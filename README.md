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
*SQL: [`sql/04_revenue_by_category.sql`](sql/04_revenue_by_category.sql)*

| Category | Revenue | Share of Revenue | Line Items | Share of Line Items | Avg Revenue per Line Item |
|---|---|---|---|---|---|
| Technology | $836,154.03 | 36.40% | 1,847 | 18.48% | $452.71 |
| Furniture | $741,999.80 | 32.30% | 2,121 | 21.22% | $349.83 |
| Office Supplies | $719,047.03 | 31.30% | 6,026 | 60.30% | $119.32 |

**Revenue is evenly split across categories, but each category gets there differently.** Technology generates the largest share of revenue (36.40%) from the smallest share of line items (18.48%), driven by the highest average revenue per line item. Office Supplies is the opposite: it accounts for 60.30% of line items but only 31.30% of revenue, making it a high-volume, low-value category.

**At the sub-category level, revenue is concentrated.** Phones ($330,007.05, 14.37%) and Chairs together bring in nearly 29% of revenue, and the top four sub-categories (Phones, Chairs, Storage, Tables) account for about 47%. At the other end, Fasteners is the smallest sub-category at $3,024.28 (0.13%).

*Note: this analysis covers revenue only; profitability by category may tell a different story.*

### 2. Top 10 Customers by Lifetime Spend
*SQL: [`sql/05_top_customers.sql`](sql/05_top_customers.sql)*

| Rank | Customer | Lifetime Sales | Orders | Avg Sales per Order | Share of Total Revenue |
|---|---|---|---|---|---|
| 1 | Sean Miller | $25,043.05 | 5 | $5,008.61 | 1.09% |
| 2 | Tamara Chand | $19,052.22 | 5 | $3,810.44 | 0.83% |
| 3 | Raymond Buch | $15,117.34 | 6 | $2,519.56 | 0.66% |
| 4 | Tom Ashbrook | $14,595.62 | 4 | $3,648.91 | 0.64% |
| 5 | Adrian Barton | $14,473.57 | 10 | $1,447.36 | 0.63% |
| 6 | Ken Lonsdale | $14,175.23 | 12 | $1,181.27 | 0.62% |
| 7 | Sanjit Chand | $14,142.33 | 9 | $1,571.37 | 0.62% |
| 8 | Hunter Lopez | $12,873.30 | 6 | $2,145.55 | 0.56% |
| 9 | Sanjit Engle | $12,209.44 | 11 | $1,109.95 | 0.53% |
| 10 | Christopher Conant | $12,129.07 | 5 | $2,425.81 | 0.53% |

**No single customer drives the business.** The top 10 customers together account for only 6.70% of total revenue ($153,811.17), and the largest, Sean Miller, accounts for 1.09%. Revenue is spread across a broad customer base, so the business does not depend on any one account.

**Two customers stand out, and the rest are closely grouped.** Sean Miller and Tamara Chand are well ahead of the rest, together making up 28.67% of top-10 sales. Customers #3 to #10 fall within about $3,000 of each other ($12,129.07 to $15,117.34).

**Top customers reach their totals in two different ways.** Some place a few large orders: Sean Miller's 5 orders average $5,008.61, and Tom Ashbrook's 4 orders average $3,648.91. Others order often at lower values: Ken Lonsdale placed 12 orders averaging $1,181.27, and Sanjit Engle placed 11 orders averaging $1,109.95. A loyalty or account-management approach would need to account for both groups.

*Note: customers are ranked by revenue only, so the most valuable customers by profit may differ. Customers are grouped by `customer_id`, so two customers with the same name are counted separately.*

### 3. Month-over-Month Revenue
*SQL: [`sql/06_monthly_revenue_trend.sql`](sql/06_monthly_revenue_trend.sql)*

| Year | Revenue | Change vs. Prior Year | Months Above Same Month Prior Year |
|---|---|---|---|
| 2014 | $484,247.51 | — | — |
| 2015 | $470,532.51 | -2.83% | 6 of 12 |
| 2016 | $609,205.60 | +29.47% | 11 of 12 |
| 2017 | $733,215.26 | +20.36% | 8 of 12 |

**Month to month, revenue follows a seasonal cycle rather than steady growth.** Revenue rose in only 21 of 47 months, and the same pattern repeats every year. January or February is always the lowest month, with January falling 55–75% from December. March rebounds by 125–224% (2015–2017), and September, November and December are the three highest-revenue months every year. The peak was November 2017 at $118,447.83. The largest swing, +1,132.13% in March 2014, reflects an unusually low February 2014 ($4,519.89) rather than an exceptional March.

**Year over year, the business is growing.** After a 2.83% dip in 2015, annual revenue grew 29.47% in 2016 and 20.36% in 2017, ending 51.41% above 2014. In 2016, 11 of 12 months beat the same month a year earlier. Individual months still vary widely, from -30.46% to +164.42%, so annual totals and same-month comparisons give a more reliable read of growth than month-over-month change.

*Note: because of this seasonality, the weekly report should compare each period with the same period last year rather than with the period just before it.*

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