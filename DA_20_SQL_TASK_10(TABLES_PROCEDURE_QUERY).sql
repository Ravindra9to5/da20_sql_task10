------------------TASK-9----------------------------------
--CREARE REPORT ON THE BASIC OF ECOM DATABASE. 

--1.Create two new report tables : 
--a.monthly_sales_report for monthly aggregated data.
--b.yearly_sales_report for yearly aggregated data.

--Step 1: Create Report Tables basic from sales,customer and product table.

-- Monthly aggregated sales report table
CREATE TABLE monthly_sales_report(
    report_id   SERIAL PRIMARY KEY,
    report_year INTEGER NOT NULL,
    report_month INTEGER NOT NULL,
    cust_id VARCHAR NOT NULL,
    customer_name VARCHAR NOT NULL,
    product_id VARCHAR NOT NULL,
    product_name VARCHAR,
    total_sales_amount DOUBLE PRECISION,
    total_quantity_sold INTEGER,
    avg_discount DOUBLE PRECISION,
    total_profit DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT now()
    );
	

-- Yearly aggregated sales report table
CREATE TABLE yearly_sales_report
    (
    report_id SERIAL PRIMARY KEY,
    report_year INTEGER NOT NULL,
    cust_id VARCHAR NOT NULL,
    customer_name VARCHAR NOT NULL,
    product_id VARCHAR NOT NULL,
    product_name VARCHAR,
    total_sales_amount DOUBLE PRECISION,
    total_quantity_sold INTEGER,
    avg_discount DOUBLE PRECISION,
    total_profit DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT now()
    );

-----------------------------------------------------------------------------------------

--Step 2: Create Procedure to Generate Reports.

CREATE OR REPLACE PROCEDURE generate_monthly_yearly_sales_reports()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Clear previous report data
    TRUNCATE TABLE monthly_sales_report, public.yearly_sales_report;

    -- Insert Monthly Aggregated Data
    INSERT INTO monthly_sales_report (
        report_year,
        report_month,
        cust_id,
        customer_name,
        product_id,
        product_name,
        total_sales_amount,
        total_quantity_sold,
        avg_discount,
        total_profit
        )
    SELECT
        EXTRACT(YEAR FROM s.order_date)::INT AS report_year,
        EXTRACT(MONTH FROM s.order_date)::INT AS report_month,
        c.cust_id,
        c.customer_name,
        p.product_id,
        p.product_name,
        SUM(s.sales) AS total_sales_amount,
        SUM(s.qty) AS total_quantity_sold,
        AVG(s.discount) AS avg_discount,
        SUM(s.profit) AS total_profit
    FROM sales s
    INNER JOIN customer c ON s.cust_id = c.cust_id
    INNER JOIN product p ON s.product_id = p.product_id
    WHERE s.order_date IS NOT NULL
    GROUP BY report_year, report_month, c.cust_id, c.customer_name, p.product_id, p.product_name
    ORDER BY report_year, report_month;

    -- Insert Yearly Aggregated Data
    INSERT INTO yearly_sales_report (
        report_year,
        cust_id,
        customer_name,
        product_id,
        product_name,
        total_sales_amount,
        total_quantity_sold,
        avg_discount,
        total_profit
        )
    SELECT
        EXTRACT(YEAR FROM s.order_date)::INT AS report_year,
        c.cust_id,
        c.customer_name,
        p.product_id,
        p.product_name,
        SUM(s.sales) AS total_sales_amount,
        SUM(s.qty) AS total_quantity_sold,
        AVG(s.discount) AS avg_discount,
        SUM(s.profit) AS total_profit
    FROM sales s
    INNER JOIN customer c ON s.cust_id = c.cust_id
    INNER JOIN product p ON s.product_id = p.product_id
    WHERE s.order_date IS NOT NULL
    GROUP BY report_year, c.cust_id, c.customer_name, p.product_id, p.product_name
    ORDER BY report_year;
END;
$$;
--------------------------------------------------------------------------------------------
--call report for inserting data in the  table.
CALL generate_monthly_yearly_sales_reports() ;

--check data is insert or not.
select * from monthly_sales_report ;   -----9985 rows inserted.
select * from yearly_sales_report ;    -----9968 rows inserted.

--------------------------------------------------------------------------------------------
--Query the report tables : Monthly report example for year 2014 and month 5 (May)
SELECT * FROM monthly_sales_report
WHERE report_year = 2014 AND report_month = 5    
ORDER BY customer_name, product_name;           ----------122 record found
-------------------------------------------------------------------------------------------
--month wise sales report for 2014 year.
SELECT
  report_month,
  round(SUM(total_sales_amount)) AS total_sales,
  round(SUM(total_quantity_sold)) AS total_quantity,
  AVG(avg_discount) AS avg_discount,
  round(SUM(total_profit)) AS total_profit
FROM monthly_sales_report
WHERE report_year = 2014
GROUP BY report_month
ORDER BY report_month;
-------------------------------------------------------------------------------------------
--creating table for that report IN sales_report_2014_by_month table.

CREATE TABLE sales_report_2014_by_month AS
SELECT
  report_month,
  round(SUM(total_sales_amount)) AS total_sales,
  round(SUM(total_quantity_sold)) AS total_quantity,
  AVG(avg_discount) AS avg_discount,
  round(SUM(total_profit)) AS total_profit
FROM monthly_sales_report
WHERE report_year = 2014
GROUP BY report_month
ORDER BY report_month;

select * from sales_report_2014_by_month ;

--Yearly report example for year 2023 : yearly report of 2015
SELECT * FROM yearly_sales_report
WHERE report_year = 2015
ORDER BY customer_name, product_name;           ----------2098 record found
---------------------------------------------------------------------------------------
--select statement for year-based grouped summary
SELECT
    report_year,
    ROUND(SUM(total_sales_amount)) AS total_sales,
    SUM(total_quantity_sold) AS total_quantity,
    AVG(avg_discount) AS avg_discount,
    ROUND(SUM(total_profit)) AS total_profit
FROM yearly_sales_report
GROUP BY report_year
ORDER BY report_year;

--creating report summery report table 

CREATE TABLE every_yearly_sales_report  AS
SELECT
    report_year,
    ROUND(SUM(total_sales_amount)) AS total_sales,
    SUM(total_quantity_sold) AS total_quantity,
    AVG(avg_discount) AS avg_discount,
    ROUND(SUM(total_profit)) AS total_profit
FROM yearly_sales_report
GROUP BY report_year
ORDER BY report_year;


select * from every_yearly_sales_report ;

-------------------------------------------------------------------------------------------
--Create Monthly Profit Report Table from monthly_sales_report
CREATE TABLE  monthly_profit_report AS
SELECT
    report_year,
    report_month,
    cust_id,
    customer_name,
    SUM(total_profit) AS total_profit,
    CASE 
        WHEN SUM(total_quantity_sold) = 0 THEN 0
        ELSE SUM(total_profit) / SUM(total_quantity_sold)
    END AS avg_profit_per_sale,
    SUM(total_sales_amount) AS total_sales_amount,
    SUM(total_quantity_sold) AS total_quantity_sold
FROM monthly_sales_report
GROUP BY report_year, report_month, cust_id, customer_name
ORDER BY report_year, report_month, cust_id;

select * from monthly_profit_report;
---------------------------------------------------------------------------------------------
---shipmode month wise summery
SELECT
    s.ship_mode,
    SUM(s.sales) AS total_sales_amount,
    SUM(s.qty) AS total_quantity_sold,
    AVG(s.discount) AS avg_discount,
    SUM(s.profit) AS total_profit
FROM sales s
WHERE s.order_date IS NOT NULL
GROUP BY s.ship_mode
ORDER BY total_sales_amount DESC;

select * from sales
-----ship mode year wise year report 
SELECT
    EXTRACT(YEAR FROM s.order_date) AS sale_year,
    s.ship_mode,
    ROUND(SUM(s.sales)) AS total_sales_amount,
    SUM(s.qty) AS total_quantity_sold,
    ROUND(SUM(s.profit)) AS total_profit
FROM sales s
WHERE s.order_date IS NOT NULL
GROUP BY sale_year, s.ship_mode
ORDER BY sale_year, total_sales_amount DESC;

--Ship Mode Grouped by Month & Year
SELECT
    EXTRACT(YEAR FROM s.order_date) AS sale_year,
    EXTRACT(MONTH FROM s.order_date) AS sale_month,
    s.ship_mode,
    SUM(s.sales) AS total_sales_amount,
    SUM(s.qty) AS total_quantity_sold,
    SUM(s.profit) AS total_profit
FROM sales s
WHERE s.order_date IS NOT NULL
GROUP BY sale_year, sale_month, s.ship_mode
ORDER BY sale_year, sale_month, total_sales_amount DESC;


SELECT
    EXTRACT(YEAR FROM s.order_date) AS sale_year,
    EXTRACT(MONTH FROM s.order_date) AS sale_month,
    s.ship_mode,
    ROUND(SUM(s.sales)) AS total_sales_amount,
    SUM(s.qty) AS total_quantity_sold,
    ROUND(SUM(s.profit)) AS total_profit
FROM sales s
WHERE s.order_date IS NOT NULL
  AND EXTRACT(YEAR FROM s.order_date) = 2014
GROUP BY sale_year, sale_month, s.ship_mode
ORDER BY sale_month, total_sales_amount DESC;



------------------------------------------------------------------------
--Category-Wise Report by Ship Mode
--Since the ship mode is present in your sales table, an aggregate report for 
--categories by ship mode can be created combining product categories and sales' ship mode.
CREATE category_shipmode_report
(
    report_id SERIAL PRIMARY KEY,
    report_type VARCHAR(10) NOT NULL CHECK (report_type IN ('MONTHLY', 'YEARLY')),
    report_year INTEGER NOT NULL,
    report_month INTEGER,  -- NULL for yearly
    category VARCHAR NOT NULL,
    ship_mode VARCHAR,
    total_sales_amount DOUBLE PRECISION,
    total_quantity_sold INTEGER,
    total_profit DOUBLE PRECISION,
    created_at TIMESTAMP DEFAULT now()
);

select * 
from category_shipmode_report
--where report_year = 2014
group by ship_mode
order by report_year ;

-------------------------------------TASK COMPLETED------------------------------------





	
