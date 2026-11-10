/* 04_revenue_by_category.sql
   Q1: What is the total revenue by product category and sub-category?
   Tables: order_lines, products (joined on product_key)
   Revenue = SUM(sales), after discount. Interpretation in README, Key Findings Q1. */

/* Findings:
   Top category         Technology       $836,154.03 (36.40%)
   Bottom category      Office Supplies  $719,047.03 (31.30%)
   Top sub-category     Phones           $330,007.05 (14.37%)
   Bottom sub-category  Fasteners        $3,024.28   (0.13%)

   Volume vs. value: Technology earns the most revenue from the fewest line items
   (18.48%, avg $452.71); Office Supplies relies on volume (60.30%, avg $119.32). */


-- Query 1: Revenue, line items, and average revenue per line item by category
-- Result: Technology leads ($836,154.03, 36.40%) from 18.48% of line items;
-- Office Supplies is lowest ($719,047.03, 31.30%) despite 60.30% of line items.
-- SUM(...) OVER() gives the overall total, used to calculate each share.
SELECT
	p.category,
  ROUND(SUM(ol.sales), 2) AS total_revenue,
  ROUND(SUM(ol.sales) / SUM(SUM(ol.sales)) OVER() * 100, 2) AS revenue_percentage,
  ROUND(AVG(ol.sales), 2) AS average_revenue_per_order_line,
  COUNT(*) AS total_order_lines,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100, 2) AS order_line_percentage
FROM order_lines ol
JOIN products p
	ON ol.product_key = p.product_key
GROUP BY p.category
ORDER BY SUM(ol.sales) DESC
;

-- Query 2: Revenue, line items, and average revenue per line item by sub-category
-- Result: Phones leads ($330,007.05, 14.37%) from 8.90% of line items;
-- Fasteners is lowest ($3,024.28, 0.13%) from 2.17% of line items.
SELECT
	p.sub_category,
  ROUND(SUM(ol.sales), 2) AS total_revenue,
  ROUND(SUM(ol.sales) / SUM(SUM(ol.sales)) OVER() * 100, 2) AS revenue_percentage,
  ROUND(AVG(ol.sales), 2) AS average_revenue_per_order_line,
  COUNT(*) AS total_order_lines,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100, 2) AS order_line_percentage
FROM order_lines ol
JOIN products p
	ON ol.product_key = p.product_key
GROUP BY p.sub_category
ORDER BY SUM(ol.sales) DESC
;