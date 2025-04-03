-- Creating table NEWSLETTERS
CREATE TABLE newsletters (
    id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100)
);

-- Creating table POSTS
CREATE TABLE posts (
    id VARCHAR(10) PRIMARY KEY,
    newsletter_id VARCHAR(10),
    name VARCHAR(255),
    published_at DATE,
    FOREIGN KEY (newsletter_id) REFERENCES newsletters(id)
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

-- Creating table INTERACTIONS
CREATE TABLE interactions (
    id VARCHAR(10) PRIMARY KEY,
    post_id VARCHAR(10),
    datetime DATETIME,
    user VARCHAR(50),
    type_of_interaction VARCHAR(50),
    FOREIGN KEY (post_id) REFERENCES posts(id)
);

INSERT INTO interactions (id, post_id, datetime, user, type_of_interaction) VALUES
('INT9256', '1111B002', '2024-04-18 11:48:00', 'user3', 'like'),
('INT7503', '1111B002', '2024-01-04 07:30:00', 'user1', 'share'),
('INT7170', '1111B002', '2024-03-12 04:23:00', 'user2', 'like'),
('INT2624', '1112A001', '2024-02-03 00:47:00', 'user4', 'comment'),
('INT6104', '1111B001', '2024-01-06 20:50:00', 'user1', 'click'),
('INT5555', '1111B002', '2024-04-07 06:42:00', 'user3', 'comment'),
('INT7674', '1112A002', '2024-01-13 06:59:00', 'user5', 'share'),
('INT4502', '1111B002', '2024-04-28 21:33:00', 'user2', 'like'),
('INT9635', '1111B001', '2024-02-27 14:00:00', 'user1', 'click');


-- LEFT JOIN
-- Get all posts and the name of their corresponding newsletter (if any):
SELECT 
    posts.name AS post_title,
    newsletters.name AS newsletter_name
FROM posts
LEFT JOIN newsletters
    ON posts.newsletter_id = newsletters.id;
    

-- RIGHT JOIN
-- Get all newsletters and any associated posts (if available):
SELECT 
    newsletters.name AS newsletter_name,
    posts.name AS post_title
FROM posts
RIGHT JOIN newsletters
    ON posts.newsletter_id = newsletters.id;
    
-- LEFT JOIN (no match)

-- Get all posts that are not linked to any newsletter:
SELECT 
    posts.name AS post_title
FROM posts
LEFT JOIN newsletters
    ON posts.newsletter_id = newsletters.id
WHERE newsletters.id IS NULL;

-- RIGHT JOIN (no match)
-- Get all newsletters that don’t have any posts:
SELECT 
    newsletters.name AS newsletter_name
FROM posts
RIGHT JOIN newsletters
    ON posts.newsletter_id = newsletters.id
WHERE posts.id IS NULL;

-- FULL OUTER JOIN (simulated using UNION of LEFT and RIGHT JOINs)
-- Show all posts and newsletters, including any that don’t match:
SELECT 
    posts.name AS post_title,
    newsletters.name AS newsletter_name
FROM posts
LEFT JOIN newsletters
    ON posts.newsletter_id = newsletters.id

UNION

SELECT 
    posts.name AS post_title,
    newsletters.name AS newsletter_name
FROM posts
RIGHT JOIN newsletters
    ON posts.newsletter_id = newsletters.id;
    
-- FULL OUTER JOIN (no match only) simulated in MySQL
-- Get only the non-matching records between posts and newsletters:
SELECT 
    posts.name AS post_title,
    newsletters.name AS newsletter_name
FROM posts
LEFT JOIN newsletters
    ON posts.newsletter_id = newsletters.id
WHERE newsletters.id IS NULL

UNION

SELECT 
    posts.name AS post_title,
    newsletters.name AS newsletter_name
FROM posts
RIGHT JOIN newsletters
    ON posts.newsletter_id = newsletters.id
WHERE posts.id IS NULL;


-- INNER JOIN
-- Get only posts that belong to a valid newsletter:
SELECT 
    posts.name AS post_title,
    newsletters.name AS newsletter_name
FROM posts
INNER JOIN newsletters
    ON posts.newsletter_id = newsletters.id;
    
-- Joining newsletters, posts, and interactions
-- Show the newsletter name, post title, and interaction type:
SELECT 
    newsletters.name AS newsletter_name,
    posts.name AS post_title,
    interactions.type_of_interaction
FROM newsletters
JOIN posts
    ON newsletters.id = posts.newsletter_id
JOIN interactions
    ON posts.id = interactions.post_id;
