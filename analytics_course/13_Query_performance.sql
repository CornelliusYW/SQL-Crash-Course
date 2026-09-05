-- "Query performance" - Non-Brand Data, SQL Module 13
-- PostgreSQL 15
--
-- Final revisioned DB Fiddle URL: https://www.db-fiddle.com/f/aTVcPYugGBCJNZyUDtxJMY/0
--
-- Expected results, in query order:
--   1. The table contains 30,000 deterministic order rows.
--   2. Before the tracking-code index, the lookup plan contains a Seq Scan
--      with a filter on tracking_code.
--   3. The lookup returns order 28731, customer_08731, delivered,
--      2024-09-17 03:00:00, and 42.31.
--   4. After the tracking-code index, the same lookup plan contains an
--      Index Scan using orders_performance_tracking_code_idx.
--   5. The broad delivered-revenue plan contains an Aggregate node over a
--      Seq Scan with a delivered-status filter in the saved DB Fiddle.
--      Plan choices can vary with server statistics and settings, so read
--      the node shown by the environment instead of memorizing it.
--   6. The summary returns 24,000 delivered orders from 30,000 total orders,
--      80.00 percent, and delivered revenue of 719,640.00.
--
-- These rows are generated teaching data shaped like an order table.
-- The identifiers, timestamps, statuses, and values are not Olist records.

DROP TABLE IF EXISTS orders_performance;

CREATE TABLE orders_performance (
    order_id INTEGER PRIMARY KEY,
    tracking_code TEXT NOT NULL,
    customer_unique_id TEXT NOT NULL,
    order_status TEXT NOT NULL,
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_total NUMERIC(10, 2) NOT NULL,
    delivery_note TEXT NOT NULL
);

INSERT INTO orders_performance (
    order_id,
    tracking_code,
    customer_unique_id,
    order_status,
    order_purchase_timestamp,
    order_total,
    delivery_note
)
SELECT
    g AS order_id,
    'TRK-' || LPAD(g::TEXT, 5, '0') AS tracking_code,
    'customer_' || LPAD((((g - 1) % 10000) + 1)::TEXT, 5, '0') AS customer_unique_id,
    CASE
        WHEN g % 10 < 8 THEN 'delivered'
        WHEN g % 10 = 8 THEN 'shipped'
        ELSE 'canceled'
    END AS order_status,
    TIMESTAMP '2024-01-01 00:00:00'
        + ((g - 1) % 365) * INTERVAL '1 day'
        + (g % 24) * INTERVAL '1 hour' AS order_purchase_timestamp,
    ROUND(((g % 5000) + 500) / 100.0, 2) AS order_total,
    REPEAT('deterministic teaching row ', 4) AS delivery_note
FROM GENERATE_SERIES(1, 30000) AS series(g);

ANALYZE orders_performance;

-- 1. Confirm the teaching-data scale.
SELECT COUNT(*) AS generated_order_rows
FROM orders_performance;

-- 2. Scenario 1, plan before the useful index.
EXPLAIN (COSTS OFF)
SELECT
    order_id,
    customer_unique_id,
    order_status,
    order_purchase_timestamp,
    order_total
FROM orders_performance
WHERE tracking_code = 'TRK-28731';

-- 3. Confirm that the query returns the intended row.
SELECT
    order_id,
    customer_unique_id,
    order_status,
    order_purchase_timestamp,
    order_total
FROM orders_performance
WHERE tracking_code = 'TRK-28731';

-- Add an index that matches the selective lookup condition.
CREATE INDEX orders_performance_tracking_code_idx
    ON orders_performance (tracking_code);

ANALYZE orders_performance;

-- 4. Scenario 1, the same plan after the useful index.
EXPLAIN (COSTS OFF)
SELECT
    order_id,
    customer_unique_id,
    order_status,
    order_purchase_timestamp,
    order_total
FROM orders_performance
WHERE tracking_code = 'TRK-28731';

-- Add a second index for the broad-filter comparison.
CREATE INDEX orders_performance_status_idx
    ON orders_performance (order_status);

ANALYZE orders_performance;

-- 5. Scenario 2, a broad filter may still favor a sequential scan.
EXPLAIN (COSTS OFF)
SELECT SUM(order_total) AS delivered_revenue
FROM orders_performance
WHERE order_status = 'delivered';

-- 6. Show how much of the table qualifies.
SELECT
    COUNT(*) FILTER (WHERE order_status = 'delivered') AS delivered_orders,
    COUNT(*) AS all_orders,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE order_status = 'delivered')
        / NULLIF(COUNT(*), 0),
        2
    ) AS delivered_share_pct,
    SUM(order_total) FILTER (WHERE order_status = 'delivered') AS delivered_revenue
FROM orders_performance;

-- Remove the test index when no other workload needs it.
DROP INDEX orders_performance_status_idx;
