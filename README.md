# Superstore Sales Analysis

## Project Overview
As a junior analyst at a retail company, I was asked to build the SQL behind a weekly sales report for my manager. Using four years of transactional sales data, I analyzed revenue trends, customer value, regional performance, and discounting practices to identify where the business is growing and where it is falling short.

The project covers the full analyst workflow: loading raw data into a database, profiling it for quality issues, modelling it into clean relational tables, and answering business questions with SQL.

---

## Business Questions
1. What is the total revenue by product category and sub-category?
2. Who are the top 10 customers by lifetime spend?
3. How does revenue compare month over month?
4. Which regions are underperforming against target?
5. What is the average order value for each customer segment?
6. Which orders received unusually high discounts?

---

## Project Scope
- Loading a raw CSV into PostgreSQL through a staging table
- Profiling the data for duplicates, blanks, inconsistent values, and key uniqueness
- Splitting the flat file into a normalized four-table model
- Writing SQL to answer each business question
- Summarizing findings in plain business language

---

## Data Source
- **Dataset:** [Superstore Dataset (Kaggle)](https://www.kaggle.com/datasets/vivek468/superstore-dataset-final)
- **File:** `superstore_data.csv`
- **Size:** 21 columns, 9,994 rows
- **Downloaded:** *November 7, 2026*

---

## About the Data
Each row in the raw file represents a **line item**: one product within an order. An order with several products appears across several rows, so a row count is not an order count. This grain shapes several queries in the project, most notably average order value.

Each row also carries details about the order, the product, and the customer, which are repeated on every line. To remove that repetition and support multi-table joins, the data is split into four tables.

---

## Data Model

| Table | Type | Primary Key | Columns | Links To |
|---|---|---|---|---|
| `customers` | Dimension | Customer ID | Customer ID, Customer Name, Segment | — |
| `products` | Dimension | product_key *(see Data Quality Notes)* | product_key, Product ID, Category, Sub-Category, Product Name | — |
| `orders` | Header | Order ID | Order ID, Customer ID, Order Date, Ship Date, Ship Mode, Country, City, State, Postal Code, Region | `customers` |
| `order_lines` | Fact | Row ID | Row ID, Order ID, product_key, Sales, Quantity, Discount, Profit | `orders`, `products` |

**Relationships**
- One customer places many orders
- One order contains many line items
- One product appears on many line items

**Design decision:** Location columns sit on `orders` rather than `customers`, because profiling showed that the same customer can ship to more than one address.

---

## Tools
- **PostgreSQL** – database
- **pgAdmin 4** – database administration and data import
- **VS Code** – SQL development
- **Git / GitHub** – version control

---

## Methodology
1. **Load:** Imported the raw CSV into a text-only staging table (`stg_superstore`) so no values were lost or misread during the load. Validated with a row count.
2. **Profile:** Queried the staging table to check key uniqueness, duplicates, blanks, formats, and unrealistic values.
3. **Build:** Created the four modelled tables and cleaned the data as it was inserted (type conversions, format fixes). The staging table is left unchanged as an exact copy of the source.
4. **Validate:** Confirmed that row counts and revenue totals match between staging and the final tables.
5. **Analyze:** Wrote one SQL script per business question.

---

## Data Quality Notes
*[Complete after profiling. For each issue: what was found, how many rows it affects, and how it was handled.]*

### 1. Product ID is not unique
- **Issue:** 32 `product_id` values are each linked to two different `product_name` values (64 products in total).
- **Evidence:** Reviewing the pairs showed they are genuinely different products, not spelling variations. Both products under each ID always share the same `category` and `sub_category`, which fits the ID format: the prefix encodes the category and sub-category (e.g. `FUR-BO-`), suggesting numbers were reused within a sub-category.
- **Impact:** `product_id` cannot be the primary key of the `products` table. Deleting one name per ID would remove 32 products and attach their sales to the wrong product.
- **Resolution:** A surrogate key (`product_key`) was added as the primary key of `products`. `product_id` is kept as a regular column, so the original identifier is still available. `order_lines` stores `product_key` instead of `product_id`, giving a single-column join to `products`.
- **Query:** `sql/02_data_profiling.sql`, Check 1

### 2. Postal codes missing leading zeros
- **Issue:** 438 line items have a 4-digit `postal_code` instead of the standard 5-digit US ZIP code.
- **Evidence:** All affected codes belong to states whose ZIP codes begin with 0 ([list the states from your query]). [X] distinct postal codes across [Y] orders are affected. The leading zero was most likely stripped when the file was saved by a tool that treated postal codes as numbers, such as Excel.
- **Impact:** Affected codes don't match their real ZIP codes, so any lookup, join or map built on postal code would place these orders incorrectly or fail to match them.
- **Resolution:** `LPAD(postal_code, 5, '0')` restores the leading zero when data is inserted into the `orders` table. The staging table is left unchanged.
- **Query:** `sql/02_data_profiling.sql`, Check [6]

**Also checked (no issues found):** `customer_id`, `order_id` and `row_id` are unique and consistent across all their attributes; key columns and `postal_code` contain no NULL or blank values; and `sales`, `quantity` and `discount` all fall within realistic ranges. See `sql/02_data_profiling.sql` for each check and its result.

## Key Findings

### 1. Revenue by Category and Sub-Category
| Category | Revenue | Share |
|---|---|---|
| Technology | $836,154.03 | 36.4% |
| Furniture | $741,999.80 | 32.3% |
| Office Supplies | $719,047.03 | 31.3% |

**Revenue is balanced across categories but concentrated in a few sub-categories.** The three categories are within about five percentage points of each other, so no category dominates. At the sub-category level the picture changes: Phones ($330,007.05, 14.4%) and Chairs ($328,449.10, 14.3%) together bring in nearly 29% of all revenue, and the top four sub-categories (Phones, Chairs, Storage, Tables) account for about 47% of revenue across 17 sub-categories.

Office Supplies has the most sub-categories (9) but the lowest revenue. Its five smallest (Supplies, Art, Envelopes, Labels and Fasteners) together contribute less than 5% of revenue, with Fasteners the lowest at $3,024.28 (0.1%).

*Note: this analysis covers revenue only. Profitability by category and sub-category may tell a different story.*

### 2. Top 10 Customers by Lifetime Spend
*[Finding]*

### 3. Month-over-Month Revenue
*[Finding]*

### 4. Regional Performance vs. Target
*Target definition: [explain how the target was set and why]*

*[Finding]*

### 5. Average Order Value by Customer Segment
*[Finding]*

### 6. High-Discount Orders
*Definition of "unusually high": [explain the threshold and why]*

*[Finding]*

---

## Recommendations
*[Two or three actions the business could take based on the findings]*

---

## Repository Structure
```
Superstore-Sales-Analysis/
│
├── data/
│   └── raw/
│       └── superstore_data.csv          # Original Kaggle file, never modified
│
├── sql/
│   ├── 01_load_staging.sql              # Create staging table, load CSV, row-count check
│   ├── 02_data_profiling.sql            # Data quality checks on the staging table
│   ├── 03_build_tables.sql              # Create the four tables; clean data on insert
│   ├── 04_revenue_by_category.sql       # Q1: Revenue by category and sub-category
│   ├── 05_top_customers.sql             # Q2: Top 10 customers by lifetime spend
│   ├── 06_monthly_revenue_trend.sql     # Q3: Month-over-month revenue
│   ├── 07_regional_performance.sql      # Q4: Regions vs. target
│   ├── 08_aov_by_segment.sql            # Q5: Average order value by segment
│   └── 09_high_discount_orders.sql      # Q6: Unusually high discounts
│
├── images/
│   └── erd.png                          # Data model diagram (optional)
│
└── README.md
```

---

## How to Reproduce
1. Download the dataset from Kaggle and save it to `data/raw/`.
2. In pgAdmin, create a database named `superstore_db`.
3. Run the scripts in `sql/` in numerical order. `01_load_staging.sql` notes the import settings used (CSV format, header row on, WIN1252 encoding).