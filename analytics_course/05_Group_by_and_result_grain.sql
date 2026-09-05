-- "GROUP BY and what one aggregate row counts" - Non-Brand Data, SQL Module 5
-- DB Fiddle setup for PostgreSQL 15. Put the schema block in the left
-- panel and the queries block in the right panel.
--
-- Final revisioned DB Fiddle URL: https://www.db-fiddle.com/f/5WX8ofYfgRwLzv3VJddpT7/0
--
-- Expected results, in query order:
--   1. Row count by status: canceled 1, delivered 9, shipped 3.
--   2. Distinct orders and customers by status: canceled 1 order and
--      1 customer; delivered 5 orders and 4 customers; shipped 2 orders
--      and 1 customer.
--   3. Month-and-status grain: 2024-01-01 delivered 3 and shipped 1;
--      2024-02-01 canceled 1, delivered 2, and shipped 1.
--   4. Monthly delivered metrics: 2024-01-01 has 3 orders and 2 customers;
--      2024-02-01 has 2 orders and 2 customers.
--
-- The rows are small teaching data based on the Olist e-commerce schema.
-- The identifiers, timestamps, statuses, and prices are made for this lesson.
-- They are not direct extracts from Olist.

-- ================= SCHEMA (left panel) =================

DROP TABLE IF EXISTS order_lines;

CREATE TABLE order_lines (
    order_id TEXT NOT NULL,
    customer_id TEXT NOT NULL,
    customer_unique_id TEXT NOT NULL,
    order_status TEXT NOT NULL,
    order_purchase_timestamp TIMESTAMPTZ NOT NULL,
    order_item_id INTEGER NOT NULL,
    product_id TEXT NOT NULL,
    item_price NUMERIC(10, 2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id)
);

INSERT INTO order_lines (
    order_id,
    customer_id,
    customer_unique_id,
    order_status,
    order_purchase_timestamp,
    order_item_id,
    product_id,
    item_price
) VALUES
    ('O1001', 'C101', 'U001', 'delivered', '2024-01-05 10:00:00+00', 1, 'P01', 40.00),
    ('O1001', 'C101', 'U001', 'delivered', '2024-01-05 10:00:00+00', 2, 'P02', 10.00),
    ('O1002', 'C102', 'U002', 'delivered', '2024-01-09 14:30:00+00', 1, 'P03', 80.00),
    ('O1003', 'C103', 'U001', 'delivered', '2024-01-20 08:15:00+00', 1, 'P04', 20.00),
    ('O1003', 'C103', 'U001', 'delivered', '2024-01-20 08:15:00+00', 2, 'P05', 25.00),
    ('O1003', 'C103', 'U001', 'delivered', '2024-01-20 08:15:00+00', 3, 'P06', 15.00),
    ('O1004', 'C104', 'U003', 'shipped',   '2024-01-27 16:45:00+00', 1, 'P07', 60.00),
    ('O1004', 'C104', 'U003', 'shipped',   '2024-01-27 16:45:00+00', 2, 'P08', 12.00),
    ('O1005', 'C105', 'U004', 'canceled',  '2024-02-02 11:00:00+00', 1, 'P09', 99.00),
    ('O1006', 'C106', 'U004', 'delivered', '2024-02-06 09:20:00+00', 1, 'P10', 45.00),
    ('O1007', 'C107', 'U005', 'delivered', '2024-02-11 13:10:00+00', 1, 'P11', 30.00),
    ('O1007', 'C107', 'U005', 'delivered', '2024-02-11 13:10:00+00', 2, 'P12', 35.00),
    ('O1008', 'C108', 'U003', 'shipped',   '2024-02-18 17:40:00+00', 1, 'P13', 55.00);

-- ================= QUERIES (right panel) =================

-- 1. Scenario 1, the first attempt: COUNT(*) counts item rows.
SELECT
    order_status,
    COUNT(*) AS order_count
FROM order_lines
GROUP BY order_status
ORDER BY order_status;

-- 2. Scenario 1, the fix: choose the key that matches each metric.
SELECT
    order_status,
    COUNT(DISTINCT order_id) AS order_count,
    COUNT(DISTINCT customer_unique_id) AS customer_count
FROM order_lines
GROUP BY order_status
ORDER BY order_status;

-- 3. Scenario 2, the first attempt: one row per month and status.
SELECT
    DATE_TRUNC(
        'month',
        order_purchase_timestamp AT TIME ZONE 'UTC'
    )::date AS order_month,
    order_status,
    COUNT(DISTINCT order_id) AS order_count
FROM order_lines
GROUP BY order_month, order_status
ORDER BY order_month, order_status;

-- 4. Scenario 2, the fix: one row per month, with status inside the counts.
SELECT
    DATE_TRUNC(
        'month',
        order_purchase_timestamp AT TIME ZONE 'UTC'
    )::date AS order_month,
    COUNT(DISTINCT order_id)
        FILTER (WHERE order_status = 'delivered') AS delivered_order_count,
    COUNT(DISTINCT customer_unique_id)
        FILTER (WHERE order_status = 'delivered') AS delivered_customer_count
FROM order_lines
GROUP BY order_month
ORDER BY order_month;
