-- 1️⃣ Use EXISTS Instead of JOIN + DISTINCT
SELECT *  
FROM newsletters n  
WHERE EXISTS (  
  SELECT 1  
  FROM posts p  
  WHERE p.newsletter_id = n.id  
  AND p.name = 'DataBites'  
);  


-- 2️⃣ Select Only What You Need
SELECT id, name, published_at  
FROM posts  
WHERE published_at >= '2024-01-01';  

-- 3️⃣ Index Strategically
CREATE INDEX idx_posts_date ON posts(published_at); 

-- 4️⃣ Break Queries into CTEs
WITH post_totals AS (  
  SELECT post_id, SUM(points) AS total  
  FROM interactions  
  GROUP BY post_id  
)  
SELECT p.id  
FROM posts p  
JOIN post_totals pt ON p.id = pt.post_id  
WHERE pt.total > (SELECT AVG(total) FROM post_totals);  

-- 5️⃣ Avoid SELECT * in Subqueries
SELECT n.name,  
  (SELECT COUNT(id) FROM posts p WHERE p.newsletter_id = n.id) AS post_count  
FROM newsletters n;  

-- 6️⃣ Use JOIN Instead of Subqueries for Filters
SELECT DISTINCT n.id  
FROM newsletters n  
JOIN posts p ON n.id = p.newsletter_id  
WHERE p.name LIKE '%SQL%';  

