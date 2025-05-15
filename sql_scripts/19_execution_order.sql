-- OUR EXAMPLE TO UNDERSTAND THE SQL EXECUTION ORDER
SELECT
  n.name AS newsletter_name,
  p.name AS post_name,
  SUM(i.points) AS total_points
FROM posts p
JOIN newsletters n 
  ON p.newsletter_id = n.id
JOIN interactions i 
  ON p.id = i.post_id
WHERE i.points IS NOT NULL
GROUP BY n.name, p.name
HAVING SUM(i.points) >= 2
ORDER BY total_points DESC
LIMIT 10;