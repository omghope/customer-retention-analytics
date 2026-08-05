/*
=============================================================
Project : Customer Churn Analytics Platform
File    : 02_advanced_sql_analysis.sql

Purpose:
Perform advanced SQL analysis using the analytical data model.

Author : Om Ghope
=============================================================
*/



--========================================================
--KPI 1: Total Customers
--========================================================
SELECT COUNT(*) AS total_customers
FROM fact_customer_churn;

--========================================================
--KPI 2: Total Churned Customers
--========================================================
SELECT COUNT(*) AS churned_customers
FROM fact_customer_churn 
WHERE churn =TRUE; 

--========================================================
--KPI 3: Active Customers
--========================================================
SELECT COUNT(*) AS active_customers
FROM fact_customer_churn
WHERE churn=FALSE;

--========================================================
--KPI 4: Churn Rate
--========================================================
SELECT
	ROUND(
		--Here 100.0 forces decial arithematic, giving an accurate percentage
		100.0* SUM(CASE WHEN churn THEN 1 ELSE 0 END)
		/COUNT(*),
		2
	) AS churn_rate_percent
FROM fact_customer_churn;  

--========================================================
--KPI 5: Average Monthly Charges
--========================================================
SELECT
	ROUND(AVG(monthly_charges), 2)AS average_monthly_charge
FROM fact_customer_churn;

--========================================================
--KPI 6: Average Customer Tenure
--========================================================
SELECT
	ROUND(AVG(tenure), 2) AS average_tenure
FROM fact_customer_churn;

--========================================================
--KPI 7: Total Revenue
--========================================================
SELECT
	ROUND(SUM(total_charges), 2) AS total_revenue
FROM fact_customer_churn;
--========================================================
--BUSINESS QUESTION:
-- Which contract type has the higesh churn rate?
--========================================================
SELECT
	contract,
	COUNT(*) AS total_customrs,

	SUM(
		CASE
			WHEN churn THEN 1
			ELSE 0
		END
	) AS churned_customers,

	ROUND(
		100.0 * SUM(CASE WHEN churn THEN 1 ELSE 0 END)
		/ COUNT(*),
		2
	) AS churn_rate_percent
FROM fact_customer_churn
GROUP BY contract
ORDER BY churn_rate_percent DESC;

--========================================================
-- BUSINESS QUESTION:
-- Which Payment method has the highest churn rate?
--Demonstrartion of a Common Table Expression (CTE)
--========================================================
SELECT
	payment_method,
	COUNT(*) AS total_customers,

	SUM(
		CASE
			WHEN churn THEN 1
			ELSE 0
		END
	) AS churned_customers,

	ROUND(
		100.0 * SUM(CASE WHEN churn THEN 1 ELSE 0 END)
		/ COUNT(*),
		2
	) AS churn_rate_percent
FROM fact_customer_churn
GROUP BY payment_method
ORDER BY churn_rate_percent DESC;

--========================================================
--BUSINESS QUESTION 
--WHich contract types have a churn rate greater than 25%
--========================================================
WITH contract_churn AS (
	SELECT
		contract,

		COUNT(*) AS total_customers,

		SUM(
			CASE
				WHEN churn THEN 1
				ELSE 0
			END
		) AS churned_customers,

		ROUND(
			100.0* SUM(CASE WHEN churn THEN 1 ELSE 0 END)
			/ COUNT(*),
			2
		) AS churn_rate

	FROM fact_customer_churn
	GROUP BY contract
)
SELECT * FROM contract_churn
WHERE churn_rate > 25;

-- ============================================================================
-- Business Question:
-- Who are the top-paying customers?
-- Demonstration of ROW_NUMBER()
-- ============================================================================
SELECT
	customer_id,
	total_charges,

	ROW_NUMBER() OVER (
		ORDER BY total_charges DESC
	) AS customer_rank
FROM fact_customer_churn
WHERE total_charges IS NOT NULL;

-- ============================================================================
-- Business Question:
-- Rank customers based on total charges.
-- Demonstration of RANK()
-- ============================================================================
SELECT 
	customer_id,
	total_charges,
	ROW_NUMBER() OVER(
		ORDER BY total_charges DESC
	) AS row_num,

	RANK() OVER(
		ORDER BY total_charges DESC
	) AS dense_rank_num

FROM fact_customer_churn

WHERE total_charges = (
	SELECT total_charges
	FROM fact_customer_churn
	WHERE total_charges IS NOT NULL
	GROUP BY total_charges
	HAVING COUNT(*) > 1
	LIMIT 1
);

-- ============================================================================
-- Business Question:
-- Which Internet Service type has the highest churn rate?
-- ============================================================================
SELECT 
	internet_service,

	COUNT(*) AS total_customers,

	SUM(
		CASE
			WHEN churn THEN 1
			ELSE 0
		END
	) AS churned_customers,

	ROUND(
		100.0* SUM(CASE WHEN churn THEN 1 ELSE 0 END)
		/ COUNT(*),
		2
	) AS churn_rate_percent

FROM fact_customer_churn
GROUP BY internet_service
ORDER BY churn_rate_percent DESC;

-- ============================================================================
-- Business Question:
-- Are senior citizens more likely to churn?
-- ============================================================================
SELECT
    senior_citizen,

    COUNT(*) AS total_customers,

    SUM(
        CASE
            WHEN churn THEN 1
            ELSE 0
        END
    ) AS churned_customers,

    ROUND(
        100.0 *
        SUM(CASE WHEN churn THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS churn_rate_percent

FROM fact_customer_churn f

JOIN dim_customer d
ON f.customer_id = d.customer_id

GROUP BY senior_citizen

ORDER BY churn_rate_percent DESC;

-- ============================================================================
-- Business Question:
-- Does gender influence customer churn?
-- ============================================================================
SELECT
    gender,

    COUNT(*) AS total_customers,

    SUM(
        CASE
            WHEN churn THEN 1
            ELSE 0
        END
    ) AS churned_customers,

    ROUND(
        100.0 *
        SUM(CASE WHEN churn THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS churn_rate_percent

FROM fact_customer_churn f

JOIN dim_customer d
ON f.customer_id = d.customer_id

GROUP BY gender

ORDER BY churn_rate_percent DESC;

-- ============================================================================
-- Business Question:
-- Does paperless billing affect churn?
-- ============================================================================

SELECT
    paperless_billing,

    COUNT(*) AS total_customers,

    SUM(
        CASE
            WHEN churn THEN 1
            ELSE 0
        END
    ) AS churned_customers,

    ROUND(
        100.0 *
        SUM(CASE WHEN churn THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS churn_rate_percent

FROM fact_customer_churn

GROUP BY paperless_billing

ORDER BY churn_rate_percent DESC;

-- ============================================================================
-- Business Question:
-- Identify the Top 10 highest-value customers.
-- Demonstration of CTE + ROW_NUMBER()
-- ============================================================================

WITH customer_ranking AS (

    SELECT
        customer_id,
        total_charges,

        ROW_NUMBER() OVER (
            ORDER BY total_charges DESC
        ) AS customer_rank

    FROM fact_customer_churn

    WHERE total_charges IS NOT NULL

)

SELECT
    customer_id,
    total_charges,
    customer_rank

FROM customer_ranking

WHERE customer_rank <= 10

ORDER BY customer_rank;

-- ============================================================================
-- Business Question:
-- Identify the Top 10 highest-value customers.
-- Demonstration of CTE + ROW_NUMBER()
-- ============================================================================

WITH customer_ranking AS (

    SELECT
        customer_id,
        total_charges,

        ROW_NUMBER() OVER (
            ORDER BY total_charges DESC
        ) AS customer_rank

    FROM fact_customer_churn

    WHERE total_charges IS NOT NULL

)

SELECT
    customer_id,
    total_charges,
    customer_rank

FROM customer_ranking

WHERE customer_rank <= 10

ORDER BY customer_rank;

-- ============================================================================
-- Business Question:
-- Rank customers based on lifetime revenue.
-- Demonstration of RANK()
-- ============================================================================

SELECT
    customer_id,
    total_charges,

    RANK() OVER (
        ORDER BY total_charges DESC
    ) AS revenue_rank

FROM fact_customer_churn

WHERE total_charges IS NOT NULL;

-- ============================================================================
-- Business Question:
-- Segment customers into revenue quartiles.
-- Demonstration of NTILE()
-- ============================================================================

SELECT
    customer_id,
    total_charges,

    NTILE(4) OVER (
        ORDER BY total_charges DESC
    ) AS revenue_quartile

FROM fact_customer_churn

WHERE total_charges IS NOT NULL;

-- ============================================================================
-- Business Question:
-- Identify customers paying above the company average.
-- Demonstration of AVG() OVER()
-- ============================================================================

WITH customer_average AS (

    SELECT
        customer_id,
        total_charges,

        AVG(total_charges) OVER () AS company_average

    FROM fact_customer_churn

    WHERE total_charges IS NOT NULL

)

SELECT
    customer_id,
    total_charges,
    company_average

FROM customer_average

WHERE total_charges > company_average

ORDER BY total_charges DESC;

-- ============================================================================
-- Business Question:
-- Identify the Top 10 highest-value customers who have churned.
-- Combines filtering, ranking and business prioritization.
-- ============================================================================

WITH churned_customers AS (

    SELECT
        customer_id,
        total_charges,

        RANK() OVER (
            ORDER BY total_charges DESC
        ) AS revenue_rank

    FROM fact_customer_churn

    WHERE churn = TRUE
      AND total_charges IS NOT NULL

)

SELECT
    customer_id,
    total_charges,
    revenue_rank

FROM churned_customers

WHERE revenue_rank <= 10

ORDER BY revenue_rank;

