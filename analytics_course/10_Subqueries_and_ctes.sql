-- "Subqueries and CTEs a reviewer can follow" - Non-Brand Data, SQL Module 10
-- PostgreSQL 15
--
-- Final revisioned DB Fiddle URL: https://www.db-fiddle.com/f/2NYDszJXuRG7H2pwopDdDE/0
--
-- Expected results, in query order:
--   1. Nested query: U001 has 2 delivered orders and 200.00 revenue;
--      U003 has 2 and 200.00; U005 has 2 and 170.00. Ordered by customer.
--   2. CTE query: the same three rows and values as query 1.
--   3. Stage checks: prep has 7 rows, metrics has 4 rows, and final has
--      3 rows. Ordered as prep, metrics, final.
--   4. Result comparison: 0 difference rows and result = match.
--
-- The rows are small teaching data based on the Olist e-commerce schema.
-- The identifiers, dates, statuses, and values were made for this lesson.
-- They are not direct Olist extracts.

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
    ('order_1001', 'U001', 'delivered', '2024-04-02 09:15:00', 120.00),
    ('order_1002', 'U001', 'delivered', '2024-04-18 14:20:00',  80.00),
    ('order_1003', 'U002', 'delivered', '2024-04-11 11:05:00',  90.00),
    ('order_1004', 'U002', 'canceled',  '2024-04-20 16:40:00',  50.00),
    ('order_1005', 'U003', 'delivered', '2024-05-03 08:30:00', 160.00),
    ('order_1006', 'U003', 'delivered', '2024-05-15 13:10:00',  40.00),
    ('order_1007', 'U004', 'shipped',   '2024-05-17 10:45:00',  70.00),
    ('order_1008', 'U005', 'delivered', '2024-05-24 15:25:00', 110.00),
    ('order_1009', 'U005', 'delivered', '2024-06-01 12:00:00',  60.00);

-- ================= TEACHING QUERIES (right panel) =================

-- 1. Scenario 1, the nested query.
-- The inner query returns one row per delivered-order customer.
SELECT
    customer_unique_id,
    delivered_orders,
    delivered_revenue
FROM (
    SELECT
        customer_unique_id,
        COUNT(*) AS delivered_orders,
        SUM(order_total) AS delivered_revenue
    FROM orders
    WHERE order_status = 'delivered'
    GROUP BY customer_unique_id
) AS customer_metrics
WHERE delivered_orders >= 2
ORDER BY customer_unique_id;

-- 2. Scenario 1, the named CTE version.
-- The structure changes, while the final rows and values stay the same.
WITH prep AS (
    SELECT
        order_id,
        customer_unique_id,
        order_total
    FROM orders
    WHERE order_status = 'delivered'
),
metrics AS (
    SELECT
        customer_unique_id,
        COUNT(*) AS delivered_orders,
        SUM(order_total) AS delivered_revenue
    FROM prep
    GROUP BY customer_unique_id
),
final AS (
    SELECT
        customer_unique_id,
        delivered_orders,
        delivered_revenue
    FROM metrics
    WHERE delivered_orders >= 2
)
SELECT
    customer_unique_id,
    delivered_orders,
    delivered_revenue
FROM final
ORDER BY customer_unique_id;

-- 3. Scenario 2, row counts at every stage.
-- The order column keeps the displayed result deterministic.
WITH prep AS (
    SELECT
        order_id,
        customer_unique_id,
        order_total
    FROM orders
    WHERE order_status = 'delivered'
),
metrics AS (
    SELECT
        customer_unique_id,
        COUNT(*) AS delivered_orders,
        SUM(order_total) AS delivered_revenue
    FROM prep
    GROUP BY customer_unique_id
),
final AS (
    SELECT
        customer_unique_id,
        delivered_orders,
        delivered_revenue
    FROM metrics
    WHERE delivered_orders >= 2
)
SELECT stage_name, row_count
FROM (
    SELECT 1 AS stage_order, 'prep' AS stage_name, COUNT(*) AS row_count
    FROM prep
    UNION ALL
    SELECT 2, 'metrics', COUNT(*)
    FROM metrics
    UNION ALL
    SELECT 3, 'final', COUNT(*)
    FROM final
) AS stage_checks
ORDER BY stage_order;

-- 4. Scenario 2, compare the nested and CTE results in both directions.
-- Zero difference rows means the two result sets match.
WITH legacy AS (
    SELECT
        customer_unique_id,
        delivered_orders,
        delivered_revenue
    FROM (
        SELECT
            customer_unique_id,
            COUNT(*) AS delivered_orders,
            SUM(order_total) AS delivered_revenue
        FROM orders
        WHERE order_status = 'delivered'
        GROUP BY customer_unique_id
    ) AS customer_metrics
    WHERE delivered_orders >= 2
),
prep AS (
    SELECT
        order_id,
        customer_unique_id,
        order_total
    FROM orders
    WHERE order_status = 'delivered'
),
metrics AS (
    SELECT
        customer_unique_id,
        COUNT(*) AS delivered_orders,
        SUM(order_total) AS delivered_revenue
    FROM prep
    GROUP BY customer_unique_id
),
final AS (
    SELECT
        customer_unique_id,
        delivered_orders,
        delivered_revenue
    FROM metrics
    WHERE delivered_orders >= 2
),
old_minus_new AS (
    SELECT * FROM legacy
    EXCEPT
    SELECT * FROM final
),
new_minus_old AS (
    SELECT * FROM final
    EXCEPT
    SELECT * FROM legacy
),
differences AS (
    SELECT * FROM old_minus_new
    UNION ALL
    SELECT * FROM new_minus_old
)
SELECT
    COUNT(*) AS difference_rows,
    CASE WHEN COUNT(*) = 0 THEN 'match' ELSE 'different' END AS result
FROM differences;
