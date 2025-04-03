-- 1. CREATE TABLES
CREATE TABLE newsletters (
    id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE posts (
    id VARCHAR(10) PRIMARY KEY,
    newsletter_id VARCHAR(10),
    name VARCHAR(255),
    published_at DATE,
    FOREIGN KEY (newsletter_id) REFERENCES newsletters(id)
);

CREATE TABLE interactions (
    id VARCHAR(10) PRIMARY KEY,
    post_id VARCHAR(10),
    datetime DATETIME,
    user VARCHAR(50),
    type_of_interaction VARCHAR(50),
    points INT,  -- numeric column added for demonstration of SUM and AVG
    FOREIGN KEY (post_id) REFERENCES posts(id)
);

-- 2. INSERT DATA
-- Newsletters
INSERT INTO newsletters (id, name) VALUES
('1112A', 'DataBites'),
('1111B', 'Non-Brand Data');

-- Posts (including a duplicate name "DataBites")
INSERT INTO posts (id, newsletter_id, name, published_at) VALUES
('1112A001', '1112A', 'SQL basics', '2024-01-10'),
('1112A002', '1112A', 'Understanding Time Series', '2024-02-15'),
('1111B001', '1111B', 'RAG model basics', '2024-03-05'),
('1111B002', '1111B', 'Crafting modular SQL queries', '2024-04-20'),
('1112A003', '1112A', 'DataBites', '2024-05-01'); -- Duplicate name from newsletters

-- Insert sample data into INTERACTIONS
INSERT INTO interactions (id, post_id, datetime, user, type_of_interaction, points) VALUES 
    ('INT9256', '1111B002', '2024-04-18 11:48:00', 'user3', 'like', 5),
    ('INT7503', '1111B002', '2024-01-04 07:30:00', 'user1', 'share', 8),
    ('INT7170', '1111B002', '2024-03-12 04:23:00', 'user2', 'like', 3),
    ('INT2624', '1112A001', '2024-02-03 00:47:00', 'user4', 'comment', 4),
    ('INT6104', '1111B001', '2024-01-06 20:50:00', 'user1', 'click', 2);

-- 3. UNION QUERY (Removes Duplicate "DataBites")
SELECT name FROM newsletters
UNION
SELECT name FROM posts;

-- 4. UNION ALL QUERY (Keeps All Rows)
SELECT name FROM newsletters
UNION ALL
SELECT name FROM posts;

-- 5. STACK 3 TABLE WITH MIXED DATA TYPE
-- Columns: id (VARCHAR), name (VARCHAR), points (INT)
SELECT id, name, NULL AS points
FROM newsletters

UNION ALL

SELECT id, name, NULL AS points
FROM posts

UNION ALL

SELECT id, type_of_interaction AS name, points
FROM interactions;