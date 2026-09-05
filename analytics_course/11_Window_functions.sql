-- "Window functions without double-counting rows" - Non-Brand Data, SQL Module 11
-- PostgreSQL 15
--
-- Final revisioned DB Fiddle URL: https://www.db-fiddle.com/f/ojrezbWjMcTLJ15FRYyY91/0
--
-- Expected results, in query order:
--   1. Daily GROUP BY: four rows. Revenue is 200.00 on 2024-04-01,
--      180.00 on 2024-04-02, 160.00 on 2024-04-03, and 90.00 on
--      2024-04-04. The matching order counts are 2, 2, 2, and 1.
--   2. Windowed order result: seven rows at order grain. Daily revenue
--      repeats as 200.00, 200.00, 180.00, 180.00, 160.00, 160.00,
--      and 90.00. Running revenue is 80.00, 200.00, 320.00, 380.00,
--      500.00, 540.00, and 630.00.
--   3. Tied value ranks: the three 120.00 orders have rank 1. The
--      remaining ranks are 4, 5, 6, and 7 for values 90.00, 80.00,
--      60.00, and 40.00.
--   4. Stable tie order: the same value ranks remain, while display
--      position runs from 1 through 7. The three tied rows appear as
--      order_1102, order_1103, and order_1105.
--
-- The rows are a small invented teaching dataset based on the Olist
-- e-commerce schema. The identifiers, customers, timestamps, and values
-- were made for this lesson. They are not direct Olist extracts.

-- ================= SCHEMA AND SEED DATA (left panel) =================

DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    order_id TEXT PRIMARY KEY,
    customer_unique_id TEXT NOT NULL,
    order_status TEXT NOT NULL,
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_total NUMERIC(10, 2) NOT NULL
);

INSERT INTO orders (
    order_id,
    customer_unique_id,
    order_status,
    order_purchase_timestamp,
    order_total
) VALUES
    ('order_1101', 'customer_001', 'delivered', '2024-04-01 09:00:00',  80.00),
    ('order_1102', 'customer_002', 'delivered', '2024-04-01 13:00:00', 120.00),
    ('order_1103', 'customer_003', 'delivered', '2024-04-02 10:00:00', 120.00),
    ('order_1104', 'customer_001', 'delivered', '2024-04-02 15:00:00',  60.00),
    ('order_1105', 'customer_004', 'delivered', '2024-04-03 09:30:00', 120.00),
    ('order_1106', 'customer_005', 'delivered', '2024-04-03 11:00:00',  40.00),
    ('order_1107', 'customer_002', 'delivered', '2024-04-04 14:00:00',  90.00);

-- ================= TEACHING QUERIES (right panel) =================

-- 1. Scenario 1, the first attempt.
-- The daily totals are right, but grouping removes the order rows.
SELECT
    order_purchase_timestamp::date AS order_date,
    COUNT(*) AS order_rows,
    SUM(order_total) AS daily_revenue
FROM orders
GROUP BY order_purchase_timestamp::date
ORDER BY order_date;

-- 2. Scenario 1, the fix.
-- Window functions add daily and running values without changing the grain.
SELECT
    order_id,
    order_purchase_timestamp::date AS order_date,
    order_total,
    SUM(order_total) OVER (
        PARTITION BY order_purchase_timestamp::date
    ) AS daily_revenue,
    SUM(order_total) OVER (
        ORDER BY order_purchase_timestamp, order_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_revenue
FROM orders
ORDER BY order_purchase_timestamp, order_id;

-- 3. Scenario 2, the first attempt.
-- RANK keeps the business tie, but the rank alone is not a unique sequence.
SELECT
    order_id,
    order_purchase_timestamp,
    order_total,
    RANK() OVER (
        ORDER BY order_total DESC
    ) AS value_rank
FROM orders
ORDER BY value_rank, order_id;

-- 4. Scenario 2, the fix.
-- Keep the business rank and add a separate stable display position.
SELECT
    order_id,
    order_purchase_timestamp,
    order_total,
    RANK() OVER (
        ORDER BY order_total DESC
    ) AS value_rank,
    ROW_NUMBER() OVER (
        ORDER BY order_total DESC,
                 order_purchase_timestamp,
                 order_id
    ) AS display_position
FROM orders
ORDER BY display_position;
