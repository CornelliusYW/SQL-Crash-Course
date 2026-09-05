-- "Reporting, what to claim and what to caveat" - Non-Brand Data, SQL Module 14
-- PostgreSQL 15
--
-- Final revisioned DB Fiddle URL: https://www.db-fiddle.com/f/tes65vHgN8URoXSm39j2Sq/0
--
-- Expected results, in query order:
--   1. Eight March delivered orders with total revenue 790.00.
--   2. Final state report, ordered by revenue:
--      SP: 3 customers, 5 orders, 520.00 revenue, 104.00 average
--          order value, 2 repeat customers, 66.67 percent repeat rate.
--      PR: 1 customer, 1 order, 95.00 revenue, 95.00 average,
--          0 repeat customers, 0.00 percent.
--      RJ: 1 customer, 1 order, 90.00 revenue, 90.00 average,
--          0 repeat customers, 0.00 percent.
--      BA: 1 customer, 1 order, 85.00 revenue, 85.00 average,
--          0 repeat customers, 0.00 percent.
--   3. Reconciliation: 8 source and report orders, 790.00 source and
--      report revenue, and a 0.00 revenue difference.
--   4. March status context: delivered 8 / 790.00, shipped 1 / 130.00,
--      canceled 1 / 70.00.
--
-- These are small invented teaching rows shaped like Olist customers
-- and orders. They are not direct Olist records.
-- This lesson treats the timestamps as UTC. order_total is measured in
-- Brazilian reais (BRL).

DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_unique_id TEXT PRIMARY KEY,
    customer_state TEXT NOT NULL
);

CREATE TABLE orders (
    order_id TEXT PRIMARY KEY,
    customer_unique_id TEXT NOT NULL REFERENCES customers(customer_unique_id),
    order_status TEXT NOT NULL,
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_total NUMERIC(10, 2) NOT NULL
);

INSERT INTO customers (customer_unique_id, customer_state) VALUES
    ('customer_001', 'SP'),
    ('customer_002', 'SP'),
    ('customer_003', 'RJ'),
    ('customer_004', 'MG'),
    ('customer_005', 'SP'),
    ('customer_006', 'RJ'),
    ('customer_007', 'PR'),
    ('customer_008', 'BA');

INSERT INTO orders (
    order_id,
    customer_unique_id,
    order_status,
    order_purchase_timestamp,
    order_total
) VALUES
    ('order_1401', 'customer_001', 'delivered', '2024-03-02 09:00:00', 120.00),
    ('order_1402', 'customer_001', 'delivered', '2024-03-18 11:00:00',  80.00),
    ('order_1403', 'customer_002', 'delivered', '2024-03-04 15:00:00', 150.00),
    ('order_1404', 'customer_003', 'delivered', '2024-03-08 10:00:00',  90.00),
    ('order_1405', 'customer_004', 'canceled',  '2024-03-10 13:00:00',  70.00),
    ('order_1406', 'customer_005', 'delivered', '2024-03-12 08:00:00', 110.00),
    ('order_1407', 'customer_005', 'delivered', '2024-03-29 17:00:00',  60.00),
    ('order_1408', 'customer_006', 'shipped',   '2024-03-21 12:00:00', 130.00),
    ('order_1409', 'customer_007', 'delivered', '2024-03-24 14:00:00',  95.00),
    ('order_1410', 'customer_008', 'delivered', '2024-03-30 16:00:00',  85.00),
    ('order_1411', 'customer_002', 'delivered', '2024-04-01 00:00:00', 200.00);

-- 1. Scenario 1, inspect the rows before writing a claim.
SELECT
    o.order_id,
    o.customer_unique_id,
    c.customer_state,
    o.order_purchase_timestamp,
    o.order_total
FROM orders AS o
JOIN customers AS c
  ON c.customer_unique_id = o.customer_unique_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= TIMESTAMP '2024-03-01 00:00:00'
  AND o.order_purchase_timestamp <  TIMESTAMP '2024-04-01 00:00:00'
ORDER BY o.order_purchase_timestamp, o.order_id;

-- 2. Scenario 1, final report table using prep -> metrics -> final.
WITH prep AS (
    SELECT
        o.order_id,
        o.customer_unique_id,
        c.customer_state,
        o.order_total
    FROM orders AS o
    JOIN customers AS c
      ON c.customer_unique_id = o.customer_unique_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= TIMESTAMP '2024-03-01 00:00:00'
      AND o.order_purchase_timestamp <  TIMESTAMP '2024-04-01 00:00:00'
),
customer_metrics AS (
    SELECT
        customer_state,
        customer_unique_id,
        COUNT(*) AS order_count,
        SUM(order_total) AS customer_revenue
    FROM prep
    GROUP BY customer_state, customer_unique_id
),
metrics AS (
    SELECT
        customer_state,
        COUNT(*) AS delivered_customers,
        SUM(order_count) AS delivered_orders,
        SUM(customer_revenue) AS delivered_revenue,
        COUNT(*) FILTER (WHERE order_count >= 2) AS repeat_customers
    FROM customer_metrics
    GROUP BY customer_state
),
final AS (
    SELECT
        customer_state,
        delivered_customers,
        delivered_orders,
        delivered_revenue,
        ROUND(delivered_revenue / NULLIF(delivered_orders, 0), 2) AS average_order_value,
        repeat_customers,
        ROUND(100.0 * repeat_customers / NULLIF(delivered_customers, 0), 2) AS repeat_customer_rate_pct
    FROM metrics
)
SELECT
    customer_state,
    delivered_customers,
    delivered_orders,
    delivered_revenue,
    average_order_value,
    repeat_customers,
    repeat_customer_rate_pct
FROM final
ORDER BY delivered_revenue DESC, customer_state;

-- 3. Scenario 2, reconcile the report to the filtered source.
WITH prep AS (
    SELECT
        o.order_id,
        o.customer_unique_id,
        c.customer_state,
        o.order_total
    FROM orders AS o
    JOIN customers AS c
      ON c.customer_unique_id = o.customer_unique_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= TIMESTAMP '2024-03-01 00:00:00'
      AND o.order_purchase_timestamp <  TIMESTAMP '2024-04-01 00:00:00'
),
customer_metrics AS (
    SELECT
        customer_state,
        customer_unique_id,
        COUNT(*) AS order_count,
        SUM(order_total) AS customer_revenue
    FROM prep
    GROUP BY customer_state, customer_unique_id
),
metrics AS (
    SELECT
        customer_state,
        SUM(order_count) AS delivered_orders,
        SUM(customer_revenue) AS delivered_revenue
    FROM customer_metrics
    GROUP BY customer_state
),
final AS (
    SELECT
        SUM(delivered_orders) AS report_orders,
        SUM(delivered_revenue) AS report_revenue
    FROM metrics
)
SELECT
    (SELECT COUNT(*) FROM prep) AS source_orders,
    final.report_orders,
    (SELECT SUM(order_total) FROM prep) AS source_revenue,
    final.report_revenue,
    (SELECT SUM(order_total) FROM prep) - final.report_revenue AS revenue_difference
FROM final;

-- 4. Scenario 2, show the records outside the delivered-order claim.
SELECT
    order_status,
    COUNT(*) AS order_rows,
    SUM(order_total) AS order_value
FROM orders
WHERE order_purchase_timestamp >= TIMESTAMP '2024-03-01 00:00:00'
  AND order_purchase_timestamp <  TIMESTAMP '2024-04-01 00:00:00'
GROUP BY order_status
ORDER BY
    CASE order_status
        WHEN 'delivered' THEN 1
        WHEN 'shipped' THEN 2
        WHEN 'canceled' THEN 3
        ELSE 4
    END,
    order_status;
