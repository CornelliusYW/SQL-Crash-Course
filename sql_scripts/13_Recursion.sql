WITH RECURSIVE InteractionDates AS (
    SELECT MIN(DATE(datetime)) AS interaction_date
    FROM interactions

    UNION ALL

    SELECT DATE_ADD(interaction_date, INTERVAL 1 DAY)
    FROM InteractionDates
    WHERE interaction_date < (SELECT MAX(DATE(datetime)) FROM interactions)
)
SELECT interaction_date
FROM InteractionDates;

WITH RECURSIVE PointsRanking AS (
    SELECT 
        id,
        post_id,
        datetime,
        points,
        points AS running_total,
        ROW_NUMBER() OVER (PARTITION BY post_id ORDER BY datetime) AS rn
    FROM interactions

    UNION ALL

    SELECT
        i.id,
        i.post_id,
        i.datetime,
        i.points,
        pr.running_total + i.points AS running_total,
        pr.rn + 1
    FROM interactions i
    JOIN PointsRanking pr 
      ON i.post_id = pr.post_id
     AND i.datetime > pr.datetime
    WHERE NOT EXISTS (
        SELECT 1 FROM interactions i2
        WHERE i2.post_id = pr.post_id
          AND i2.datetime > pr.datetime
          AND i2.datetime < i.datetime
    )
)
SELECT post_id, datetime, points, running_total
FROM PointsRanking
ORDER BY post_id, datetime;

WITH RECURSIVE post_sequence AS (
  -- Anchor: Earliest post in the newsletter
  SELECT 
    id,
    name,
    published_at,
    1 AS post_order,
    CAST(NULL AS SIGNED) AS days_since_previous
  FROM posts
  WHERE newsletter_id = '1112A'
    AND published_at = (
      SELECT MIN(published_at) 
      FROM posts 
      WHERE newsletter_id = '1112A'
    )

  UNION ALL

  -- Recursive step: find next-later post
  SELECT 
    p.id,
    p.name,
    p.published_at,
    ps.post_order + 1,
    DATEDIFF(p.published_at, ps.published_at) AS days_since_previous
  FROM posts p
  JOIN post_sequence ps ON p.newsletter_id = '1112A'
  WHERE p.published_at > ps.published_at
    AND NOT EXISTS (
        SELECT 1 
        FROM posts p2
        WHERE p2.newsletter_id = '1112A'
          AND p2.published_at > ps.published_at
          AND p2.published_at < p.published_at
    )
)
SELECT * 
FROM post_sequence
ORDER BY post_order;
