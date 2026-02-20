CREATE DATABASE project2;
USE project2;
SELECT * FROM product_sales;

SELECT COUNT(*) FROM product_sales;

DESC product_sales;

SELECT * FROM product_sales LIMIT 10;
------------------------------------------------
#2. DATA VALIDATION AND CLEANING.

#  Convert Order_Date from TEXT → DATE
SET SQL_SAFE_UPDATES = 0;

UPDATE product_sales
SET Order_Date = STR_TO_DATE(Order_Date, '%m-%d-%y');

ALTER TABLE product_sales
MODIFY Order_Date DATE;

# Validate Revenue (Very Important for Marks)
# Even if revenue exists, we re-check it (industry practice)
SELECT *
FROM product_sales
WHERE Revenue != Quantity * Unit_Price;

# Check nulls and invalid data.
SELECT
    SUM(Order_ID IS NULL) AS null_orders,
    SUM(Order_Date IS NULL) AS null_dates,
    SUM(Quantity <= 0) AS invalid_quantity,
    SUM(Unit_Price <= 0) AS invalid_price
FROM product_sales;

# Since mismatches exist in revenue , you must correct them.
UPDATE product_sales
SET Revenue = Quantity * Unit_Price
WHERE Revenue != Quantity * Unit_Price;

# Recheck
SELECT COUNT(*)
FROM product_sales
WHERE Revenue != Quantity * Unit_Price;

----------------------------------------------------
#3.  Data Transformation 

SELECT COUNT(*) AS total_rows FROM product_sales;
SELECT * FROM product_sales LIMIT 5;              # just checked data is clean.

# CREATED BASE TRANSFORMATION VIEW
# We re-derive revenue (industry practice)

CREATE VIEW vw_sales_base AS
SELECT
    Order_ID,
    Order_Date,
    Customer_Name,
    City,
    State,
    Region,
    Country,
    Category,
    Sub_Category,
    Product_Name,
    Quantity,
    Unit_Price,
    Quantity * Unit_Price AS Revenue,
    Profit
FROM product_sales;

# ADD TIME-BASED DERIVED COLUMNS
CREATE VIEW vw_sales_trend AS
SELECT
    *,
    YEAR(Order_Date) AS sales_year,
    MONTH(Order_Date) AS sales_month,
    MONTHNAME(Order_Date) AS sales_month_name,
    QUARTER(Order_Date) AS sales_quarter,
    DAYNAME(Order_Date) AS sales_day
FROM vw_sales_base;

# CREATE LOCATION HIERARCHY VIEW (MODEL ENHANCEMENT)
CREATE VIEW vw_location_hierarchy AS
SELECT DISTINCT
    Country,
    Region,
    State,
    City
FROM product_sales;                   -- Clean location modeling in Power BI

# VALIDATE TRANSFORMED VIEWS
SELECT * FROM vw_sales_base LIMIT 5;

SELECT * FROM vw_sales_trend LIMIT 5;

SELECT * FROM vw_location_hierarchy LIMIT 5;

--------------------------------------------------------------------------------
#4. EXPLORATORY DATA ANALYSIS (EDA)
#Base View Used: vw_sales_trend
#(All queries will use this view)

#  Overall Business Performance
SELECT
    COUNT(DISTINCT Order_ID) AS total_orders,
    ROUND(SUM(Revenue), 2) AS total_revenue,
    ROUND(SUM(Profit), 2) AS total_profit
FROM vw_sales_trend;

# Revenue Performance by Region
SELECT
    Region,
    ROUND(SUM(Revenue), 2) AS total_revenue
FROM vw_sales_trend
GROUP BY Region
ORDER BY total_revenue DESC;

# Category-wise Revenue Contribution
SELECT
    Category,
    ROUND(SUM(Revenue), 2) AS total_revenue,
    ROUND(
        SUM(Revenue) * 100 / SUM(SUM(Revenue)) OVER (), 
        2
    ) AS revenue_percentage                             -- Percentage of total revenue contributed by each category.
FROM vw_sales_trend
GROUP BY Category
ORDER BY total_revenue DESC;

# Monthly Sales Trend
SELECT
    sales_year,
    sales_month,
    sales_month_name,
    ROUND(SUM(Revenue), 2) AS monthly_revenue
FROM vw_sales_trend
GROUP BY sales_year, sales_month, sales_month_name
ORDER BY sales_year, sales_month;

# Top 10 Products by Revenue
SELECT
    Product_Name,
    ROUND(SUM(Revenue), 2) AS total_revenue,
    RANK() OVER (ORDER BY SUM(Revenue) DESC) AS revenue_rank
FROM vw_sales_trend
GROUP BY Product_Name
ORDER BY revenue_rank
LIMIT 10;

# Category-wise Profit Margin Analysis
SELECT
    Category,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND(
        SUM(Profit) / SUM(Revenue) * 100,
        2
    ) AS profit_margin_percentage
FROM vw_sales_trend
GROUP BY Category
ORDER BY profit_margin_percentage DESC;

-------------------------------------------------------------------
# KPI Layer
# Total Orders

SELECT
    COUNT(DISTINCT Order_ID) AS total_orders
FROM vw_sales_trend;

# Total Revenue
SELECT
    ROUND(SUM(Revenue), 2) AS total_revenue
FROM vw_sales_trend;

# Total Profit
SELECT
    ROUND(SUM(Profit), 2) AS total_profit
FROM vw_sales_trend;

# Average Order Value (AOV)
SELECT
    ROUND(SUM(Revenue) / COUNT(DISTINCT Order_ID), 2) AS avg_order_value
FROM vw_sales_trend;

# Profit Margin %
SELECT
    ROUND(SUM(Profit) / SUM(Revenue) * 100, 2) AS profit_margin_percent
FROM vw_sales_trend;












