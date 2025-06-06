WITH 
-- MODULE 1

post_points AS (
SELECT 
  p.id AS post_id,
  p.name AS post_name,
  p.newsletter_id,
  SUM(i.points) AS total_points
FROM posts p
JOIN interactions i ON p.id = i.post_id
GROUP BY p.id, p.name, p.newsletter_id
),

-- MODULE 2
ranked_posts AS 
(
SELECT 
  pp.*,
  RANK() OVER (PARTITION BY newsletter_id ORDER BY total_points DESC) AS rank_within_newsletter
FROM post_points pp
),

-- MODULE 3
newsletter_avg_points AS (
  SELECT 
    newsletter_id,
    AVG(total_points) AS avg_post_score
  FROM post_points
  GROUP BY newsletter_id
)

-- FINAL SELECTION
SELECT 
  n.name AS newsletter_name,
  rp.post_name,
  rp.total_points,
  rp.rank_within_newsletter,
  nap.avg_post_score
FROM ranked_posts rp
JOIN newsletters n ON n.id = rp.newsletter_id
JOIN newsletter_avg_points nap ON nap.newsletter_id = rp.newsletter_id
WHERE rp.rank_within_newsletter <= 3
ORDER BY n.name, rp.rank_within_newsletter;