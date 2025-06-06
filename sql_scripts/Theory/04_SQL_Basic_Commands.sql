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

-- Simple SELECT example
SELECT name FROM newsletters;

-- Single Filter with Comparison Operator
SELECT name, published_at
FROM posts
WHERE published_at < '2024-03-01';

-- Multiple Filter Condition
SELECT name
FROM posts
WHERE newsletter_id = '1112A' AND published_at >= '2024-01-01';

-- Text Filter Condition
SELECT name
FROM posts
WHERE name LIKE '%SQL%';

-- Date Filter Condition
SELECT id, name
FROM posts
WHERE published_at >= '2024-02-01';

-- Grouped Condition
SELECT name
FROM posts
WHERE (newsletter_id = '1112A' OR newsletter_id = '1111B')
AND published_at <= '2024-03-31';
