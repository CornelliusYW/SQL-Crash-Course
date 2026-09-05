-- "WHERE and HAVING, and which filter runs when" - Non-Brand Data, SQL Module 6
-- DB Fiddle setup for PostgreSQL 15. Put the schema block in the left
-- panel and the queries block in the right panel.
--
-- Final revisioned DB Fiddle URL: https://www.db-fiddle.com/f/xa3aNgZANtF6bSN2x6ZXFj/0
--
-- Expected results, in query order:
--   1. Three customers with at least two delivered orders:
--      customer_005 3, customer_001 2, customer_003 2.
--   2. Five customers with at least two total orders and one delivery:
--      customer_001 3/2, customer_005 3/3, customer_002 2/1,
--      customer_003 2/2, customer_006 2/1. Values are total/delivered.
--   3. The same five-customer result as query 2. It is a valid query,
--      but it doesn't answer a request for two delivered orders.
--   4. The same three-customer result as query 1. It answers the
--      two-delivered-order request because WHERE defines the population.
--
-- The rows are small teaching data based on the Olist e-commerce schema.
-- The identifiers, dates, statuses, and values are made for this lesson.
-- They are not direct extracts from Olist.

-- ================= SCHEMA (left panel) =================

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
    ('order_1001', 'customer_001', 'delivered',   '2024-01-05 10:15:00', 125.00),
    ('order_1002', 'customer_001', 'canceled',    '2024-01-12 09:20:00',  90.00),
    ('order_1003', 'customer_001', 'delivered',   '2024-02-02 14:05:00', 210.00),
    ('order_1004', 'customer_002', 'delivered',   '2024-01-08 11:40:00',  75.00),
    ('order_1005', 'customer_002', 'shipped',     '2024-02-03 16:25:00',  80.00),
    ('order_1006', 'customer_003', 'delivered',   '2024-01-10 08:55:00',  55.00),
    ('order_1007', 'customer_003', 'delivered',   '2024-01-24 18:10:00', 120.00),
    ('order_1008', 'customer_004', 'canceled',    '2024-01-18 12:30:00',  40.00),
    ('order_1009', 'customer_004', 'shipped',     '2024-02-06 15:45:00',  60.00),
    ('order_1010', 'customer_005', 'delivered',   '2024-01-03 07:35:00', 300.00),
    ('order_1011', 'customer_005', 'delivered',   '2024-02-01 13:00:00', 140.00),
    ('order_1012', 'customer_005', 'delivered',   '2024-02-07 17:50:00',  50.00),
    ('order_1013', 'customer_006', 'delivered',   '2024-01-29 10:05:00',  95.00),
    ('order_1014', 'customer_006', 'unavailable', '2024-02-08 09:15:00',  95.00),
    ('order_1015', 'customer_007', 'canceled',    '2024-02-10 19:30:00',  65.00);

-- ================= QUERIES (right panel) =================

-- 1. Scenario 1, the first attempt.
-- This counts delivered orders, not total orders with one delivery.
SELECT
    customer_unique_id,
    COUNT(*) AS delivered_orders
FROM orders
WHERE order_status = 'delivered'
GROUP BY customer_unique_id
HAVING COUNT(*) >= 2
ORDER BY delivered_orders DESC, customer_unique_id;

-- 2. Scenario 1, the fix.
-- Keep every status, then test the total and delivered counts per customer.
SELECT
    customer_unique_id,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders
FROM orders
GROUP BY customer_unique_id
HAVING COUNT(*) >= 2
   AND COUNT(*) FILTER (
           WHERE order_status = 'delivered'
       ) >= 1
ORDER BY total_orders DESC, customer_unique_id;

-- 3. Scenario 2, the first attempt.
-- This valid group test still allows customers with one delivered order.
SELECT
    customer_unique_id,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders
FROM orders
GROUP BY customer_unique_id
HAVING COUNT(*) >= 2
   AND COUNT(*) FILTER (
           WHERE order_status = 'delivered'
       ) >= 1
ORDER BY total_orders DESC, customer_unique_id;

-- 4. Scenario 2, the fix.
-- WHERE creates a delivered-order population before HAVING tests group size.
SELECT
    customer_unique_id,
    COUNT(*) AS delivered_orders
FROM orders
WHERE order_status = 'delivered'
GROUP BY customer_unique_id
HAVING COUNT(*) >= 2
ORDER BY delivered_orders DESC, customer_unique_id;
