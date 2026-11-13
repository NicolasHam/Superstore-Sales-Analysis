/* 06_monthly_revenue.sql
   Purpose: Compares monthly revenue with the previous month (Query 1) and with the same month
            of the previous year (Query 2). Each CTE uses LAG() to add the comparison month's total.
   Tables:  order_lines, orders (joined on order_id)
   Results: README.md, Q3.
*/

-- Query 1: Does revenue grow steadily from month to month?
-- Result: No. Revenue swings sharply (-75.25% to +1132.13%) and rose in only 21 of 47 months.
--         The same pattern repeats each year: January drops 55-75%, March rebounds 125-224%, and
--         September to December is the strongest period (peak: 118447.83 in November 2017).
-- Note: NULLIF prevents a division-by-zero error when the previous month's revenue is 0.

WITH monthly_revenue AS (
SELECT  
    EXTRACT(YEAR FROM o.order_date) AS year,
    EXTRACT(MONTH FROM o.order_date) AS month_num,
    TO_CHAR(o.order_date, 'FMMonth') AS month,
    ROUND(SUM(ol.sales), 2) AS total_revenue,
    NULLIF((LAG(SUM(ol.sales), 1) OVER (ORDER BY EXTRACT(YEAR FROM o.order_date), EXTRACT(MONTH FROM o.order_date))), 0) AS previous_month_revenue
FROM order_lines ol
INNER JOIN orders o
    ON ol.order_id = o.order_id
GROUP BY 1, 2, 3
)

SELECT
    year,
    month,
    total_revenue,
    ROUND(((total_revenue - previous_month_revenue) / previous_month_revenue * 100), 2) AS percentage_change
FROM monthly_revenue
ORDER BY year, month_num;


-- Query 2: Does revenue grow compared with the same month of the previous year?
-- Result: Yes, from 2016. 2015 was flat (6 of 12 months up; -2.8% for the year). 2016 rose in 11 of 12
--         months (+29.5%) and 2017 in 8 of 12 (+20.4%). Single months still vary (-30.46% to +164.42%).
--         The first 12 months are NULL (no prior year). Here, previous_month_revenue = same month last year.
WITH monthly_revenue AS (
SELECT  
    EXTRACT(YEAR FROM o.order_date) AS year,
    EXTRACT(MONTH FROM o.order_date) AS month_num,
    TO_CHAR(o.order_date, 'FMMonth') AS month,
    ROUND(SUM(ol.sales), 2) AS total_revenue,
    NULLIF((LAG(SUM(ol.sales), 12) OVER (ORDER BY EXTRACT(YEAR FROM o.order_date), EXTRACT(MONTH FROM o.order_date))), 0) AS previous_month_revenue
FROM order_lines ol
INNER JOIN orders o
    ON ol.order_id = o.order_id
GROUP BY 1, 2, 3
)

SELECT
    year,
    month,
    total_revenue,
    ROUND(((total_revenue - previous_month_revenue) / previous_month_revenue * 100), 2) AS percentage_change
FROM monthly_revenue
ORDER BY year, month_num;