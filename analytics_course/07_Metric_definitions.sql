-- "Metric definitions two people compute the same way" - Non-Brand Data, SQL Module 7
-- PostgreSQL 15
-- Final revisioned DB Fiddle URL: https://www.db-fiddle.com/f/db6ebJgdoDmLVfS7q6YvJH/0
--
-- Expected results, in query order:
--   1. Mixed calendar windows: 7 deliveries in January, 9 purchases in
--      January, delivery_to_purchase_ratio_pct = 77.78.
--   2. January purchase-cohort order completion: 6 delivered orders,
--      9 placed orders, order_completion_rate_pct = 66.67.
--   3. Order counts with customer labels: 6 customers_with_delivery,
--      9 cohort_customers, customer_completion_rate_pct = 66.67.
--      The labels are intentionally wrong because COUNT(*) counts orders.
--   4. Two metric rows, ordered by metric:
--      customer_completion_rate | 5 | 6 | 83.33
--      order_completion_rate    | 6 | 9 | 66.67
--
-- The rows are deterministic teaching data based on the Olist e-commerce
-- schema. The identifiers, dates, and statuses are made for this lesson.
-- They are not direct extracts from Olist. Treat the table as a snapshot
-- taken after 2024-02-15.

-- ================= SCHEMA AND SEED DATA (left panel) =================

DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    order_id TEXT PRIMARY KEY,
    customer_unique_id TEXT NOT NULL,
    order_status TEXT NOT NULL CHECK (
        order_status IN ('delivered', 'canceled', 'shipped')
    ),
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_delivered_customer_date TIMESTAMP NULL
);

INSERT INTO orders (
    order_id,
    customer_unique_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date
) VALUES
    ('order_090', 'customer_007', 'delivered', '2023-12-20 09:00:00', '2024-01-03 13:00:00'),
    ('order_091', 'customer_008', 'delivered', '2023-12-24 11:15:00', '2024-01-07 15:20:00'),
    ('order_092', 'customer_009', 'delivered', '2023-12-28 14:30:00', '2024-01-18 10:45:00'),
    ('order_093', 'customer_010', 'delivered', '2023-12-30 16:40:00', '2024-01-29 12:10:00'),
    ('order_101', 'customer_001', 'delivered', '2024-01-05 10:15:00', '2024-01-10 14:30:00'),
    ('order_102', 'customer_001', 'canceled',  '2024-01-20 09:20:00', NULL),
    ('order_103', 'customer_002', 'delivered', '2024-01-08 11:40:00', '2024-01-12 16:25:00'),
    ('order_104', 'customer_003', 'canceled',  '2024-01-14 12:30:00', NULL),
    ('order_105', 'customer_004', 'delivered', '2024-01-26 08:55:00', '2024-02-03 17:05:00'),
    ('order_106', 'customer_005', 'delivered', '2024-01-30 18:10:00', '2024-02-10 09:35:00'),
    ('order_107', 'customer_006', 'shipped',   '2024-01-31 19:25:00', NULL),
    ('order_108', 'customer_003', 'delivered', '2024-01-28 07:35:00', '2024-02-06 11:50:00'),
    ('order_109', 'customer_004', 'delivered', '2024-01-18 13:00:00', '2024-01-25 15:45:00'),
    ('order_201', 'customer_001', 'delivered', '2024-02-04 10:05:00', '2024-02-12 14:15:00'),
    ('order_202', 'customer_011', 'canceled',  '2024-02-08 09:15:00', NULL);

-- ================= TEACHING QUERIES (right panel) =================

-- 1. Scenario 1, the first attempt.
-- The numerator uses delivery month while the denominator uses purchase month.
SELECT
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND order_delivered_customer_date >= TIMESTAMP '2024-01-01 00:00:00'
          AND order_delivered_customer_date <  TIMESTAMP '2024-02-01 00:00:00'
    ) AS delivered_in_january,
    COUNT(*) FILTER (
        WHERE order_purchase_timestamp >= TIMESTAMP '2024-01-01 00:00:00'
          AND order_purchase_timestamp <  TIMESTAMP '2024-02-01 00:00:00'
    ) AS purchased_in_january,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND order_delivered_customer_date >= TIMESTAMP '2024-01-01 00:00:00'
              AND order_delivered_customer_date <  TIMESTAMP '2024-02-01 00:00:00'
        )
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_purchase_timestamp >= TIMESTAMP '2024-01-01 00:00:00'
                  AND order_purchase_timestamp <  TIMESTAMP '2024-02-01 00:00:00'
            ),
            0
        ),
        2
    ) AS delivery_to_purchase_ratio_pct
FROM orders;

-- 2. Scenario 1, the fix.
-- Purchase date defines one cohort for both numerator and denominator.
WITH january_purchase_cohort AS (
    SELECT
        order_id,
        order_status
    FROM orders
    WHERE order_purchase_timestamp >= TIMESTAMP '2024-01-01 00:00:00'
      AND order_purchase_timestamp <  TIMESTAMP '2024-02-01 00:00:00'
)
SELECT
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders,
    COUNT(*) AS placed_orders,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_status = 'delivered'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS order_completion_rate_pct
FROM january_purchase_cohort;

-- 3. Scenario 2, the first attempt.
-- The aliases say customers, but COUNT(*) still counts order rows.
WITH january_purchase_cohort AS (
    SELECT
        order_id,
        customer_unique_id,
        order_status
    FROM orders
    WHERE order_purchase_timestamp >= TIMESTAMP '2024-01-01 00:00:00'
      AND order_purchase_timestamp <  TIMESTAMP '2024-02-01 00:00:00'
)
SELECT
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS customers_with_delivery,
    COUNT(*) AS cohort_customers,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_status = 'delivered'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS customer_completion_rate_pct
FROM january_purchase_cohort;

-- 4. Scenario 2, the fix and comparison.
-- Both rates keep the same cohort and observation cutoff. Only the key changes.
WITH january_purchase_cohort AS (
    SELECT
        order_id,
        customer_unique_id,
        order_status
    FROM orders
    WHERE order_purchase_timestamp >= TIMESTAMP '2024-01-01 00:00:00'
      AND order_purchase_timestamp <  TIMESTAMP '2024-02-01 00:00:00'
)
SELECT
    'customer_completion_rate' AS metric,
    COUNT(DISTINCT customer_unique_id) FILTER (
        WHERE order_status = 'delivered'
    ) AS numerator,
    COUNT(DISTINCT customer_unique_id) AS denominator,
    ROUND(
        100.0 * COUNT(DISTINCT customer_unique_id) FILTER (
            WHERE order_status = 'delivered'
        ) / NULLIF(COUNT(DISTINCT customer_unique_id), 0),
        2
    ) AS conversion_rate_pct
FROM january_purchase_cohort

UNION ALL

SELECT
    'order_completion_rate' AS metric,
    COUNT(DISTINCT order_id) FILTER (
        WHERE order_status = 'delivered'
    ) AS numerator,
    COUNT(DISTINCT order_id) AS denominator,
    ROUND(
        100.0 * COUNT(DISTINCT order_id) FILTER (
            WHERE order_status = 'delivered'
        ) / NULLIF(COUNT(DISTINCT order_id), 0),
        2
    ) AS conversion_rate_pct
FROM january_purchase_cohort
ORDER BY metric;
