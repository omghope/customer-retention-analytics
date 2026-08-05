/*
===============================================================================
Project : Customer Churn Analytics Platform
File    : 01_database_setup.sql
Author  : Om Ghope
Date    : 02-Aug-2026

Purpose:
Creates the database objects required for the Customer Churn Analytics project
and loads the analytical model from the raw staging data.

Workflow:
Raw CSV
    ↓
stg_customer_churn
    ↓
dim_customer
    ↓
fact_customer_churn

===============================================================================
*/

-- ============================================================================
-- STEP 1: CREATE STAGING TABLE
-- ============================================================================


CREATE TABLE stg_customer_churn (
    customerID TEXT,
    gender TEXT,
    SeniorCitizen INT,
    Partner TEXT,
    Dependents TEXT,
    tenure INT,
    PhoneService TEXT,
    MultipleLines TEXT,
    InternetService TEXT,
    OnlineSecurity TEXT,
    OnlineBackup TEXT,
    DeviceProtection TEXT,
    TechSupport TEXT,
    StreamingTV TEXT,
    StreamingMovies TEXT,
    Contract TEXT,
    PaperlessBilling TEXT,
    PaymentMethod TEXT,
    MonthlyCharges NUMERIC,
    TotalCharges TEXT,
    Churn TEXT
);
SELECT COUNT(*) FROM stg_customer_churn;
-- ============================================================================
-- STEP 2: DATA QUALITY CHECKS
-- ============================================================================
-- Review the imported dataset to verify the schema,
-- row count, and identify potential data quality issues.
SELECT * FROM stg_customer_churn
LIMIT 10; --(Data Inspection)
--Table Structure
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'stg_customer_churn'; --This shows postgres sql data types for every columns

SELECT COUNT(*) AS total_customers
FROM stg_customer_churn;

-- Check for blank values in TotalCharges before
-- converting the column to NUMERIC.
SELECT COUNT(*) FROM stg_customer_churn 
WHERE TRIM(TotalCharges)= '';


-- =====================================================
-- STEP 3: CREATE CUSTOMER DIMENSION
-- =====================================================
-- Dimension tables store descriptive attributes
-- that provide context for business analysis.
CREATE TABLE dim_customer(
	customer_id VARCHAR(20) PRIMARY KEY,
	gender VARCHAR(10) NOT NULL,
	senior_citizen BOOLEAN NOT NULL,
	partner BOOLEAN NOT NULL,
	dependents BOOLEAN NOT NULL
);
-- Load customer attributes into the dimension table.
-- Convert integer and Yes/No values into BOOLEAN.
INSERT INTO dim_customer(
	customer_id,
	gender,
	senior_citizen,
	partner,
	dependents
)
SELECT 
       customerID,
	   gender,
	   CASE
	       WHEN SeniorCitizen = 1 THEN TRUE
		   ELSE FALSE
	   END,
	   CASE
	       WHEN Partner = 'Yes' THEN TRUE
		   ELSE FALSE
	   END,
	   CASE
	       WHEN Dependents = 'Yes' THEN TRUE
		   ELSE FALSE
	   END 
FROM stg_customer_churn;

-- ============================================================================
-- STEP 4: LOAD CUSTOMER DIMENSION
-- ============================================================================
SELECT * FROM dim_customer LIMIT 10; -- Validation: Verify that data was loaded correctly.
SELECT COUNT(*) FROM dim_customer; -- Validation: Expected result = 7043 rows.

--- ============================================================================
-- STEP 5: CREATE FACT TABLE
-- ============================================================================
-- Fact tables store measurable business events
-- used for reporting and analytical queries.
CREATE TABLE fact_customer_churn (
    customer_id VARCHAR(20) PRIMARY KEY,
    tenure INT NOT NULL,
    contract VARCHAR(30) NOT NULL,
    monthly_charges NUMERIC(10,2) NOT NULL,
    total_charges NUMERIC(10,2),
    payment_method VARCHAR(50) NOT NULL,
    paperless_billing BOOLEAN NOT NULL,
    phone_service BOOLEAN NOT NULL,
    multiple_lines VARCHAR(30),
    internet_service VARCHAR(30),
    online_security VARCHAR(30),
    online_backup VARCHAR(30),
    device_protection VARCHAR(30),
    tech_support VARCHAR(30),
    streaming_tv VARCHAR(30),
    streaming_movies VARCHAR(30),
    churn BOOLEAN NOT NULL,

    CONSTRAINT fk_customer
        FOREIGN KEY (customer_id)
        REFERENCES dim_customer(customer_id)
);
SELECT * FROM fact_customer_churn;

INSERT INTO fact_customer_churn(
	customer_id,
	tenure,
    contract,
    monthly_charges,
    total_charges,
    payment_method,
    paperless_billing,
    phone_service,
    multiple_lines,
    internet_service,
    online_security,
    online_backup,
    device_protection,
    tech_support,
    streaming_tv,
    streaming_movies,
    churn
)
SELECT 
	customerID,
	tenure,
	Contract,
	MonthlyCharges,
    -- Convert blank values to NULL and safely cast the
    -- remaining values from TEXT to NUMERIC.
	CAST(NULLIF(TRIM(TotalCharges), '') AS NUMERIC), --TRIM (remove whitespaces), --NULLIF(convert empty strings into NULL), CAST(to safely convert rmaning values into a numeric datatype during ETL process)
	PaymentMethod,

	CASE
		WHEN PaperlessBilling = 'Yes' THEN TRUE
		ELSE FALSE
	END,
	CASE
		WHEN PhoneService = 'Yes' THEN TRUE
		ELSE FALSE
	END,

	MultipleLines,
	InternetService,
	OnlineSecurity,
	OnlineBackup,
	DeviceProtection,
	TechSupport,
	StreamingTV,
	StreamingMovies,

	CASE
		WHEN Churn = 'Yes' THEN TRUE
		ELSE FALSE
	END
FROM stg_customer_churn;
-- ============================================================================
-- STEP 6: LOAD FACT TABLE
-- ============================================================================
SELECT COUNT(*) FROM;  -- Validation, Expected result: 7043 rows
SELECT COUNT(*) FROM  
WHERE total_charges is NULL; -- Validation, Expected result: 11 NULL values

/*
===============================================================================

Day 1 Summary

✓ Created staging table
✓ Created customer dimension
✓ Created customer churn fact table
✓ Loaded 7043 customer records
✓ Converted Yes/No values to BOOLEAN
✓ Converted blank TotalCharges values to NULL

===============================================================================
*/