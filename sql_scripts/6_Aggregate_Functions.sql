-- Create the NEWSLETTERS table
CREATE TABLE newsletters (
    id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Create the POSTS table
CREATE TABLE posts (
    id VARCHAR(10) PRIMARY KEY,
    newsletter_id VARCHAR(10),
    name VARCHAR(255) NOT NULL,
    published_at DATE,
    FOREIGN KEY (newsletter_id) REFERENCES newsletters(id)
);

-- Create the INTERACTIONS table with an extra numeric column 'points'
CREATE TABLE interactions (
    id VARCHAR(10) PRIMARY KEY,
    post_id VARCHAR(10),
    datetime DATETIME,
    user VARCHAR(50),
    type_of_interaction VARCHAR(50),
    points INT,  -- numeric column added for demonstration of SUM and AVG
    FOREIGN KEY (post_id) REFERENCES posts(id)
);


-- Insert sample data into NEWSLETTERS
INSERT INTO newsletters (id, name) VALUES 
    ('1112A', 'DataBites'),
    ('1111B', 'Non-Brand Data');


-- Insert sample data into POSTS
INSERT INTO posts (id, newsletter_id, name, published_at) VALUES 
    ('1112A001', '1112A', 'SQL basics', '2024-01-10'),
    ('1112A002', '1112A', 'Understanding Time Series', '2024-02-15'),
    ('1111B001', '1111B', 'RAG model basics', '2024-03-05'),
    ('1111B002', '1111B', 'Crafting modular SQL queries', '2024-04-20');


-- Insert sample data into INTERACTIONS
INSERT INTO interactions (id, post_id, datetime, user, type_of_interaction, points) VALUES 
    ('INT9256', '1111B002', '2024-04-18 11:48:00', 'user3', 'like', 5),
    ('INT7503', '1111B002', '2024-01-04 07:30:00', 'user1', 'share', 8),
    ('INT7170', '1111B002', '2024-03-12 04:23:00', 'user2', 'like', 3),
    ('INT2624', '1112A001', '2024-02-03 00:47:00', 'user4', 'comment', 4),
    ('INT6104', '1111B001', '2024-01-06 20:50:00', 'user1', 'click', 2);


-- 1. SUM: Add up numeric values from the 'points' column in INTERACTIONS
SELECT SUM(points) AS total_points
FROM interactions;
-- This query sums up the 'points' values for all interactions.

-- 2. AVG: Calculate the average of the numeric values in the 'points' column
SELECT AVG(points) AS average_points
FROM interactions;
-- This query returns the average points per interaction.

-- 3. COUNT: Count rows (all interactions) or count non-NULL values in a column
-- a) Count all rows in the INTERACTIONS table:
SELECT COUNT(*) AS total_interactions
FROM interactions;
-- b) Count only the non-NULL entries in the 'points' column:
SELECT COUNT(points) AS count_points
FROM interactions;

-- 4. MIN / MAX: Find the smallest (MIN) and largest (MAX) published dates in POSTS
SELECT MIN(published_at) AS earliest_post, 
       MAX(published_at) AS latest_post
FROM posts;
-- This query retrieves the earliest and latest publication dates of posts.

-- 5. GROUP BY: Segment data into groups.
-- For example, count the number of interactions for each type_of_interaction:
SELECT type_of_interaction, COUNT(*) AS interactions_count
FROM interactions
GROUP BY type_of_interaction;
-- This groups the interactions table by type (like, share, etc.) and counts each group.

-- 6. HAVING: Filter groups after aggregation.
-- For example, only show interaction types that occur more than once:
SELECT type_of_interaction, COUNT(*) AS interactions_count
FROM interactions
GROUP BY type_of_interaction
HAVING COUNT(*) > 1;
-- This filters the groups, returning only those with more than one interaction.    