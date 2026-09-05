-- "Getting the question right before any SQL" - Non-Brand Data, SQL Module 1
-- DB Fiddle setup (PostgreSQL 15). Schema block into the left panel,
-- queries block into the right panel.
--
-- Live fiddle, tested and matching this file exactly:
-- https://www.db-fiddle.com/f/8JL5ZLxYCbWoCh2pa5x9re/2
--
-- Expected results, in order:
--   1. 15
--   2. 7 rows
--   3. 0.0
--   4. 20.0
--   5. top rows 0, 35, 40
--   6. 28.6 on 7 customers
--
-- This fiddle is the reader-facing path for Module 1: no account, no
-- download, and no local database. The rows are invented teaching data
-- shaped like Olist customer and order tables. They are not direct Olist
-- records.

-- ================= SCHEMA (left panel) =================
CREATE TABLE customers (customer_id INT, customer_unique_id TEXT);
CREATE TABLE orders (order_id INT, customer_id INT, order_status TEXT, order_purchase_timestamp TIMESTAMP);

INSERT INTO customers VALUES
 (1,'P1'),(2,'P1'),(3,'P2'),(4,'P3'),(5,'P3'),(6,'P4'),(7,'P4'),(8,'P5'),
 (9,'P6'),(10,'P7'),(11,'P8'),(12,'P9'),(13,'P10'),(14,'P11'),(15,'P7');

INSERT INTO orders VALUES
 (1,1,'delivered','2017-01-15 10:00'),
 (2,2,'delivered','2017-02-20 11:00'),
 (3,3,'delivered','2017-03-01 09:00'),
 (4,4,'delivered','2017-01-10 08:00'),
 (5,5,'delivered','2017-08-01 08:00'),
 (6,6,'canceled' ,'2017-02-01 08:00'),
 (7,7,'delivered','2017-02-15 08:00'),
 (8,8,'delivered','2018-01-05 08:00'),
 (9,9,'delivered','2017-01-20 08:00'),
 (10,10,'delivered','2017-03-15 08:00'),
 (11,11,'delivered','2017-03-22 08:00'),
 (12,12,'canceled' ,'2017-04-01 08:00'),
 (13,13,'delivered','2018-01-10 08:00'),
 (14,14,'delivered','2018-02-14 08:00'),
 (15,15,'delivered','2017-04-01 08:00');

-- ================= QUERIES (right panel) =================

-- 1. Scenario 1, the default move: one number, no population, no window.
-- Returns: 15
SELECT COUNT(*) FROM orders;

-- 2. Scenario 1, the fix: delivered orders by month.
-- Returns: 7 rows
SELECT
    date_trunc('month', order_purchase_timestamp) AS order_month,
    COUNT(*) AS delivered_orders
FROM orders
WHERE order_status = 'delivered'
  AND order_purchase_timestamp >= '2017-01-01'
  AND order_purchase_timestamp <  '2019-01-01'
GROUP BY 1
ORDER BY 1;

-- 3. Scenario 2, the default move: repeat rate on customer_id.
-- customer_id is unique per order, so this can only ever return zero.
-- Returns: 0.0
SELECT
    ROUND(100.0 * COUNT(*) FILTER (WHERE order_count > 1) / COUNT(*), 1) AS repeat_rate_pct
FROM (
    SELECT customer_id, COUNT(*) AS order_count
    FROM orders
    GROUP BY customer_id
) c;

-- 4. Scenario 2, the fix: one customer = one customer_unique_id, delivered
-- only, next order within 90 days.
-- Returns: 20.0
WITH delivered_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
sequenced AS (
    SELECT
        customer_unique_id,
        order_purchase_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp
        ) AS order_seq,
        LEAD(order_purchase_timestamp) OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp
        ) AS next_order_ts
    FROM delivered_orders
)
SELECT
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE next_order_ts IS NOT NULL
              AND next_order_ts <= order_purchase_timestamp + INTERVAL '90 days'
        ) / COUNT(*)
    , 1) AS repeat_rate_pct
FROM sequenced
WHERE order_seq = 1;

-- 5. Scenario 2, the assumption still in there: how many days did each
-- customer actually have in which to come back?
-- Returns: top rows 0, 35, 40
WITH delivered_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
sequenced AS (
    SELECT
        customer_unique_id,
        order_purchase_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp
        ) AS order_seq,
        LEAD(order_purchase_timestamp) OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp
        ) AS next_order_ts
    FROM delivered_orders
)
SELECT
    customer_unique_id,
    order_purchase_timestamp AS first_order,
    DATE_PART('day', (SELECT MAX(order_purchase_timestamp) FROM orders)
                     - order_purchase_timestamp) AS days_they_had
FROM sequenced
WHERE order_seq = 1
ORDER BY days_they_had;

-- 6. Scenario 2, corrected: drop customers who never had a full 90 days.
-- Returns: 28.6 on 7 customers
WITH delivered_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_purchase_timestamp
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
),
sequenced AS (
    SELECT
        customer_unique_id,
        order_purchase_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp
        ) AS order_seq,
        LEAD(order_purchase_timestamp) OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp
        ) AS next_order_ts
    FROM delivered_orders
)
SELECT
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE next_order_ts IS NOT NULL
              AND next_order_ts <= order_purchase_timestamp + INTERVAL '90 days'
        ) / COUNT(*)
    , 1) AS repeat_rate_pct,
    COUNT(*) AS customers_counted
FROM sequenced
WHERE order_seq = 1
  AND order_purchase_timestamp + INTERVAL '90 days'
      <= (SELECT MAX(order_purchase_timestamp) FROM orders);
