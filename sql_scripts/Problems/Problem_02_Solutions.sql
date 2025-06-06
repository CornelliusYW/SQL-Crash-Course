-- ****************TASKS***********************************************
-- 1. List newsletters with above-average monthly revenue
SELECT n.newsletter_id, n.name, SUM(s.monthly_cost) AS revenue
FROM newsletters n
JOIN subscriptions s ON n.newsletter_id = s.newsletter_id
GROUP BY n.newsletter_id, n.name
HAVING SUM(s.monthly_cost) > (
    SELECT AVG(monthly_cost_sum)
    FROM (
        SELECT SUM(monthly_cost) AS monthly_cost_sum
        FROM subscriptions
        GROUP BY newsletter_id
    ) sub
);

-- 2. Find issues with more likes than their newsletter's average
SELECT 
    issue_id, 
    title, 
    likes,
    (SELECT AVG(likes) 
     FROM issues i2 
     WHERE i2.newsletter_id = i1.newsletter_id) AS avg_newsletter_likes
FROM issues i1
WHERE likes > (
    SELECT AVG(likes) 
    FROM issues i3 
    WHERE i3.newsletter_id = i1.newsletter_id
);

-- 3. Rank members by subscription spending per country
WITH MemberSpending AS (
    SELECT 
        m.member_id, 
        m.name, 
        m.country,
        SUM(s.monthly_cost) AS total_spending
    FROM members m
    JOIN subscriptions s ON m.member_id = s.member_id
    GROUP BY m.member_id, m.name, m.country
)
SELECT 
    *,
    RANK() OVER (PARTITION BY country ORDER BY total_spending DESC) AS spending_rank
FROM MemberSpending;

-- 4. Calculate cumulative views per newsletter over time
WITH NewsletterViews AS (
    SELECT 
        newsletter_id, 
        published_date, 
        views,
        SUM(views) OVER (
            PARTITION BY newsletter_id 
            ORDER BY published_date
        ) AS cumulative_views
    FROM issues
)
SELECT * FROM NewsletterViews;

-- 5. Generate a date series for 2025 and count new subscriptions
WITH RECURSIVE DateSeries AS (
    SELECT CAST('2025-01-01' AS DATE) AS series_date
    UNION ALL
    SELECT series_date + INTERVAL 1 DAY
    FROM DateSeries
    WHERE series_date < '2025-12-31'
)
SELECT 
    ds.series_date,
    COUNT(s.joined_date) AS new_subscriptions
FROM DateSeries AS ds
LEFT JOIN subscriptions AS s
       ON ds.series_date = s.joined_date
GROUP BY ds.series_date
ORDER BY ds.series_date;


-- 6. Track subscription growth milestones per newsletter
WITH RECURSIVE GrowthMilestones AS (
    -- Anchor: first subscription date per newsletter
    SELECT 
        newsletter_id,
        MIN(joined_date) AS milestone_date,
        1 AS milestone_month
    FROM subscriptions
    GROUP BY newsletter_id

    UNION ALL

    -- Recursive: add one month until month 3
    SELECT 
        gm.newsletter_id,
        gm.milestone_date + INTERVAL 1 MONTH AS milestone_date,
        gm.milestone_month + 1
    FROM GrowthMilestones AS gm
    WHERE gm.milestone_month < 3
)
SELECT 
    gm.newsletter_id,
    n.name,
    gm.milestone_date,
    gm.milestone_month,
    COUNT(s.subscription_id) AS cumulative_subscriptions
FROM GrowthMilestones AS gm
JOIN newsletters AS n 
  ON gm.newsletter_id = n.newsletter_id
LEFT JOIN subscriptions AS s 
  ON s.newsletter_id = gm.newsletter_id 
 AND s.joined_date <= gm.milestone_date
GROUP BY 
    gm.newsletter_id,
    n.name,
    gm.milestone_date,
    gm.milestone_month
ORDER BY 
    gm.newsletter_id,
    gm.milestone_month;


-- 7. Create a view for high-engagement issues
CREATE VIEW hot_issues AS
SELECT issue_id, title, newsletter_id, likes
FROM issues
WHERE likes > 150;

-- Query the view:
SELECT n.name, COUNT(*) AS hot_issue_count
FROM hot_issues h
JOIN newsletters n ON h.newsletter_id = n.newsletter_id
GROUP BY n.name;

-- 8. Modular revenue analysis by country
WITH CountryRevenue AS (
    SELECT 
        m.country,
        SUM(s.monthly_cost) AS revenue
    FROM members m
    JOIN subscriptions s ON m.member_id = s.member_id
    GROUP BY m.country
), 
GlobalRevenue AS (
    SELECT SUM(revenue) AS total_revenue
    FROM CountryRevenue
)
SELECT 
    cr.country,
    cr.revenue,
    ROUND((cr.revenue / gr.total_revenue) * 100, 2) AS revenue_pct
FROM CountryRevenue cr, GlobalRevenue gr;

-- 9. Debug query with incorrect aggregation
-- Fixed query:
-- Corrected query:
SELECT country, plan, COUNT(*) AS member_count
FROM members
GROUP BY country, plan
HAVING COUNT(*) > 5;  -- HAVING applies AFTER aggregation

-- 10. Optimize a slow-running issue analysis
-- Optimized version:
-- Optimized (CTE + JOIN):
WITH NewsletterAvg AS (
    SELECT 
        newsletter_id, 
        AVG(views) AS avg_views
    FROM issues
    GROUP BY newsletter_id
)
SELECT 
    i.issue_id, 
    i.title, 
    i.views, 
    na.avg_views
FROM issues i
JOIN NewsletterAvg na ON i.newsletter_id = na.newsletter_id
WHERE i.views > na.avg_views;
