/* 03_build_tables.sql
   Builds the four modelled tables (customers, products, orders, order_lines)
   from the staging table (superstore_staging). Data is cleaned as it is
   inserted; the staging table is left unchanged.
   Design decisions and data quality fixes are documented in the README
   under Data Model and Data Quality Notes. */


-- Drop existing tables so the script can be re-run from scratch
DROP TABLE IF EXISTS order_lines;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;


-- Table 1: customers (dimension) - one row per customer
CREATE TABLE customers (
	customer_id TEXT PRIMARY KEY,
	customer_name TEXT NOT NULL,
	segment TEXT NOT NULL
);

-- DISTINCT reduces staging (one row per line item) to one row per customer.
-- Safe because profiling (Check 2) confirmed each customer_id has one name and segment.
INSERT INTO customers (customer_id, customer_name, segment)
SELECT DISTINCT
    customer_id,
    customer_name,
    segment
FROM superstore_staging;


-- Table 2: products (dimension) - one row per product
-- product_id is not unique (see Data Quality Notes), so a surrogate key
-- (product_key) is the primary key. The UNIQUE constraint ensures each
-- product_id + product_name pair appears only once.
CREATE TABLE products (
	product_key INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	product_id TEXT NOT NULL,
	product_name TEXT NOT NULL,
	category TEXT NOT NULL,
	sub_category TEXT NOT NULL,
	UNIQUE (product_id, product_name)
);

-- product_key is omitted from the insert; PostgreSQL generates it automatically.
INSERT INTO products (product_id, product_name, category, sub_category)
SELECT DISTINCT
	product_id,
	product_name,
	category,
	sub_category
FROM superstore_staging;


-- Table 3: orders (header) - one row per order
CREATE TABLE orders (
	order_id TEXT PRIMARY KEY,
	customer_id TEXT NOT NULL REFERENCES customers(customer_id),
	order_date DATE NOT NULL,
	ship_date DATE,			-- Nullable: an order may be placed but not yet shipped.
	ship_mode TEXT,			-- Nullable for the same reason as ship_date.
	country TEXT NOT NULL,
	city TEXT NOT NULL,
	state TEXT NOT NULL,
	postal_code TEXT NOT NULL CHECK (LENGTH(postal_code) = 5),
	region TEXT NOT NULL
);

-- Cleaning applied on insert:
--   TO_DATE converts text dates (e.g. 11/8/2017) to real DATE values.
--   LPAD restores the leading zero dropped from 4-digit ZIP codes (see Data Quality Notes).
-- DISTINCT is safe because profiling (Check 3) confirmed each order_id has one set of values.
INSERT INTO orders (order_id, customer_id, order_date, ship_date, ship_mode, country, city, state, postal_code, region)
SELECT DISTINCT
	order_id, 
	customer_id, 
	TO_DATE(order_date, 'MM/DD/YYYY'), 
	TO_DATE(ship_date, 'MM/DD/YYYY'), 
	ship_mode, 
	country, 
	city, 
	state, 
	LPAD(postal_code, 5, '0'), 
	region
FROM superstore_staging;

-- Table 4: order_lines (fact) - one row per line item
-- NUMERIC is used for money and discount values because it stores exact decimals.
CREATE TABLE order_lines (
	row_id INTEGER PRIMARY KEY,
	order_id TEXT NOT NULL REFERENCES orders(order_id),
	product_key INTEGER NOT NULL REFERENCES products(product_key),
	sales NUMERIC NOT NULL,
	quantity INTEGER NOT NULL,
	discount NUMERIC NOT NULL,
	profit NUMERIC NOT NULL
);

-- Staging has no product_key, so each line item looks up its key by joining
-- to products on BOTH product_id and product_name (product_id alone is not unique).
-- Text columns are cast to their numeric types on insert.
INSERT INTO order_lines (row_id, order_id, product_key, sales, quantity, discount, profit)
SELECT
	CAST(row_id AS INTEGER),
	order_id,
	p.product_key,
	CAST(sales AS NUMERIC),
	CAST(quantity AS INTEGER),
	CAST(discount AS NUMERIC),
	CAST(profit AS NUMERIC)
FROM superstore_staging s
JOIN products p
	ON s.product_id = p.product_id
	AND s.product_name = p.product_name
;

-- Validation (run after the build):
--   Row counts: customers 793, products 1,894, orders 5,009, order_lines 9,994 - all match staging.
--   SUM(sales) and SUM(profit) in order_lines match staging exactly.
--   order_date ranges from 2014-01-03 to 2017-12-30.


-- Validation 1: Row counts of the four tables
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_lines', COUNT(*) FROM order_lines;

-- Validation 2: Expected counts from staging (should match Validation 1)
SELECT
    COUNT(DISTINCT customer_id) AS customers,
    COUNT(DISTINCT (product_id, product_name)) AS products,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(*) AS order_lines
FROM superstore_staging;

-- Validation 3: Sales and profit totals match between staging and order_lines
SELECT
    (SELECT SUM(CAST(sales AS NUMERIC)) FROM superstore_staging) AS staging_sales,
    (SELECT SUM(sales) FROM order_lines) AS order_lines_sales,
    (SELECT SUM(CAST(profit AS NUMERIC)) FROM superstore_staging) AS staging_profit,
    (SELECT SUM(profit) FROM order_lines) AS order_lines_profit;

-- Validation 4: Order dates converted correctly (expect 2014-01-03 to 2017-12-30)
SELECT MIN(order_date) AS first_order, MAX(order_date) AS last_order
FROM orders;

-- Validation 5: Leading zeros restored (expect 51 postal codes starting with 0). Returned 52, likely because one already began with 0.
SELECT COUNT(DISTINCT postal_code) AS zero_prefixed_postal_codes
FROM orders
WHERE postal_code LIKE '0%';