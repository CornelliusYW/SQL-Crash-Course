-- #1. Modular Metric Calculation
-- WITH SUBQUERIES
SELECT 
  n.name, 
  SUM(i.points) AS total_points
FROM newsletters n
JOIN posts p ON n.id = p.newsletter_id
JOIN interactions i ON p.id = i.post_id
GROUP BY n.name
ORDER BY total_points DESC;

-- WITH CTEs
WITH newsletter_points AS (
  SELECT 
    n.id AS newsletter_id,
    SUM(i.points) AS total_points
  FROM newsletters n
  JOIN posts p ON n.id = p.newsletter_id
  JOIN interactions i ON p.id = i.post_id
  GROUP BY n.id
)
SELECT n.name, np.total_points
FROM newsletter_points np
JOIN newsletters n ON n.id = np.newsletter_id
ORDER BY np.total_points DESC;

-- #2. Reusable Intermediate Filters
-- Real-world scenario
WITH high_engagement_newsletters AS (
  SELECT 
    n.id AS newsletter_id
  FROM newsletters n
  JOIN posts p ON n.id = p.newsletter_id
  JOIN interactions i ON p.id = i.post_id
  GROUP BY n.id
  HAVING SUM(i.points) > 10
),
top_posts AS (
  SELECT 
    p.id, 
    p.name, 
    SUM(i.points) AS total_post_points
  FROM posts p
  JOIN interactions i ON p.id = i.post_id
  GROUP BY p.id, p.name
)
SELECT tp.name, tp.total_post_points
FROM top_posts tp
JOIN posts p ON tp.id = p.id
WHERE p.newsletter_id IN (
  SELECT newsletter_id FROM high_engagement_newsletters
);

-- #3. Step-by-Step Aggregation
WITH post_points AS (
  SELECT 
    p.id AS post_id, 
    p.newsletter_id, 
    SUM(i.points) AS total_points
  FROM posts p
  JOIN interactions i ON p.id = i.post_id
  GROUP BY p.id, p.newsletter_id
),
normalized_post_points AS (
  SELECT 
    pp.post_id,
    pp.newsletter_id,
    pp.total_points / COUNT(i.id) AS normalized_score
  FROM post_points pp
  JOIN interactions i ON pp.post_id = i.post_id
  GROUP BY pp.post_id, pp.newsletter_id, pp.total_points
),
newsletter_avg_score AS (
  SELECT 
    n.id AS newsletter_id,
    AVG(npp.normalized_score) AS avg_normalized_score
  FROM newsletters n
  JOIN normalized_post_points npp ON n.id = npp.newsletter_id
  GROUP BY n.id
)
SELECT n.name, nas.avg_normalized_score
FROM newsletter_avg_score nas
JOIN newsletters n ON nas.newsletter_id = n.id;