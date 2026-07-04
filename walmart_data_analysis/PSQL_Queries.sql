/* =========================================================
   Walmart Project SQL Queries
   ========================================================= */

-- =========================================================
-- BASIC EXPLORATION
-- =========================================================

-- View all data
SELECT * FROM walmart;

-- DROP TABLE walmart;  -- (use only if needed)

-- Count total records
SELECT COUNT(*) FROM walmart;

-- Count transactions by payment method
SELECT
    payment_method,
    COUNT(*) AS no_transactions
FROM walmart
GROUP BY payment_method;

-- Count distinct branches
SELECT COUNT(DISTINCT branch) FROM walmart;

-- Minimum quantity sold
SELECT MIN(quantity) FROM walmart;


-- =========================================================
-- BUSINESS PROBLEMS
-- =========================================================

-- Q1: Payment method-wise transactions and quantity sold
SELECT
    payment_method,
    COUNT(*) AS no_payments,
    SUM(quantity) AS total_qty_sold
FROM walmart
GROUP BY payment_method;


-- =========================================================
-- Q2: Highest-rated category in each branch
-- =========================================================

SELECT *
FROM (
    SELECT
        branch,
        category,
        AVG(rating) AS avg_rating,
        RANK() OVER (PARTITION BY branch ORDER BY AVG(rating) DESC) AS rnk
    FROM walmart
    GROUP BY branch, category
) t
WHERE rnk = 1;


-- =========================================================
-- Q3: Busiest day for each branch (by transactions)
-- =========================================================

SELECT *
FROM (
    SELECT
        branch,
        TO_CHAR(TO_DATE(date, 'DD/MM/YY'), 'Day') AS day_name,
        COUNT(*) AS no_transactions,
        RANK() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS rnk
    FROM walmart
    GROUP BY branch, day_name
) t
WHERE rnk = 1;


-- =========================================================
-- Q4: Total quantity sold per payment method
-- =========================================================

SELECT
    payment_method,
    SUM(quantity) AS total_qty_sold
FROM walmart
GROUP BY payment_method;


-- =========================================================
-- Q5: Rating stats per city & category
-- =========================================================

SELECT
    city,
    category,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating,
    AVG(rating) AS avg_rating
FROM walmart
GROUP BY city, category;


-- =========================================================
-- Q6: Total revenue and profit per category
-- =========================================================

SELECT
    category,
    SUM(total) AS total_revenue,
    SUM(total * profit_margin) AS total_profit
FROM walmart
GROUP BY category
ORDER BY total_profit DESC;


-- =========================================================
-- Q7: Most common payment method per branch
-- =========================================================

WITH payment_rank AS (
    SELECT
        branch,
        payment_method,
        COUNT(*) AS total_transactions,
        RANK() OVER (
            PARTITION BY branch
            ORDER BY COUNT(*) DESC
        ) AS rnk
    FROM walmart
    GROUP BY branch, payment_method
)
SELECT
    branch,
    payment_method AS preferred_payment_method
FROM payment_rank
WHERE rnk = 1;


-- =========================================================
-- Q8: Sales distribution by time of day
-- =========================================================

SELECT
    branch,
    CASE
        WHEN EXTRACT(HOUR FROM (time::time)) < 12 THEN 'Morning'
        WHEN EXTRACT(HOUR FROM (time::time)) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS day_time,
    COUNT(*) AS total_invoices
FROM walmart
GROUP BY branch, day_time
ORDER BY branch, total_invoices DESC;


-- =========================================================
-- Q9: Top 5 branches with highest revenue decrease (2023 vs 2022)
-- =========================================================

WITH revenue_2022 AS (
    SELECT
        branch,
        SUM(total) AS revenue
    FROM walmart
    WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2022
    GROUP BY branch
),
revenue_2023 AS (
    SELECT
        branch,
        SUM(total) AS revenue
    FROM walmart
    WHERE EXTRACT(YEAR FROM TO_DATE(date, 'DD/MM/YY')) = 2023
    GROUP BY branch
)
SELECT
    r22.branch,
    r22.revenue AS last_year_revenue,
    r23.revenue AS current_year_revenue,
    ROUND(
        (r22.revenue - r23.revenue)::numeric
        / r22.revenue::numeric * 100,
        2
    ) AS revenue_decrease_ratio
FROM revenue_2022 r22
JOIN revenue_2023 r23
    ON r22.branch = r23.branch
WHERE r22.revenue > r23.revenue
ORDER BY revenue_decrease_ratio DESC
LIMIT 5;
