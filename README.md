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
- **Downloaded:** *[add date]*

---

## About the Data
Each row in the raw file represents a **line item**: one product within an order. An order with several products appears across several rows, so a row count is not an order count. This grain shapes several queries in the project, most notably average order value.

Each row also carries details about the order, the product, and the customer, which are repeated on every line. To remove that repetition and support multi-table joins, the data is split into four tables.

---

## Data Model

| Table | Type | Primary Key | Columns | Links To |
|---|---|---|---|---|
| `customers` | Dimension | Customer ID | Customer ID, Customer Name, Segment | — |
| `products` | Dimension | Product ID *(see Data Quality Notes)* | Product ID, Category, Sub-Category, Product Name | — |
| `orders` | Header | Order ID | Order ID, Customer ID, Order Date, Ship Date, Ship Mode, Country, City, State, Postal Code, Region | `customers` |
| `order_lines` | Fact | Row ID | Row ID, Order ID, Product ID, Sales, Quantity, Discount, Profit | `orders`, `products` |

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

-
-
-

---

## Key Findings

### 1. Revenue by Category and Sub-Category
*[Finding]*

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