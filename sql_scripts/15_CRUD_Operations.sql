-- ======================================
-- 1. INSERT EXAMPLES
-- ======================================

-- Single Row Insert
INSERT INTO newsletters (id, name) 
VALUES ('1113C', 'Analytics Weekly');

INSERT INTO posts (id, newsletter_id, name, published_at)
VALUES ('1113C001', '1113C', 'Introduction to Python', '2024-06-01');

-- Bulk Insert
INSERT INTO interactions (id, post_id, datetime, user, type_of_interaction, points) 
VALUES 
  ('INT9991', '1112A003', '2024-05-02 09:00:00', 'user5', 'like', 5),
  ('INT9992', '1112A003', '2024-05-02 10:30:00', 'user6', 'share', 8);

-- Insert from Another Table
CREATE TABLE interactions_archive AS
SELECT * FROM interactions
WHERE datetime < '2024-01-01';


-- ======================================
-- 2. UPDATE EXAMPLES
-- ======================================

-- Update with Subquery
UPDATE interactions
SET points = points + 2
WHERE post_id IN (
  SELECT id FROM posts 
  WHERE newsletter_id = '1112A'  -- "DataBites" newsletter
);

-- ======================================
-- 3. DELETE EXAMPLES (SAFE VERSION)
-- ======================================

-- Example: Delete post '1112A003' and its interactions
-- Step 1: Delete child interactions first
DELETE FROM interactions 
WHERE post_id = '1112A003';

-- Step 2: Delete the post
DELETE FROM posts 
WHERE id = '1112A003';

-- ======================================
-- 🔑 BEST PRACTICES EXAMPLES
-- ======================================

-- 1. Always Use WHERE in UPDATE/DELETE
-- ✅ Safe deletion of old interactions
DELETE FROM interactions 
WHERE datetime < '2024-01-01';

-- 2. Test with SELECT First
-- Preview posts to delete (with no interactions)
SELECT * FROM posts 
WHERE id NOT IN (SELECT post_id FROM interactions);


-- 3. Soft Delete Example (avoids foreign key issues)
ALTER TABLE posts ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
UPDATE posts SET is_active = FALSE WHERE id = '1112A003';  -- Mark as inactive