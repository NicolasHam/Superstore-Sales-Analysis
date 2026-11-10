/* 04_revenue_by_category.sql
   Business question 1: What is the total revenue by product category and sub-category?
   Tables: order_lines, products (joined on product_key)
   Revenue = SUM(sales), where sales is the line-item amount after discount.
   Findings are summarized in the README under Key Findings. */

/* Findings:

   Categories:
     Top        -->     Technology          ($836,154.03, 36.40% of revenue)
     Bottom     -->     Office Supplies     ($719,047.03, 31.30%)

   Sub-categories:
     Top        -->     Phones              ($330,007.05, 14.37%)
     Bottom     -->     Fasteners           ($3,024.28, 0.13%) */


-- Query 1: What is each product category's total revenue and share of overall revenue?
-- Result: Technology leads with $836,154.03 (36.40%); Office Supplies is lowest at $719,047.03 (31.30%).
-- SUM(SUM(ol.sales)) OVER() is a window function over the grouped results, giving overall revenue so each category's share can be calculated.
SELECT
	p.category,
    ROUND(SUM(ol.sales), 2) AS total_revenue,
    ROUND(SUM(ol.sales) / SUM(SUM(ol.sales)) OVER() * 100, 2) AS revenue_percentage
FROM order_lines ol
JOIN products p
	ON ol.product_key = p.product_key
GROUP BY p.category
ORDER BY SUM(ol.sales) DESC
;

-- Query 2: What is each product sub-category's total revenue and share of overall revenue?
-- Result: Phones leads with $330,007.05 (14.37%); Fasteners is lowest at $3,024.28 (0.13%).
SELECT
	p.sub_category,
    ROUND(SUM(ol.sales), 2) AS total_revenue,
    ROUND(SUM(ol.sales) / SUM(SUM(ol.sales)) OVER() * 100, 2) AS revenue_percentage
FROM order_lines ol
JOIN products p
	ON ol.product_key = p.product_key
GROUP BY p.sub_category
ORDER BY SUM(ol.sales) DESC
;