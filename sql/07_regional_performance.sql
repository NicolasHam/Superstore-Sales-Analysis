/* 07_regional_performance.sql
   Purpose: Compares regions on profit, order volume, profit per order and sales-weighted discount to find the weakest performers,
            then breaks regional profit down by product category to find what drives the gap.
   Tables:  orders, order_lines, products
   Results: Documented in README.md, Q4.
*/

-- Query 1: Which regions earn the most and least profit, and how do they compare on profit per order and discount?

-- Result:  West earns the most ($108,418.45, 1,611 orders); Central earns the least ($39,706.36, 1,175 orders).
--          The gap comes from profit per order ($67.30 vs. $33.79), not volume: Central has more orders than South but less profit.
--          Profit per order falls as discount rises across all four regions (West 12.88% → Central 15.52%).
--          This is a correlation, not proof of cause. Central earns $23 less per order than South with a discount only 1 point higher,
--          so discount alone does not explain the gap. Query 2 looks for the other cause.

-- CTE: one row per order with its profit, sales and discounted sales.

WITH order_value AS (
    SELECT
        o.order_id,
        o.region,
        SUM(ol.profit) AS order_profit,
        SUM(ol.sales) AS order_sales,
        SUM(ol.sales * ol.discount) AS discount_sales
    FROM orders o
    INNER JOIN order_lines ol
        ON o.order_id = ol.order_id
    GROUP BY o.order_id, o.region
)

SELECT
    region,
    ROUND(SUM(order_profit), 2) AS total_profit,
    ROUND(SUM(order_profit) / SUM(SUM(order_profit)) OVER() * 100, 2) AS profit_share_pct,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100, 2) AS order_share_pct,
    ROUND(AVG(order_profit), 2) AS profit_per_order,
    ROUND(SUM(discount_sales) / NULLIF(SUM(order_sales), 0) * 100, 2) AS avg_discount_pct
FROM order_value
GROUP BY region
ORDER BY SUM(order_profit) DESC;

-- Query 2: Does Central's profit gap come from what it sells (product mix) or how profitably it sells it (margins)?
-- Method:  One row per region and category, with revenue, profit and profit margin.
-- Result:  Margins, not mix. Central's revenue is split almost evenly across Technology, Office Supplies and Furniture, like the other regions.
--          Central has the highest Technology margin of any region (19.77%), but earns only 5.32% on Office Supplies
--          (15.91–23.82% elsewhere) and loses $2,871.05 on Furniture (-1.75%).
--          Furniture is the least profitable category in every region (1.46% to 5.77% outside Central).

SELECT
    o.region,
    p.category,
    ROUND(SUM(ol.sales), 2) AS revenue,
    ROUND(SUM(ol.profit), 2) AS profit,
    ROUND(SUM(ol.profit) / SUM(ol.sales) * 100, 2) AS profit_margin_pct
FROM order_lines ol
INNER JOIN orders o
    ON ol.order_id = o.order_id
INNER JOIN products p
    ON ol.product_key = p.product_key
GROUP BY o.region, p.category
ORDER BY o.region, profit DESC;