-- #1. Simplifying Repetitive Logic
-- Without a view
SELECT *
FROM posts
WHERE newsletter_id = '1112A';

-- With a view
CREATE VIEW databites_posts AS
SELECT *
FROM posts
WHERE newsletter_id = '1112A';

-- Reuse easily:
SELECT * FROM databites_posts
WHERE published_at > '2024-02-01';

-- #2. Reusable Metrics
CREATE VIEW post_performance AS
SELECT 
  p.id AS post_id,
  p.name,
  n.name AS newsletter_name,
  SUM(i.points) AS total_points,
  COUNT(i.id) AS interaction_count
FROM posts p
JOIN newsletters n ON p.newsletter_id = n.id
LEFT JOIN interactions i ON p.id = i.post_id
GROUP BY p.id, p.name, n.name;

-- Use it like this:
SELECT *
FROM post_performance
WHERE total_points > 5;

-- #3. Hiding Sensitive Data
CREATE VIEW public_post_insights AS
SELECT 
  p.id AS post_id,
  p.name AS post_title,
  COUNT(i.id) AS total_interactions,
  SUM(i.points) AS engagement_score
FROM posts p
LEFT JOIN interactions i ON p.id = i.post_id
GROUP BY p.id, p.name;

-- Simple and safe:
SELECT * FROM public_post_insights;