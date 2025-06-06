-- Preserve Original Table Structure
SELECT 
  n.id,
  n.name,
  (SELECT COUNT(*) 
   FROM posts p 
   WHERE p.newsletter_id = n.id) AS total_posts
FROM newsletters n;

-- Aggregate Comparison
SELECT 
  p.name,
  SUM(i.points) AS total_points
FROM posts p
JOIN interactions i ON p.id = i.post_id
GROUP BY p.id
HAVING SUM(i.points) > (
  SELECT AVG(total) 
  FROM (
    SELECT SUM(points) AS total
    FROM interactions
    GROUP BY post_id
  ) agg
);

-- Multi-Layer Calculations with GROUP BY
SELECT 
  p.name AS post_name,
  p.newsletter_id,
  SUM(i.points) AS post_points,
  newsletter_avg.avg_points
FROM posts p
JOIN interactions i ON p.id = i.post_id
JOIN (
  SELECT 
    newsletter_id,
    AVG(points) AS avg_points
  FROM posts
  JOIN interactions ON posts.id = interactions.post_id
  GROUP BY newsletter_id
) newsletter_avg ON p.newsletter_id = newsletter_avg.newsletter_id
GROUP BY p.name, p.newsletter_id, newsletter_avg.avg_points;



-- Existence Check
SELECT *
FROM newsletters n
WHERE EXISTS (
  SELECT 1
  FROM posts p
  WHERE p.newsletter_id = n.id
  AND p.name = 'DataBites'
);