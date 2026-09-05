-- "Filtering with WHERE without losing rows to NULLs"
-- Non-Brand Data, SQL and analytics course, Module 3
-- PostgreSQL 15
--
-- Live DB Fiddle URL:
-- https://www.db-fiddle.com/f/kPQaLgrP67a4LcPDN8xWPC/0
--
-- Teaching data based on the Olist e-commerce schema. The rows and IDs below
-- are made for teaching and are not direct extracts from Olist.
--
-- Expected results, in query order:
--   1. 6 rows: o1001, o1002, o1003, o1006, o1007, o1010
--      Two NULL-status orders are lost with the two canceled orders.
--   2. 8 rows: o1001, o1002, o1003, o1004, o1006, o1007, o1008, o1010
--      The NULL-status orders o1004 and o1008 are included explicitly.
--   3. 5 rows in the UTC day: o1002, o1003, o1004, o1005, o1006
--      o1002 is 14 June in Sao Paulo. Late local orders o1007 and o1008
--      are missing because their UTC date is 16 June.
--   4. 6 rows on 15 June in Sao Paulo: o1003, o1004, o1005, o1006,
--      o1007, o1008

-- ================= SCHEMA AND SEED DATA (left panel) =================

CREATE TABLE orders (
    order_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    order_status TEXT,
    order_purchase_timestamp TIMESTAMPTZ NOT NULL
);

INSERT INTO orders (
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp
) VALUES
    ('o1001', 'c001', 'delivered', TIMESTAMPTZ '2018-06-14 23:30:00+00'),
    ('o1002', 'c002', 'delivered', TIMESTAMPTZ '2018-06-15 00:30:00+00'),
    ('o1003', 'c003', 'shipped',   TIMESTAMPTZ '2018-06-15 03:00:00+00'),
    ('o1004', 'c004', NULL,        TIMESTAMPTZ '2018-06-15 12:00:00+00'),
    ('o1005', 'c005', 'canceled',  TIMESTAMPTZ '2018-06-15 14:30:00+00'),
    ('o1006', 'c006', 'delivered', TIMESTAMPTZ '2018-06-15 23:59:00+00'),
    ('o1007', 'c007', 'approved',  TIMESTAMPTZ '2018-06-16 01:30:00+00'),
    ('o1008', 'c008', NULL,        TIMESTAMPTZ '2018-06-16 02:59:00+00'),
    ('o1009', 'c009', 'canceled',  TIMESTAMPTZ '2018-06-16 03:00:00+00'),
    ('o1010', 'c010', 'invoiced',  TIMESTAMPTZ '2018-06-16 10:00:00+00');

-- ================= TEACHING QUERIES (right panel) =================

-- 1. Scenario 1, the default filter.
-- Returns 6 rows and drops both NULL-status rows.
SELECT
    order_id,
    order_status
FROM orders
WHERE order_status <> 'canceled'
ORDER BY order_id;

-- 2. Scenario 1, the explicit fix.
-- Returns 8 rows, including o1004 and o1008 with NULL status.
SELECT
    order_id,
    order_status
FROM orders
WHERE order_status <> 'canceled'
   OR order_status IS NULL
ORDER BY order_id;

-- 3. Scenario 2, the wrong population.
-- The request names the Sao Paulo date, but this filter uses the UTC day.
-- Returns 5 rows: o1002, o1003, o1004, o1005, o1006.
SELECT
    order_id,
    order_purchase_timestamp,
    order_purchase_timestamp AT TIME ZONE 'America/Sao_Paulo' AS sao_paulo_time
FROM orders
WHERE order_purchase_timestamp >= TIMESTAMPTZ '2018-06-15 00:00:00+00'
  AND order_purchase_timestamp <  TIMESTAMPTZ '2018-06-16 00:00:00+00'
ORDER BY order_purchase_timestamp, order_id;

-- 4. Scenario 2, the corrected local-day filter.
-- Sao Paulo was UTC-03:00 on 15 June 2018, so the local day maps to
-- [2018-06-15 03:00:00+00, 2018-06-16 03:00:00+00).
-- Returns 6 rows: o1003, o1004, o1005, o1006, o1007, o1008.
SELECT
    order_id,
    order_purchase_timestamp,
    order_purchase_timestamp AT TIME ZONE 'America/Sao_Paulo' AS sao_paulo_time
FROM orders
WHERE order_purchase_timestamp >=
          TIMESTAMP '2018-06-15 00:00:00' AT TIME ZONE 'America/Sao_Paulo'
  AND order_purchase_timestamp <
          TIMESTAMP '2018-06-16 00:00:00' AT TIME ZONE 'America/Sao_Paulo'
ORDER BY order_purchase_timestamp, order_id;
