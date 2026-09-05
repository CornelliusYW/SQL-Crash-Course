-- "Choosing inner vs left, and which rows survive" - Non-Brand Data, SQL Module 8
-- PostgreSQL 15
-- Final revisioned DB Fiddle URL: https://www.db-fiddle.com/f/bexQHtNNYDvaLsFD1kpnG3/0
--
-- Expected results, in query order:
--   1. INNER JOIN coverage calculated after unmatched customers disappear:
--      customers_seen = 5, customers_with_orders = 5,
--      customers_without_orders = 0, match_coverage_pct = 100.00.
--   2. LEFT JOIN coverage calculated from the full customer population:
--      customers_seen = 8, customers_with_orders = 5,
--      customers_without_orders = 3, match_coverage_pct = 62.50.
--   3. LEFT JOIN followed by a delivered-status condition in WHERE:
--      customer_005 | SP | 2
--      customer_001 | SP | 1
--      customer_002 | RJ | 1
--   4. LEFT JOIN with the delivered-status condition in ON:
--      customer_005 | SP | 2
--      customer_001 | SP | 1
--      customer_002 | RJ | 1
--      customer_003 | MG | 0
--      customer_004 | BA | 0
--      customer_006 | PR | 0
--      customer_007 | PE | 0
--      customer_008 | SC | 0
--   5. Teaching-data exercise, canceled orders with the condition in ON:
--      customer_001 | SP | 1
--      customer_006 | PR | 1
--      customer_002 | RJ | 0
--      customer_003 | MG | 0
--      customer_004 | BA | 0
--      customer_005 | SP | 0
--      customer_007 | PE | 0
--      customer_008 | SC | 0
--
-- These are small deterministic teaching data shaped like the Olist
-- customers and orders tables. The IDs, states, dates, statuses, and
-- values are invented for this lesson. They are not direct Olist records.

-- ================= SCHEMA AND SEED DATA (left panel) =================

DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_unique_id TEXT PRIMARY KEY,
    customer_state CHAR(2) NOT NULL
);

CREATE TABLE orders (
    order_id TEXT PRIMARY KEY,
    customer_unique_id TEXT NOT NULL REFERENCES customers(customer_unique_id),
    order_status TEXT NOT NULL CHECK (
        order_status IN ('delivered', 'canceled', 'shipped')
    ),
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_total NUMERIC(10, 2) NOT NULL
);

INSERT INTO customers (
    customer_unique_id,
    customer_state
) VALUES
    ('customer_001', 'SP'),
    ('customer_002', 'RJ'),
    ('customer_003', 'MG'),
    ('customer_004', 'BA'),
    ('customer_005', 'SP'),
    ('customer_006', 'PR'),
    ('customer_007', 'PE'),
    ('customer_008', 'SC');

INSERT INTO orders (
    order_id,
    customer_unique_id,
    order_status,
    order_purchase_timestamp,
    order_total
) VALUES
    ('order_101', 'customer_001', 'delivered', '2024-01-05 10:15:00', 125.00),
    ('order_102', 'customer_001', 'canceled',  '2024-01-20 09:20:00',  90.00),
    ('order_103', 'customer_002', 'delivered', '2024-01-08 11:40:00',  75.00),
    ('order_104', 'customer_003', 'shipped',   '2024-01-14 12:30:00',  55.00),
    ('order_105', 'customer_005', 'delivered', '2024-01-18 08:55:00', 210.00),
    ('order_106', 'customer_005', 'delivered', '2024-01-26 18:10:00', 140.00),
    ('order_107', 'customer_006', 'canceled',  '2024-01-31 19:25:00',  65.00);

-- ================= TEACHING QUERIES (right panel) =================

-- 1. Scenario 1, the first attempt.
-- INNER JOIN removes unmatched customers before coverage is calculated.
SELECT
    COUNT(DISTINCT c.customer_unique_id) AS customers_seen,
    COUNT(DISTINCT c.customer_unique_id) FILTER (
        WHERE o.order_id IS NOT NULL
    ) AS customers_with_orders,
    COUNT(DISTINCT c.customer_unique_id) FILTER (
        WHERE o.order_id IS NULL
    ) AS customers_without_orders,
    ROUND(
        100.0 * COUNT(DISTINCT c.customer_unique_id) FILTER (
            WHERE o.order_id IS NOT NULL
        ) / NULLIF(COUNT(DISTINCT c.customer_unique_id), 0),
        2
    ) AS match_coverage_pct
FROM customers AS c
INNER JOIN orders AS o
    ON c.customer_unique_id = o.customer_unique_id;

-- 2. Scenario 1, the fix and main proof.
-- LEFT JOIN keeps the eight-customer denominator and exposes three misses.
SELECT
    COUNT(DISTINCT c.customer_unique_id) AS customers_seen,
    COUNT(DISTINCT c.customer_unique_id) FILTER (
        WHERE o.order_id IS NOT NULL
    ) AS customers_with_orders,
    COUNT(DISTINCT c.customer_unique_id) FILTER (
        WHERE o.order_id IS NULL
    ) AS customers_without_orders,
    ROUND(
        100.0 * COUNT(DISTINCT c.customer_unique_id) FILTER (
            WHERE o.order_id IS NOT NULL
        ) / NULLIF(COUNT(DISTINCT c.customer_unique_id), 0),
        2
    ) AS match_coverage_pct
FROM customers AS c
LEFT JOIN orders AS o
    ON c.customer_unique_id = o.customer_unique_id;

-- 3. Scenario 2, the first attempt.
-- The right-table WHERE condition removes customers with no delivered match.
SELECT
    c.customer_unique_id,
    c.customer_state,
    COUNT(o.order_id) AS delivered_orders
FROM customers AS c
LEFT JOIN orders AS o
    ON c.customer_unique_id = o.customer_unique_id
WHERE o.order_status = 'delivered'
GROUP BY
    c.customer_unique_id,
    c.customer_state
ORDER BY
    delivered_orders DESC,
    c.customer_unique_id;

-- 4. Scenario 2, the fix.
-- The status condition limits matches in ON while all customers survive.
SELECT
    c.customer_unique_id,
    c.customer_state,
    COUNT(o.order_id) AS delivered_orders
FROM customers AS c
LEFT JOIN orders AS o
    ON c.customer_unique_id = o.customer_unique_id
   AND o.order_status = 'delivered'
GROUP BY
    c.customer_unique_id,
    c.customer_state
ORDER BY
    delivered_orders DESC,
    c.customer_unique_id;

-- 5. Teaching-data Try-it answer check.
-- Changing the eligible status in ON still preserves all eight customers.
SELECT
    c.customer_unique_id,
    c.customer_state,
    COUNT(o.order_id) AS canceled_orders
FROM customers AS c
LEFT JOIN orders AS o
    ON c.customer_unique_id = o.customer_unique_id
   AND o.order_status = 'canceled'
GROUP BY
    c.customer_unique_id,
    c.customer_state
ORDER BY
    canceled_orders DESC,
    c.customer_unique_id;
