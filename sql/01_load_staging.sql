-- 1. Create the superstore_staging table
CREATE TABLE superstore_staging (
	row_id 			TEXT,
	order_id 		TEXT,
	order_date 		TEXT,
	ship_date 		TEXT,
	ship_mode 		TEXT,
	customer_id 	TEXT,
	customer_name 	TEXT,
	segment 		TEXT,
	country 		TEXT,
	city 			TEXT,
	state 			TEXT,
	postal_code 	TEXT,
	region 			TEXT,
	product_id 		TEXT,
	category 		TEXT,
	sub_category 	TEXT,
	product_name 	TEXT,
	sales 			TEXT,
	quantity 		TEXT,
	discount 		TEXT,
	profit 			TEXT
);

-- 2. Importing data into the superstore_staging table
-- Loaded via pgAdmin Import/Export (Format: csv, Header: on, Encoding: WIN1252, Escape: ")
-- File path is machine-specific; update it to your local copy of the data.
copy public.superstore_staging(
	row_id, 
	order_id, 
	order_date, 
	ship_date, 
	ship_mode, 
	customer_id, 
	customer_name, 
	segment, 
	country, 
	city, 
	state, 
	postal_code, 
	region, 
	product_id, 
	category, 
	sub_category, 
	product_name, 
	sales, 
	quantity, 
	discount, 
	profit) 
FROM 'C:/Users/nhame/DATAAN~2/SUPERS~1/data/raw/SUPERS~1.CSV' 
WITH(FORMAT csv, DELIMITER ',', HEADER, ENCODING 'WIN1252', QUOTE '\"', ESCAPE '\"');

-- 3. Checking row count: 9,994 expected
SELECT COUNT(*)
FROM superstore_staging;