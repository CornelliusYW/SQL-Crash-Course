-- Example combining String, Date, and Numeric functions
SELECT 
    -- String Functions
    CONCAT(n.name, ' - ', p.name) AS combined_title,  -- Merge newsletter & post names
    SUBSTRING(p.name, 1, 10) AS title_snippet,        -- Extract first 10 characters
    UPPER(n.name) AS uppercase_newsletter,             -- Convert newsletter name to uppercase
    TRIM(i.type_of_interaction) AS clean_interaction,  -- Remove whitespace from interaction types
    REPLACE(p.name, 'DataBites', 'DB') AS renamed_post,-- Replace substring in post names

    -- Date Functions
    CURRENT_DATE AS today,                             -- Get current date
    EXTRACT(YEAR FROM p.published_at) AS publish_year, -- Extract year from publication date
    DATE_ADD(CURRENT_DATE, INTERVAL -7 DAY) AS week_ago_start, -- Calculate date 7 days ago
    DATEDIFF(CURRENT_DATE, p.published_at) AS days_since_publish, -- Days between today and publish date

    -- Numeric Functions
    SUM(i.points) AS total_points,                     -- Sum interaction points per post
    ROUND(AVG(i.points), 1) AS avg_points,             -- Average points (rounded to 1 decimal)
    CEIL(SUM(i.points)) AS rounded_up_points,          -- Round total points up to nearest integer
    FLOOR(SUM(i.points)) AS rounded_down_points,       -- Round total points down to nearest integer
    ABS(i.points - 5) AS deviation_from_five,          -- Absolute difference from 5 points
    MOD(i.points, 2) AS even_odd_check                 -- Check if points are even (0) or odd (1)

FROM posts p
JOIN newsletters n ON p.newsletter_id = n.id
LEFT JOIN interactions i ON p.id = i.post_id
GROUP BY 
    p.id, n.name, p.name, i.type_of_interaction, p.published_at, i.points;