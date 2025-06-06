-- EXAMPLE 1
-- We want to count how many interactions each post has received and classify them into categories: 🟥 No Interactions, 🟨 Low, 🟧 Medium, 🟩 High.
SELECT 
    P.name AS post_name,
    COUNT(I.id) AS num_interactions,
    CASE 
        WHEN COUNT(I.id) = 0 THEN '🟥 No Interactions'
        WHEN COUNT(I.id) BETWEEN 1 AND 3 THEN '🟨 Low'
        WHEN COUNT(I.id) BETWEEN 4 AND 6 THEN '🟧 Medium'
        ELSE '🟩 High'
    END AS interaction_level
FROM posts P
LEFT JOIN interactions I
    ON P.id = I.post_id
GROUP BY P.name;

-- EXAMPLE 2
-- We’ll classify each interaction as Like, Comment, or Other using a CASE expression.
SELECT 
    I.id,
    I.type_of_interaction,
    CASE 
        WHEN I.type_of_interaction = 'like' THEN 'Like'
        WHEN I.type_of_interaction = 'comment' THEN 'Comment'
        ELSE 'Other'
    END AS interaction_category
FROM interactions I;

-- EXAMPLE 3
-- We want to list all posts, and prioritize those with no interactions at the top of the results.
SELECT 
    P.name AS post_name,
    COUNT(I.id) AS num_interactions
FROM posts P
LEFT JOIN interactions I
    ON P.id = I.post_id
GROUP BY P.name
ORDER BY 
    CASE 
        WHEN COUNT(I.id) = 0 THEN 0
        ELSE 1
    END,
    P.name;
