
SELECT * FROM dim_campaigns ;

SELECT * FROM dim_products ;

SELECT * FROM dim_stores ;

SELECT * FROM fact_events ;

-- BUSINESS REQUESTS -----------

# 1. Provide a list of products with a base price greater than 500 and that are featured in promo type of 'BOGOF' (Buy One Get One Free) #

SELECT 
    DISTINCT p.product_name AS Product,
    f.base_price AS Base_Price,
    f.promo_type AS Promo_type
FROM
    dim_products p
        JOIN
    fact_events f ON p.product_code = f.product_code
WHERE
    f.base_price > 500
        AND f.promo_type = 'BOGOF'
ORDER BY base_price ASC ;

# 2. Generate a report that provides an overview of the number of stores in each city. #

SELECT 
    city AS City, COUNT(DISTINCT store_id) AS Store_Count
FROM
    dim_stores
GROUP BY city
ORDER BY Store_Count DESC;

# 3. Generate a report that displays each campaign along with the total revenue generated before and after the campaign? #

SELECT 
    c.campaign_name AS Campaign_Name,
    CONCAT(ROUND(SUM(f.base_price * f.quantity_sold_before_promo) / 1000000,2),' M') AS Total_Revenue_before_Campaign,
    CONCAT(ROUND(SUM(f.base_price * f.quantity_sold_after_promo) / 1000000,2),' M') AS Total_Revenue_after_Campaign
FROM
    dim_campaigns c
        JOIN
    fact_events f ON c.campaign_id = f.campaign_id
GROUP BY campaign_name 
ORDER BY campaign_name;

# 4. Produce a report that calculates the Incremental Sold Quantity (ISU%) for each category during the Diwali campaign # 
-- Additionally provide rankings for the categories based on their ISU% --

WITH category_isu_pct AS
	(SELECT 
		p.category AS Category,
		ROUND(((SUM(f.quantity_sold_after_promo) - SUM(f.quantity_sold_before_promo)) / SUM(f.quantity_sold_before_promo)) * 100,
				2) AS ISU_Percentage
	FROM
		dim_products p
			JOIN
		fact_events f USING (product_code)
	GROUP BY category)
SELECT *,
	DENSE_RANK () OVER(ORDER BY ISU_Percentage DESC ) as Rank_Order
FROM category_isu_pct ;

# 5. Create a report featuring the Top 5 products, ranked by Incremental Revenue Percentage (IR%), across all campaigns. #
 
 WITH product_ir_pct AS
	(SELECT 
		DISTINCT p.product_name AS Product,
		ROUND(((SUM(f.base_price*f.quantity_sold_after_promo) - SUM(f.base_price*f.quantity_sold_before_promo)) / SUM(f.base_price*f.quantity_sold_before_promo)) * 100,2) AS IR_Percentage
	FROM
		dim_products p
			JOIN
		fact_events f USING (product_code)
	GROUP BY product_name)
SELECT *,
	DENSE_RANK () OVER(ORDER BY IR_Percentage DESC ) as Rank_Order
FROM product_ir_pct
LIMIT 5 ;

    

 