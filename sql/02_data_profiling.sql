/* 02_data_profiling.sql
   Data quality checks on the staging table (superstore_staging) before
   building the four modelled tables. Each check states the question it
   answers and the result. Issues found are documented in the README under
   Data Quality Notes and resolved in 03_build_tables.sql. */


-- Check 1: Does every product_id map to exactly one product_name?
-- Result: No. 32 product_ids are each linked to two different product_names.
-- product_id therefore cannot be the primary key of the products table.

-- CTE identifying product_ids with more than one product_name
WITH multiple_product_names AS (
SELECT
    product_id,
    COUNT(DISTINCT product_name) AS unique_product_names
FROM superstore_staging
GROUP BY product_id
HAVING COUNT(DISTINCT product_name) > 1
)

-- Count of affected product_ids
SELECT COUNT(*) AS product_id_with_multiple_names
FROM multiple_product_names;

-- Investigation: list each affected product_id with its product_names.
-- Result: 64 rows, so each of the 32 product_ids has exactly two product_names.
-- The names describe genuinely different products, not spelling variations.
-- Both products under each ID share the same category and sub_category, which
-- fits the ID format: a category code, a sub-category code, then a number
-- (e.g. FUR-BO-10001798), suggesting numbers were reused within a sub-category.
-- Resolution: products gets a surrogate key (product_key); see 03_build_tables.sql.

SELECT DISTINCT
    product_id,
    product_name,
    category,
    sub_category

FROM superstore_staging

WHERE product_id IN (           -- subquery to identify product_ids with multiple product_names
    SELECT
        product_id
    FROM superstore_staging
    GROUP BY product_id
    HAVING COUNT(DISTINCT product_name) > 1
)

ORDER BY product_id DESC;


-- Check 2: Does each customer_id always have the same customer_name and segment?
-- Result: Yes. 0 customer_ids have more than one name or segment.
-- customer_id can be the primary key of the customers table.

WITH multiple_segments AS (
SELECT
    customer_id,
    COUNT(DISTINCT customer_name) AS unique_customer_names,
    COUNT(DISTINCT segment) AS unique_segments
FROM superstore_staging
GROUP BY customer_id
HAVING COUNT(DISTINCT customer_name) > 1 OR COUNT(DISTINCT segment) > 1
)

SELECT COUNT(*)
FROM multiple_segments;


-- Check 3: Does each order_id always have the same customer, dates, ship mode and location?
-- Result: Yes. 0 order_ids have more than one value in any of these columns.
-- postal_code is used to represent location. These columns all belong in the
-- orders table, and order_id can be its primary key.

WITH multiple_order_details AS (
SELECT
    order_id,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT order_date) AS unique_order_dates,
    COUNT(DISTINCT ship_date) AS unique_ship_dates,
    COUNT(DISTINCT ship_mode) AS unique_ship_modes,
    COUNT(DISTINCT postal_code) AS unique_postal_codes
FROM superstore_staging
GROUP BY order_id
HAVING COUNT(DISTINCT customer_id) > 1
    OR COUNT(DISTINCT order_date) > 1
    OR COUNT(DISTINCT ship_date) > 1
    OR COUNT(DISTINCT ship_mode) > 1
    OR COUNT(DISTINCT postal_code) > 1
)

SELECT COUNT(*)
FROM multiple_order_details;


-- Check 4: Is each row_id unique?
-- Result: Yes. No row_id appears more than once.
-- row_id can be the primary key of the order_lines table.

SELECT
    row_id,
    COUNT(*) AS row_count
FROM superstore_staging
GROUP BY row_id
HAVING COUNT(*) > 1;


-- Check 5: Does each row_id always have the same order_id, product_id and customer_id?
-- Result: Yes. 0 row_ids have more than one value in these columns.

WITH multiple_row_details AS (
SELECT
    row_id,
    COUNT(DISTINCT order_id) AS unique_order_ids,
    COUNT(DISTINCT product_id) AS unique_product_ids,
    COUNT(DISTINCT customer_id) AS unique_customer_ids
FROM superstore_staging
GROUP BY row_id
HAVING COUNT(DISTINCT order_id) > 1
    OR COUNT(DISTINCT product_id) > 1
    OR COUNT(DISTINCT customer_id) > 1
)

SELECT COUNT(*)
FROM multiple_row_details;


-- Check 6: Are there any NULL or blank values in the key columns
-- (product_id, order_id, customer_id) or in postal_code?
-- Result: No. 0 NULL or blank values in all four columns.

SELECT
	SUM(CASE WHEN product_id IS NULL or product_id = '' THEN 1 ELSE 0 END) AS count_blank_product_id,
	SUM(CASE WHEN order_id IS NULL or order_id = '' THEN 1 ELSE 0 END) AS count_blank_order_id,
	SUM(CASE WHEN customer_id IS NULL or customer_id = '' THEN 1 ELSE 0 END) AS count_blank_customer_id,
	SUM(CASE WHEN postal_code IS NULL or postal_code = '' THEN 1 ELSE 0 END) AS count_blank_postal_code
FROM superstore_staging;


-- Check 7: Are all postal codes 5 digits long?
-- Result: No. 51 distinct postal codes, affecting 438 line items, have only 4 digits.

-- Count of distinct affected postal codes
SELECT
    COUNT(DISTINCT postal_code) AS count_invalid_postal_codes
FROM superstore_staging
WHERE LENGTH(postal_code) <> 5;

-- Count of affected line items
SELECT
    COUNT(postal_code)
FROM superstore_staging
WHERE LENGTH(postal_code) <> 5;

-- Investigation: list the affected postal codes with their location.
-- The affected codes belong to states whose ZIP codes begin with 0. The leading
-- zero was most likely dropped when the file was saved by a tool that treated
-- postal codes as numbers (e.g. Excel).
SELECT DISTINCT
    postal_code,
    country,
    city,
    state
FROM superstore_staging
WHERE LENGTH(postal_code) <> 5;

-- Fix test: LPAD restores the leading zero. This expression will be applied
-- when inserting into the orders table (03_build_tables.sql); staging stays unchanged.
SELECT DISTINCT
    postal_code,
    LPAD(postal_code, 5, '0') AS corrected_postal_code
FROM superstore_staging
WHERE LENGTH(postal_code) <> 5;


-- Check 8: Are sales, quantity and discount within realistic ranges?
-- (No negative or zero sales/quantities; discount between 0 and 1, where 0.2 = 20% off.)
-- Profit is excluded because negative profit (a loss-making sale) is valid.
-- Result: All values are within realistic ranges.
--   Sales:    min [__]  max [__]
--   Quantity: min [__]  max [__]
--   Discount: min [__]  max [__]
-- Note: the maximum discount is relevant to the high-discount analysis (Q6),
-- and the maximum sales value is an outlier to keep in mind for average order value (Q5).

SELECT
	MIN(CAST(sales AS numeric)) AS min_sales,
	MAX(CAST(sales AS numeric)) AS max_sales,
	MIN(CAST(quantity AS numeric)) AS min_quantity,
	MAX(CAST(quantity AS numeric)) AS max_quantity,
	MIN(CAST(discount AS numeric)) AS min_discount,
	MAX(CAST(discount AS numeric)) AS max_discount
FROM superstore_staging;