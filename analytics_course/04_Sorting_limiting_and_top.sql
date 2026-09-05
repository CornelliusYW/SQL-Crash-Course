-- "Sorting, limiting, and defining top" - Non-Brand Data, SQL Module 4
-- DB Fiddle setup for PostgreSQL 15. Put the schema block in the left
-- panel and the queries block in the right panel.
--
-- Live DB Fiddle URL:
-- https://www.db-fiddle.com/f/jkaMLBobi1WuJWaewxpb4k/0
--
-- Expected results, in query order:
--   1. Five rows ordered by customer_id: C001 120.00, C002 910.00,
--      C003 85.50, C004 1300.00, C005 410.00.
--   2. Top five by spend: C008 2500.00, C004 1300.00, then C002,
--      C006, and C011 at 910.00.
--   3. Bottom five by spend: C010 -35.00, C009 0.00, C007 60.00,
--      C003 85.50, and C001 120.00.
--   4. Stable top three rows: C008 2500.00, C004 1300.00,
--      C002 910.00.
--   5. Top three spend ranks: C008 rank 1, C004 rank 2, and C002,
--      C006, C011 rank 3. Five rows in total.
--
-- The rows are small teaching data based on the Olist e-commerce schema.
-- The identifiers, totals, and notes are made for this lesson. They are not
-- direct extracts from Olist.

-- ================= SCHEMA (left panel) =================

DROP TABLE IF EXISTS customer_spend;

CREATE TABLE customer_spend (
    customer_id TEXT PRIMARY KEY,
    total_payment_value NUMERIC(10, 2),
    spend_note TEXT NOT NULL
);

INSERT INTO customer_spend (customer_id, total_payment_value, spend_note) VALUES
    ('C001',  120.00, 'standard account'),
    ('C002',  910.00, 'standard account'),
    ('C003',   85.50, 'standard account'),
    ('C004', 1300.00, 'standard account'),
    ('C005',  410.00, 'standard account'),
    ('C006',  910.00, 'standard account'),
    ('C007',   60.00, 'standard account'),
    ('C008', 2500.00, 'standard account'),
    ('C009',    0.00, 'no captured payment'),
    ('C010',  -35.00, 'refund adjustment'),
    ('C011',  910.00, 'standard account'),
    ('C012',  740.00, 'standard account'),
    ('C013',    NULL, 'payment total missing');

-- ================= QUERIES (right panel) =================

-- 1. Scenario 1, the first attempt: LIMIT after an ID sort.
-- This is stable, but customer_id doesn't define the largest spend.
-- Returns the five rows listed first in the expected results.
SELECT
    customer_id,
    total_payment_value,
    spend_note
FROM customer_spend
ORDER BY customer_id
LIMIT 5;

-- 2. Scenario 1, the fix: five largest known spend values.
-- NULLS LAST keeps the missing total out of the top-spend result.
-- customer_id makes the order stable when spend values are equal.
SELECT
    customer_id,
    total_payment_value,
    spend_note
FROM customer_spend
ORDER BY total_payment_value DESC NULLS LAST, customer_id ASC
LIMIT 5;

-- 3. Scenario 1, the other end: five smallest known spend values.
-- Looking at the bottom shows the zero and negative values.
SELECT
    customer_id,
    total_payment_value,
    spend_note
FROM customer_spend
ORDER BY total_payment_value ASC NULLS LAST, customer_id ASC
LIMIT 5;

-- 4. Scenario 2, stable but incomplete when the cutoff is a tie.
-- C002 wins the customer_id tie-break, while C006 and C011 are left out.
SELECT
    customer_id,
    total_payment_value
FROM customer_spend
ORDER BY total_payment_value DESC NULLS LAST, customer_id ASC
LIMIT 3;

-- 5. Scenario 2, the fix: include every customer in the top three
-- distinct spend ranks. Window functions are taught in Module 11.
WITH ranked_customers AS (
    SELECT
        customer_id,
        total_payment_value,
        DENSE_RANK() OVER (
            ORDER BY total_payment_value DESC NULLS LAST
        ) AS spend_rank
    FROM customer_spend
    WHERE total_payment_value IS NOT NULL
)
SELECT
    customer_id,
    total_payment_value,
    spend_rank
FROM ranked_customers
WHERE spend_rank <= 3
ORDER BY spend_rank, customer_id;
