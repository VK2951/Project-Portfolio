/* Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region */

SELECT DISTINCT
    market
FROM
    dim_customer
WHERE
    customer = 'Atliq Exclusive'
        AND region = 'APAC';

/* What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, 
unique_products_2020, unique_products_2021, percentage_chg */

WITH ProductCounts AS (
	SELECT 
		YEAR(date) as sale_year,
        COUNT(DISTINCT product_code) as unique_product_count
	FROM fact_sales_monthly 
    WHERE YEAR(date) in (2020,2021)
    GROUP BY YEAR(date)  
)
SELECT
pc_20.unique_product_count as unique_products_2020,
pc_21.unique_product_count as unique_products_2021,
ROUND(((pc_21.unique_product_count - pc_20.unique_product_count) / NULLIF(pc_20.unique_product_count, 0) * 100), 2) 
									AS percentage_chg
FROM 
	(SELECT unique_product_count FROM ProductCounts WHERE sale_year = 2020) pc_20
CROSS JOIN 
	(SELECT unique_product_count FROM ProductCounts WHERE sale_year = 2021) pc_21 ;

/* Provide a report with all the unique product counts for each segment and sort them in descending order of 
product counts. The final output contains 2 fields, segment, product_count */

SELECT 
    segment, COUNT(DISTINCT product_code) AS product_count
FROM
    dim_product
GROUP BY segment
ORDER BY product_count DESC;

/* Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output
 contains these fields, segment, product_count_2020, product_count_2021, difference */

WITH cte1 AS (
	SELECT 
		d.segment, 
        COUNT(DISTINCT CASE WHEN f.fiscal_year = 2020 THEN f.product_code END) AS product_count_2020,
        COUNT(DISTINCT CASE WHEN f.fiscal_year = 2021 THEN f.product_code END) AS product_count_2021
	FROM fact_sales_monthly f
    JOIN dim_product d 
    ON d.product_code = f.product_code
    GROUP BY d.segment	
)
SELECT 
    segment,
    product_count_2020,
    product_count_2021,
    (product_count_2021 - product_count_2020) AS difference
FROM cte1
ORDER BY difference DESC ;

/* Get the products that have the highest and lowest manufacturing costs. The final output should contain
 these fields, product_code, product, manufacturing_cost */

SELECT 
    p.product_code, p.product, m.manufacturing_cost
FROM
    dim_product p
        JOIN
    fact_manufacturing_cost m ON m.product_code = p.product_code
WHERE
    m.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
											OR 
	m.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost) ;

/* Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct 
for the fiscal year 2021 and in the Indian market. The final output contains these fields, 
customer_code, customer, average_discount_percentage */

SELECT 
    f.customer_code,
    c.customer,
    ROUND(AVG(pre_invoice_discount_pct), 3) AS average_discount_percentage
FROM
    fact_pre_invoice_deductions f
        JOIN
    dim_customer c ON c.customer_code = f.customer_code
WHERE
    f.fiscal_year = 2021
        AND c.market = 'India'
GROUP BY f.customer_code , c.customer
ORDER BY average_discount_percentage DESC
LIMIT 5;

/* Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
The final report contains these columns: Month, Year, Gross sales Amount */

SELECT 
    MONTHNAME(f.date) AS Month,
    YEAR(f.date) AS Year,
    ROUND(SUM((g.gross_price * f.sold_quantity)),2) AS Gross_sales_Amount
FROM
    fact_sales_monthly f
        JOIN
    dim_customer c ON c.customer_code = f.customer_code
        JOIN
    fact_gross_price g ON g.product_code = f.product_code
WHERE
    c.customer = "Atliq Exclusive"
GROUP BY Month , Year
ORDER BY Year ;

/* In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields 
sorted by the total_sold_quantity, Quarter, total_sold_quantity */

WITH MonthlyQuarters AS (
	SELECT 
		CASE
        WHEN MONTH(date) IN (9,10,11) THEN 'Q1'
		WHEN MONTH(date) IN (12,1,2) THEN 'Q2'
		WHEN MONTH(date) IN (3,14,5) THEN 'Q3'
		WHEN MONTH(date) IN (6,7,8) THEN 'Q4'
        END as Quarter, 
        SUM(sold_quantity) as total_sold_quantity
	FROM fact_sales_monthly
    WHERE fiscal_year = 2020 AND
    CASE
        WHEN MONTH(date) IN (9,10,11) THEN 'Q1'
		WHEN MONTH(date) IN (12,1,2) THEN 'Q2'
		WHEN MONTH(date) IN (3,14,5) THEN 'Q3'
		WHEN MONTH(date) IN (6,7,8) THEN 'Q4'
        END IS NOT NULL
    GROUP BY Quarter
    
)
SELECT Quarter, total_sold_quantity
FROM MonthlyQuarters
ORDER BY total_sold_quantity DESC ;

/* Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
The final output contains these fields, channel, gross_sales_mln, percentage */

WITH SalesData AS (
	SELECT 
    c.channel,
    ROUND(SUM(g.gross_price * s.sold_quantity) / 1000000,2) AS gross_sales_mln
FROM
    fact_sales_monthly s
        JOIN
    fact_gross_price g ON g.product_code = s.product_code
        JOIN
    dim_customer c ON c.customer_code = s.customer_code
WHERE
    s.fiscal_year = 2021
GROUP BY c.channel
),
TotalSales AS (
	SELECT SUM(gross_sales_mln) as total_gross_sales_mln
    FROM SalesData
)
SELECT sd.channel, sd.gross_sales_mln, ROUND((sd.gross_sales_mln/t.total_gross_sales_mln)*100,2) as percentage
FROM SalesData sd
CROSS JOIN TotalSales t
ORDER BY sd.gross_sales_mln DESC ;
 