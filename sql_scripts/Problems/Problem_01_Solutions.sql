-- ****************TASKS***********************************************
-- Task 1: List all newsletter issues with their titles and publish dates.
SELECT title, published_date
FROM issues;

-- Task 2: Which 2 issues got the most views?
SELECT title, views
FROM issues
ORDER BY views DESC
LIMIT 2;

-- Task 3: What is the total number of likes across all issues?
SELECT SUM(likes) AS total_likes
FROM issues;

-- Task 4: Show each subscriber’s name and which newsletter(s) they’re subscribed to.
SELECT 
   m.name AS member_name, 
   n.name AS newsletter_name
FROM members m
JOIN subscriptions s ON m.member_id = s.member_id
JOIN newsletters n ON s.newsletter_id = n.newsletter_id;

-- Task 5: Return a list of all distinct countries of your members and all newsletter names.
SELECT country AS value FROM members
UNION
SELECT name FROM newsletters;

-- Task 6: Classify each member as 'Supporter' or 'Follower'.
SELECT name,
       CASE 
           WHEN plan = 'paid' THEN 'Supporter'
           ELSE 'Follower'
       END AS status
FROM members;

-- Task 7: Return each member’s name in UPPERCASE and the length of their email.
SELECT UPPER(name) AS uppercase_name,
       LENGTH(email) AS email_length
FROM members;

-- Task 8: How many members are subscribed to each newsletter?
SELECT n.name AS newsletter_name,
       COUNT(DISTINCT s.member_id) AS total_subscribers
FROM newsletters n
JOIN subscriptions s ON n.newsletter_id = s.newsletter_id
GROUP BY n.name;

-- Task 9: What is the average monthly revenue per newsletter from subscriptions?
SELECT n.name AS newsletter_name,
       ROUND(AVG(s.monthly_cost), 2) AS avg_monthly_revenue
FROM newsletters n
JOIN subscriptions s ON n.newsletter_id = s.newsletter_id
GROUP BY n.name;

-- Task 10: What’s the total monthly revenue per country?
SELECT n.name AS newsletter_name,
       ROUND(AVG(s.monthly_cost), 2) AS avg_monthly_revenue
FROM newsletters n
JOIN subscriptions s ON n.newsletter_id = s.newsletter_id
GROUP BY n.name;

-- Task 10: Categorize engagement levels for each issue.
SELECT title, likes,
       CASE 
           WHEN likes > 150 THEN 'Hot'
           WHEN likes BETWEEN 100 AND 150 THEN 'Warm'
           ELSE 'Cold'
       END AS engagement_level
FROM issues;