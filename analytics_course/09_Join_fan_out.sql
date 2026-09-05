-- "Join fan-out and the total that inflates" - Non-Brand Data, SQL Module 9
-- PostgreSQL 15
--
-- Final revisioned DB Fiddle URL: https://www.db-fiddle.com/f/qCdfcfoccu6hH4sZ9VLiAA/0
--
-- Expected results, in query order:
--   1. One-child raw join: 6 joined rows, 3 distinct order rows,
--      reported order total 590.00. The correct source total is 290.00.
--   2. One-child pre-aggregation: 3 order rows, correct order total
--      290.00, and 6 item rows.
--   3. Two-child raw join: 11 joined rows, 3 order rows, 6 item rows,
--      5 payment rows, reported item total 500.00, and reported payment
--      total 590.00. Both correct source totals are 290.00.
--   4. Two-child pre-aggregation: 3 order rows, 6 item rows, 5 payment
--      rows, correct item total 290.00, and correct payment total 290.00.
--
-- The rows are small teaching data based on the Olist e-commerce schema.
-- The identifiers, timestamps, values, products, sellers, and payment
-- records were made for this lesson. They are not direct Olist extracts.

-- ================= SCHEMA AND SEED DATA (left panel) =================

DROP TABLE IF EXISTS order_payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    order_id TEXT PRIMARY KEY,
    customer_unique_id TEXT NOT NULL,
    order_status TEXT NOT NULL,
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_total NUMERIC(10, 2) NOT NULL
);

CREATE TABLE order_items (
    order_item_id TEXT PRIMARY KEY,
    order_id TEXT NOT NULL REFERENCES orders(order_id),
    product_id TEXT NOT NULL,
    seller_id TEXT NOT NULL,
    item_value NUMERIC(10, 2) NOT NULL
);

CREATE TABLE order_payments (
    payment_id TEXT PRIMARY KEY,
    order_id TEXT NOT NULL REFERENCES orders(order_id),
    payment_sequential INTEGER NOT NULL,
    payment_type TEXT NOT NULL,
    payment_installments INTEGER NOT NULL,
    payment_value NUMERIC(10, 2) NOT NULL
);

INSERT INTO orders (
    order_id,
    customer_unique_id,
    order_status,
    order_purchase_timestamp,
    order_total
) VALUES
    ('order_1001', 'customer_001', 'delivered', '2024-03-03 09:15:00', 120.00),
    ('order_1002', 'customer_002', 'delivered', '2024-03-05 13:40:00',  80.00),
    ('order_1003', 'customer_003', 'delivered', '2024-03-08 17:10:00',  90.00);

INSERT INTO order_items (
    order_item_id,
    order_id,
    product_id,
    seller_id,
    item_value
) VALUES
    ('item_1001_1', 'order_1001', 'product_101', 'seller_01', 70.00),
    ('item_1001_2', 'order_1001', 'product_102', 'seller_02', 50.00),
    ('item_1002_1', 'order_1002', 'product_103', 'seller_01', 80.00),
    ('item_1003_1', 'order_1003', 'product_104', 'seller_03', 30.00),
    ('item_1003_2', 'order_1003', 'product_105', 'seller_03', 35.00),
    ('item_1003_3', 'order_1003', 'product_106', 'seller_04', 25.00);

INSERT INTO order_payments (
    payment_id,
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
) VALUES
    ('payment_1001_1', 'order_1001', 1, 'credit_card', 2, 100.00),
    ('payment_1001_2', 'order_1001', 2, 'voucher',     1,  20.00),
    ('payment_1002_1', 'order_1002', 1, 'debit_card', 1,  80.00),
    ('payment_1003_1', 'order_1003', 1, 'credit_card', 1,  60.00),
    ('payment_1003_2', 'order_1003', 2, 'voucher',     1,  30.00);

-- ================= TEACHING QUERIES (right panel) =================

-- 1. Scenario 1, the first attempt.
-- The order value repeats once for every item row.
SELECT
    COUNT(*) AS joined_rows,
    COUNT(DISTINCT o.order_id) AS order_rows,
    SUM(o.order_total) AS reported_order_total
FROM orders AS o
JOIN order_items AS i
  ON i.order_id = o.order_id;

-- 2. Scenario 1, the fix.
-- Reduce the child table to one row per order before the join.
WITH items_per_order AS (
    SELECT
        order_id,
        COUNT(*) AS item_rows
    FROM order_items
    GROUP BY order_id
)
SELECT
    COUNT(*) AS order_rows,
    SUM(o.order_total) AS correct_order_total,
    SUM(i.item_rows) AS item_rows
FROM orders AS o
JOIN items_per_order AS i
  ON i.order_id = o.order_id;

-- 3. Scenario 2, the first attempt.
-- Every item pairs with every payment inside the same order.
SELECT
    COUNT(*) AS joined_rows,
    COUNT(DISTINCT o.order_id) AS order_rows,
    COUNT(DISTINCT i.order_item_id) AS item_rows,
    COUNT(DISTINCT p.payment_id) AS payment_rows,
    SUM(i.item_value) AS reported_item_total,
    SUM(p.payment_value) AS reported_payment_total
FROM orders AS o
JOIN order_items AS i
  ON i.order_id = o.order_id
JOIN order_payments AS p
  ON p.order_id = o.order_id;

-- 4. Scenario 2, the fix.
-- Pre-aggregate each one-to-many child at order grain before joining.
WITH item_totals AS (
    SELECT
        order_id,
        COUNT(*) AS item_rows,
        SUM(item_value) AS item_total
    FROM order_items
    GROUP BY order_id
),
payment_totals AS (
    SELECT
        order_id,
        COUNT(*) AS payment_rows,
        SUM(payment_value) AS payment_total
    FROM order_payments
    GROUP BY order_id
)
SELECT
    COUNT(*) AS order_rows,
    SUM(COALESCE(i.item_rows, 0)) AS item_rows,
    SUM(COALESCE(p.payment_rows, 0)) AS payment_rows,
    SUM(COALESCE(i.item_total, 0)) AS correct_item_total,
    SUM(COALESCE(p.payment_total, 0)) AS correct_payment_total
FROM orders AS o
LEFT JOIN item_totals AS i
  ON i.order_id = o.order_id
LEFT JOIN payment_totals AS p
  ON p.order_id = o.order_id;
