# Superstore Sales Analysis

## Project Overview
This project is an end-to-end SQL analysis of four years of transactional sales data from a US retail company. I approached it the way I would a request from a business stakeholder: the company needs the SQL behind a weekly sales report and wants to know where it is growing, where it is falling short, and what to do about it. The analysis covers revenue by product, customer value, regional performance, and the effect of discounting on profit, and ends with recommendations the business could act on.

In my current role in the federal public sector, I analyze transaction data for compliance monitoring and spend reporting. I built this project to apply those skills in a commercial setting and to deepen my SQL in PostgreSQL. It covers the full analyst workflow: loading raw data into a database, profiling it for quality issues, modelling it into clean relational tables, and answering business questions with SQL.

---

## Business Questions
1. What is the total revenue by product category and sub-category?
2. Who are the top 10 customers by lifetime spend?
3. How does revenue compare month over month?
4. Which regions are underperforming against target?
5. What is the average order value for each customer segment?

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

*Note: this analysis covers revenue only. Profit by category is covered in Finding 4: Furniture brings in 32.30% of revenue but only 6.44% of profit.*

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

### 4. Regional Performance
*SQL: [`sql/07_regional_performance.sql`](sql/07_regional_performance.sql)*
 
| Region | Total Profit | Share of Profit | Orders | Share of Orders | Profit per Order | Avg Discount (sales-weighted) |
|---|---|---|---|---|---|---|
| West | $108,418.45 | 37.86% | 1,611 | 32.16% | $67.30 | 12.88% |
| East | $91,522.78 | 31.96% | 1,401 | 27.97% | $65.33 | 13.94% |
| South | $46,749.43 | 16.32% | 822 | 16.41% | $56.87 | 14.49% |
| Central | $39,706.36 | 13.86% | 1,175 | 23.46% | $33.79 | 15.52% |
 
**Central is the weakest region, and the problem is profit per order, not volume.** Central earns the least profit (13.86% of the total) despite handling 23.46% of orders, more than South. Its profit per order of $33.79 is half of West's and well below the company-wide average of $57.18. West leads on both volume and profit per order, earning 2.73 times Central's profit.
 
**Profit per order falls as discounts rise.** The regions rank in exactly opposite order on discount and profit per order: West gives the lowest average discount (12.88%) and Central the highest (15.52%). Discount alone does not explain Central's gap, however: it earns $23.08 less per order than South with a discount only 1.03 points higher.

**Profit Margin by Region and Category**

| Region | Technology | Office Supplies | Furniture |
|---|---|---|---|
| West | 17.58% | 23.82% | 4.55% |
| East | 17.91% | 19.96% | 1.46% |
| South | 13.44% | 15.91% | 5.77% |
| Central | 19.77% | 5.32% | -1.75% |
| **All regions** | **17.40%** | **17.04%** | **2.49%** |

**Central's gap comes from its Office Supplies and Furniture margins, not its product mix.** Central's revenue is split almost evenly across Technology (34.00%), Office Supplies (33.32%) and Furniture (32.68%), similar to the other regions. Its Technology margin of 19.77% is the highest of any region. However, it earns only 5.32% on Office Supplies, compared with 15.91–23.82% elsewhere, and loses $2,871.05 on Furniture. If Central's Office Supplies earned the same margin as the other three regions combined (20.58%), its profit would be about $25,500 higher, enough to move it ahead of South.

**Furniture is the least profitable category in every region.** It earns a 2.49% margin company-wide, compared with 17.40% for Technology and 17.04% for Office Supplies. Furniture brings in 32.30% of revenue but only 6.44% of profit, while Technology alone generates 50.79% of profit.

*Note: the dataset contains no regional targets, so regions are compared with each other rather than with a target. The discount pattern is a correlation, not proof of cause. Discount is weighted by sales, so larger orders count more. Average discount by category was not checked, so it is not yet known whether discounting or pricing explains Central's low Office Supplies margin.*

### 5. Average Order Value by Customer Segment
*SQL: [`sql/08_aov_by_segment.sql`](sql/08_aov_by_segment.sql)*

| Segment | Avg Order Value | Orders | Share of Orders |
|---|---|---|---|
| Home Office | $472.67 | 909 | 18.15% |
| Corporate | $466.41 | 1,514 | 30.23% |
| Consumer | $449.11 | 2,586 | 51.63% |

**Order value is consistent across segments.** Home Office has the highest average order value ($472.67) and Consumer the lowest ($449.11). The gap is only $23.56, or 5.25%. All three segments are within $15 of the company-wide average of $458.61, so customer segment has little effect on how much is spent per order.

**Segments differ in volume, not order size.** Consumer places 51.63% of all orders, more than Corporate and Home Office combined (2,423). Home Office places the fewest orders (18.15%) despite having the highest average order value. Because order values are so similar, each segment's revenue depends mainly on how many orders it places. Growing a segment means winning more orders rather than larger ones.

*Note: average order value is total sales per order, averaged across orders, and covers revenue only, not profit. An average can be pulled up by a few very large orders (see the top customers in Finding 2), so a median would be a useful check. Order counts total 5,009, matching the order total in Finding 4.*

---

## Recommendations
**1. Fix margins on Office Supplies and Furniture in Central rather than discounting further.** Central gives the highest average discount (15.52%) and earns the lowest profit per order ($33.79). Its product mix is not the cause; its margins are. Central earns 19.77% on Technology, the highest of any region, but only 5.32% on Office Supplies, compared with 15.91–23.82% elsewhere, and it loses money on Furniture (-1.75%). Bringing Office Supplies in line with the other regions would add about $25,500 in profit. The business should review discounts and pricing on Office Supplies and Furniture in Central first. More broadly, Furniture earns only 2.49% company-wide, so it should not be a growth focus until its pricing and discounting are reviewed.

**2. Grow Technology sales by pairing it with high-volume categories.** Technology brings in $452.71 per line item, compared with $119.32 for Office Supplies, but appears on only 18.48% of line items. Office Supplies appears on 60.30%, so customers are already buying from the company often. Bundles or product suggestions that add Technology to these regular purchases could raise revenue per order without broad discounts that cut into profit. Technology also has the highest profit margin of the three categories (17.40%, compared with 17.04% for Office Supplies and 2.49% for Furniture), so growing it adds profit as well as revenue.

**3. Plan promotions and reporting around the seasonal cycle.** September, November and December are the highest-revenue months every year, while January and February are always the lowest. Promotions are more likely to add new orders in the January–February low than in peak months, when customers are already buying. Because segments spend similar amounts per order (Finding 5), growth depends mainly on winning more orders, which makes the slow months the best time to target. The weekly report should compare each period with the same period last year, so seasonal swings are not mistaken for growth or decline.

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
│   ├── 07_regional_performance.sql      # Q4: Regional performance and profit margin by category
│   └── 08_aov_by_segment.sql            # Q5: Average order value by segment
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