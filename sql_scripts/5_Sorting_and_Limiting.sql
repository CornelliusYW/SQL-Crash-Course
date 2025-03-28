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

-- Get all post names from the posts table:
SELECT name  
FROM posts;

-- ORDER BY
-- Get all post names sorted by publish date (oldest to newest):
SELECT name, published_at  
FROM posts  
ORDER BY published_at ASC;

-- Get post names sorted by newsletter and then by publish date (newest first):
SELECT name, newsletter_id, published_at  
FROM posts  
ORDER BY newsletter_id ASC, published_at DESC;

-- LIMIT
-- Get the 2 most recent posts:
SELECT name, published_at  
FROM posts  
ORDER BY published_at DESC  
LIMIT 2;

-- Get just 1 post from the 'Non-Brand Data' newsletter:
SELECT name  
FROM posts  
WHERE newsletter_id = '1111B'  
LIMIT 1;