-- "SELECT, FROM, and the grain of a row" - Non-Brand Data, SQL Module 2
-- DB Fiddle setup for PostgreSQL 15. Put the schema block in the left panel
-- and the query block in the right panel.
--
-- Final live URL:
-- https://www.db-fiddle.com/f/b4muu1u2tYjtUwu2PJEVye/0
--
-- Expected results, in query order:
--   1. Five rows ordered O1001, O1002, O1003, O1004, O1005, with all seven columns.
--   2. The same five rows with four explicit columns.
--   3. row_count = 8; distinct_orders = 8.
--   4. customers = 8. The alias is intentionally wrong for the teaching example.
--   5. order_rows = 8; order_customer_ids = 8; unique_people = 6.
--   6. Six rows ordered U001 to U006. U001 and U003 each have two orders;
--      U002, U004, U005, and U006 each have one.
--
-- The rows below are invented teaching data based on the Olist schema. They
-- are not direct extracts from Olist or client data.

-- ================= SCHEMA (left panel) =================

CREATE TABLE customers (
    customer_id TEXT PRIMARY KEY,
    customer_unique_id TEXT NOT NULL,
    customer_city TEXT NOT NULL,
    customer_state CHAR(2) NOT NULL
);

CREATE TABLE orders (
    order_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL REFERENCES customers(customer_id),
    order_status TEXT NOT NULL,
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_approved_at TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP NOT NULL
);

INSERT INTO customers (
    customer_id,
    customer_unique_id,
    customer_city,
    customer_state
) VALUES
    ('C101', 'U001', 'sao paulo',      'SP'),
    ('C102', 'U002', 'rio de janeiro', 'RJ'),
    ('C103', 'U001', 'sao paulo',      'SP'),
    ('C104', 'U003', 'curitiba',       'PR'),
    ('C105', 'U004', 'salvador',       'BA'),
    ('C106', 'U005', 'campinas',       'SP'),
    ('C107', 'U003', 'curitiba',       'PR'),
    ('C108', 'U006', 'recife',         'PE');

INSERT INTO orders (
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_customer_date,
    order_estimated_delivery_date
) VALUES
    ('O1001', 'C101', 'delivered',  '2018-01-05 09:15', '2018-01-05 09:30', '2018-01-10 16:00', '2018-01-12 00:00'),
    ('O1002', 'C102', 'shipped',    '2018-01-06 10:20', '2018-01-06 10:45', NULL,               '2018-01-14 00:00'),
    ('O1003', 'C103', 'delivered',  '2018-01-08 13:05', '2018-01-08 13:25', '2018-01-11 11:40', '2018-01-15 00:00'),
    ('O1004', 'C104', 'canceled',   '2018-01-09 17:50', NULL,               NULL,               '2018-01-17 00:00'),
    ('O1005', 'C105', 'delivered',  '2018-01-11 08:10', '2018-01-11 08:20', '2018-01-16 15:30', '2018-01-18 00:00'),
    ('O1006', 'C106', 'delivered',  '2018-01-12 12:00', '2018-01-12 12:15', '2018-01-18 10:05', '2018-01-20 00:00'),
    ('O1007', 'C107', 'delivered',  '2018-02-03 14:35', '2018-02-03 14:50', '2018-02-08 09:20', '2018-02-10 00:00'),
    ('O1008', 'C108', 'processing', '2018-02-05 16:25', '2018-02-05 16:40', NULL,               '2018-02-15 00:00');

-- ================= QUERIES (right panel) =================

-- 1. Scenario 1, the default: inspect every column.
-- Returns the first five orders in purchase order: O1001 through O1005.
SELECT *
FROM orders
ORDER BY order_purchase_timestamp, order_id
LIMIT 5;

-- 2. Scenario 1, the fix: select the columns needed to understand the row.
-- Returns the same five orders with four explicit columns.
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp
FROM orders
ORDER BY order_purchase_timestamp, order_id
LIMIT 5;

-- 3. Scenario 1, check the proposed grain: one row per order.
-- Returns: 8 | 8
SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM orders;

-- 4. Scenario 2, the default: order rows mislabeled as customers.
-- Returns: 8
SELECT COUNT(*) AS customers
FROM orders;

-- 5. Scenario 2, the fix: compare order rows with distinct people.
-- Returns: 8 | 8 | 6
SELECT
    COUNT(*) AS order_rows,
    COUNT(DISTINCT o.customer_id) AS order_customer_ids,
    COUNT(DISTINCT c.customer_unique_id) AS unique_people
FROM orders o
JOIN customers c
  ON c.customer_id = o.customer_id;

-- 6. Scenario 2, show which orders belong to the same person.
-- Returns:
-- U001 | 2 | O1001, O1003
-- U002 | 1 | O1002
-- U003 | 2 | O1004, O1007
-- U004 | 1 | O1005
-- U005 | 1 | O1006
-- U006 | 1 | O1008
SELECT
    c.customer_unique_id,
    COUNT(*) AS order_count,
    STRING_AGG(o.order_id, ', ' ORDER BY o.order_id) AS order_ids
FROM orders o
JOIN customers c
  ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
ORDER BY c.customer_unique_id;
