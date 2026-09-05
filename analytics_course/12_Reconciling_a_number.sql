-- "Reconciling a number before you trust it" - Non-Brand Data, SQL Module 12
-- PostgreSQL 15
--
-- Final revisioned DB Fiddle URL: https://www.db-fiddle.com/f/d8KDVv2GQwZE55h8sH4qgu/0
--
-- Expected results, in query order:
--   1. Different time windows: monthly_revenue 700.00,
--      four_week_revenue 520.00, difference 180.00.
--   2. One March population split into weekly buckets:
--      2024-02-26 180.00, 2024-03-04 120.00,
--      2024-03-11 60.00, 2024-03-18 90.00,
--      2024-03-25 250.00, TOTAL 700.00.
--   3. Failed staging checks:
--      Join row count: 8 observed, 7 expected, order_1207 repeats.
--      Payment key uniqueness: 9 rows / 8 IDs observed,
--      one row per payment_id expected, payment_1207 repeats.
--      Payment order coverage: 1 unmatched row observed,
--      0 expected, payment_1299 -> order_1299.
--      Raw payment total: 810.00 observed, 700.00 expected,
--      difference 110.00.
--   4. Corrected staging checks:
--      Accepted payment key uniqueness: PASS, 7 rows / 7 IDs.
--      Accepted order coverage: PASS, 7 matched orders / 7 March orders.
--      Monthly payment total: PASS, 700.00 / 700.00, difference 0.00.
--      Payment quarantine: REVIEW, 1 row / 25.00,
--      payment_1299 -> order_1299.
--
-- The rows are small teaching data based on the Olist e-commerce schema.
-- The order and payment identifiers, timestamps, values, and load records
-- were made for this lesson. They are not direct Olist extracts.

-- ================= SCHEMA AND SEED DATA (left panel) =================

DROP TABLE IF EXISTS order_payments_staging;
DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    order_id TEXT PRIMARY KEY,
    customer_unique_id TEXT NOT NULL,
    order_status TEXT NOT NULL,
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_total NUMERIC(10, 2) NOT NULL
);

CREATE TABLE order_payments_staging (
    staging_row_id TEXT PRIMARY KEY,
    payment_id TEXT NOT NULL,
    order_id TEXT NOT NULL,
    payment_value NUMERIC(10, 2) NOT NULL,
    loaded_at TIMESTAMP NOT NULL
);

INSERT INTO orders (
    order_id,
    customer_unique_id,
    order_status,
    order_purchase_timestamp,
    order_total
) VALUES
    ('order_1201', 'customer_001', 'delivered', '2024-03-01 09:00:00', 100.00),
    ('order_1202', 'customer_002', 'delivered', '2024-03-03 11:00:00',  80.00),
    ('order_1203', 'customer_003', 'delivered', '2024-03-08 15:00:00', 120.00),
    ('order_1204', 'customer_004', 'delivered', '2024-03-14 10:00:00',  60.00),
    ('order_1209', 'customer_009', 'canceled',  '2024-03-16 12:00:00',  50.00),
    ('order_1205', 'customer_005', 'delivered', '2024-03-21 18:00:00',  90.00),
    ('order_1206', 'customer_006', 'delivered', '2024-03-28 08:00:00', 140.00),
    ('order_1207', 'customer_007', 'delivered', '2024-03-31 22:00:00', 110.00),
    ('order_1208', 'customer_008', 'delivered', '2024-04-01 00:00:00', 200.00);

INSERT INTO order_payments_staging (
    staging_row_id,
    payment_id,
    order_id,
    payment_value,
    loaded_at
) VALUES
    ('staging_01', 'payment_1201', 'order_1201', 100.00, '2024-04-01 08:01:00'),
    ('staging_02', 'payment_1202', 'order_1202',  80.00, '2024-04-01 08:02:00'),
    ('staging_03', 'payment_1203', 'order_1203', 120.00, '2024-04-01 08:03:00'),
    ('staging_04', 'payment_1204', 'order_1204',  60.00, '2024-04-01 08:04:00'),
    ('staging_05', 'payment_1205', 'order_1205',  90.00, '2024-04-01 08:05:00'),
    ('staging_06', 'payment_1206', 'order_1206', 140.00, '2024-04-01 08:06:00'),
    ('staging_07', 'payment_1207', 'order_1207', 110.00, '2024-04-01 08:07:00'),
    ('staging_08', 'payment_1207', 'order_1207', 110.00, '2024-04-02 08:07:00'),
    ('staging_09', 'payment_1299', 'order_1299',  25.00, '2024-04-02 08:09:00');

-- ================= TEACHING QUERIES (right panel) =================

-- 1. Scenario 1, the first attempt.
-- The calendar-month query and four-complete-week query use different starts.
WITH monthly_total AS (
    SELECT SUM(order_total) AS revenue
    FROM orders
    WHERE order_status = 'delivered'
      AND order_purchase_timestamp >= TIMESTAMP '2024-03-01 00:00:00'
      AND order_purchase_timestamp <  TIMESTAMP '2024-04-01 00:00:00'
),
four_complete_weeks AS (
    SELECT SUM(order_total) AS revenue
    FROM orders
    WHERE order_status = 'delivered'
      AND order_purchase_timestamp >= TIMESTAMP '2024-03-04 00:00:00'
      AND order_purchase_timestamp <  TIMESTAMP '2024-04-01 00:00:00'
)
SELECT
    m.revenue AS monthly_revenue,
    w.revenue AS four_week_revenue,
    m.revenue - w.revenue AS difference
FROM monthly_total AS m
CROSS JOIN four_complete_weeks AS w;

-- 2. Scenario 1, the fix.
-- One scoped population feeds every weekly bucket and their total.
WITH scoped_orders AS (
    SELECT
        order_id,
        order_purchase_timestamp,
        order_total
    FROM orders
    WHERE order_status = 'delivered'
      AND order_purchase_timestamp >= TIMESTAMP '2024-03-01 00:00:00'
      AND order_purchase_timestamp <  TIMESTAMP '2024-04-01 00:00:00'
),
weekly AS (
    SELECT
        DATE_TRUNC('week', order_purchase_timestamp)::date AS week_start,
        SUM(order_total) AS weekly_revenue
    FROM scoped_orders
    GROUP BY DATE_TRUNC('week', order_purchase_timestamp)::date
),
rows_to_show AS (
    SELECT
        1 AS sort_group,
        week_start,
        TO_CHAR(week_start, 'YYYY-MM-DD') AS period,
        weekly_revenue AS revenue
    FROM weekly

    UNION ALL

    SELECT
        2 AS sort_group,
        NULL::date AS week_start,
        'TOTAL' AS period,
        SUM(weekly_revenue) AS revenue
    FROM weekly
)
SELECT
    period,
    revenue
FROM rows_to_show
ORDER BY sort_group, week_start NULLS LAST;

-- 3. Scenario 2, failed checks.
-- The raw staging table has a repeated payment ID and an unmatched payment.
WITH scoped_orders AS (
    SELECT
        order_id,
        order_total
    FROM orders
    WHERE order_status = 'delivered'
      AND order_purchase_timestamp >= TIMESTAMP '2024-03-01 00:00:00'
      AND order_purchase_timestamp <  TIMESTAMP '2024-04-01 00:00:00'
),
raw_join AS (
    SELECT
        o.order_id,
        o.order_total,
        p.payment_id,
        p.payment_value
    FROM scoped_orders AS o
    LEFT JOIN order_payments_staging AS p
      ON p.order_id = o.order_id
),
checks AS (
    SELECT
        1 AS check_order,
        'Join row count' AS check_name,
        'FAIL' AS status,
        (SELECT COUNT(*)::text FROM raw_join) AS observed,
        (SELECT COUNT(*)::text FROM scoped_orders) AS expected,
        'order_1207 repeats' AS offending_rows

    UNION ALL

    SELECT
        2,
        'Payment key uniqueness',
        'FAIL',
        (SELECT COUNT(*)::text || ' rows / '
            || COUNT(DISTINCT payment_id)::text || ' IDs'
         FROM order_payments_staging),
        'one row per payment_id',
        'payment_1207'

    UNION ALL

    SELECT
        3,
        'Payment order coverage',
        'FAIL',
        (SELECT COUNT(*)::text || ' unmatched row'
         FROM order_payments_staging AS p
         LEFT JOIN orders AS o
           ON o.order_id = p.order_id
         WHERE o.order_id IS NULL),
        '0 unmatched rows',
        'payment_1299 -> order_1299'

    UNION ALL

    SELECT
        4,
        'Raw payment total',
        'FAIL',
        (SELECT TO_CHAR(SUM(payment_value), 'FM999999990.00') FROM raw_join),
        (SELECT TO_CHAR(SUM(order_total), 'FM999999990.00') FROM scoped_orders),
        'difference 110.00'
)
SELECT
    check_name,
    status,
    observed,
    expected,
    offending_rows
FROM checks
ORDER BY check_order;

-- 4. Scenario 2, corrected checks.
-- Keep the latest staging row per payment ID and report unmatched rows separately.
WITH scoped_orders AS (
    SELECT
        order_id,
        order_total
    FROM orders
    WHERE order_status = 'delivered'
      AND order_purchase_timestamp >= TIMESTAMP '2024-03-01 00:00:00'
      AND order_purchase_timestamp <  TIMESTAMP '2024-04-01 00:00:00'
),
ranked_payments AS (
    SELECT
        p.*,
        ROW_NUMBER() OVER (
            PARTITION BY payment_id
            ORDER BY loaded_at DESC, staging_row_id DESC
        ) AS row_number_for_payment
    FROM order_payments_staging AS p
),
deduplicated_payments AS (
    SELECT
        payment_id,
        order_id,
        payment_value
    FROM ranked_payments
    WHERE row_number_for_payment = 1
),
accepted_payments AS (
    SELECT
        p.payment_id,
        p.order_id,
        p.payment_value
    FROM deduplicated_payments AS p
    JOIN scoped_orders AS o
      ON o.order_id = p.order_id
),
unmatched_payments AS (
    SELECT
        p.payment_id,
        p.order_id,
        p.payment_value
    FROM deduplicated_payments AS p
    LEFT JOIN orders AS o
      ON o.order_id = p.order_id
    WHERE o.order_id IS NULL
),
checks AS (
    SELECT
        1 AS check_order,
        'Accepted payment key uniqueness' AS check_name,
        'PASS' AS status,
        (SELECT COUNT(*)::text || ' rows / '
            || COUNT(DISTINCT payment_id)::text || ' IDs'
         FROM accepted_payments) AS observed,
        'one row per payment_id' AS expected,
        'none' AS rows_to_review

    UNION ALL

    SELECT
        2,
        'Accepted order coverage',
        'PASS',
        (SELECT COUNT(DISTINCT order_id)::text || ' matched orders'
         FROM accepted_payments),
        (SELECT COUNT(*)::text || ' March orders' FROM scoped_orders),
        'none'

    UNION ALL

    SELECT
        3,
        'Monthly payment total',
        'PASS',
        (SELECT TO_CHAR(SUM(payment_value), 'FM999999990.00') FROM accepted_payments),
        (SELECT TO_CHAR(SUM(order_total), 'FM999999990.00') FROM scoped_orders),
        'difference 0.00'

    UNION ALL

    SELECT
        4,
        'Payment quarantine',
        'REVIEW',
        (SELECT COUNT(*)::text || ' row / '
            || TO_CHAR(SUM(payment_value), 'FM999999990.00')
         FROM unmatched_payments),
        'review outside accepted total',
        (SELECT payment_id || ' -> ' || order_id FROM unmatched_payments)
)
SELECT
    check_name,
    status,
    observed,
    expected,
    rows_to_review
FROM checks
ORDER BY check_order;
