/* 05_top_customers.sql
   Purpose: Ranks customers by lifetime sales and returns the top 10, with order count,
            average sales per order and share of total revenue.
   Tables:  order_lines, orders, customers
            (order_lines joined to orders on order_id; orders joined to customers on customer_id)
   Results: Documented in README.md under Q2.
*/

-- Query 1: Who are the top 10 customers by lifetime spend?
-- Result: #1 is Sean Miller with $25,043.05 across 5 orders ($5,008.61 per order, 1.09% of total revenue);
--         #10 is Christopher Conant with $12,129.07 (0.53%). The top 10 together account for 6.70% of revenue, so no single customer drives the business.
SELECT
	RANK () OVER (ORDER BY SUM(ol.sales) DESC) AS customer_rank,
	c.customer_name,
	ROUND(SUM(ol.sales), 2) AS total_sales,
	COUNT(DISTINCT o.order_id) AS order_count,
	ROUND(SUM(ol.sales) / COUNT(DISTINCT o.order_id), 2) AS average_sales_per_order,
	ROUND((SUM(ol.sales) / SUM(SUM(ol.sales)) OVER () * 100), 2) AS share_of_total_revenue
FROM order_lines ol
INNER JOIN orders o
	ON ol.order_id = o.order_id
INNER JOIN customers c
	ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY customer_rank
LIMIT 10;