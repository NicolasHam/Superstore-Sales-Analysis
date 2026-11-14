/* 08_aov_by_segment.sql
   Purpose: Calculates the average order value (AOV) and the number of orders for each customer segment.
   Tables:  orders + customers (joined on customer_id) + order_lines(joined on order_id)
   Results: Documented in README.md, Q5.
*/

-- Query 1: Which customer segment has the highest average order value, and which has the lowest?
-- Method: The CTE adds up sales for each order and attaches the customer's segment. The outer query averages those order totals and counts orders by segment.
-- Result: Home Office has the highest at $472.67 (909 orders). Corporate is next at $466.41 (1,514 orders). Consumer has the lowest at $449.11 (2,586 orders).
--         The gap between highest and lowest is about $24 (roughly 5%), so segment has little effect on order value.
--         Consumer places just over half of all orders (2,586 of 5,009) despite having the lowest AOV.
WITH order_values AS (
    SELECT
        o.order_id,
        c.segment,
        SUM(ol.sales) AS order_value
    FROM orders o
    INNER JOIN customers c
        ON o.customer_id = c.customer_id
    INNER JOIN order_lines ol
        ON o.order_id = ol.order_id
    GROUP BY o.order_id, c.segment
)

SELECT
    segment,
    ROUND(AVG(order_value), 2) AS avg_order_value,
    COUNT(*) AS order_count
FROM order_values
GROUP BY segment
ORDER BY avg_order_value DESC;