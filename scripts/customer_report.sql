/*
===========================================================================================================================
Customer Report
===========================================================================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights : 
    1. Gather essential fields such as names, ages, and transaction details.
    2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
       - total orders
       - total sales
       - total quantity purchases
       - total products
       - lifespan (in months)
    4. Calculates valueable KPIs:
       - recency (months since last order)
       - average order value
       - average monthly spend
===========================================================================================================================
*/
CREATE VIEW gold.report_customers AS 
WITH base_query as (
/* ------------------------------------------------------------------------------------------------------------------------
1) Base query : Retrives core columns from tables
--------------------------------------------------------------------------------------------------------------------------*/

SELECT
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name, ' ', c.last_name ) as customer_name,
DATEDIFF(year, c.birthdate, GETDATE()) age 
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
WHERE order_date IS NOT NULL
)
, customer_aggregations as (
/* ------------------------------------------------------------------------------------------------------------------------
2) Customer Aggregations : Summarizes key matrics at the customer level
--------------------------------------------------------------------------------------------------------------------------*/

SELECT 
customer_key,
customer_number,
customer_name,
age ,
COUNT(DISTINCT order_number) as total_orders,
SUM(sales_amount) as total_sales,
SUM(quantity) as total_quantity,
COUNT(DISTINCT product_key) as total_products,
MAX(order_date) as last_order_date,
DATEDIFF(MONTH, MIN(order_date), mAX(order_date)) as lifespan
FROM base_query
GROUP BY 
    customer_key,
    customer_number,
    customer_name,
    age
)

SELECT 
customer_key,
customer_number,
customer_name,
age,
CASE WHEN age < 20 THEN 'Under 20'
     WHEN age BETWEEN 20 AND 29 THEN '20-29'
     WHEN age BETWEEN 30 AND 39 THEN '30-39'
     WHEN age BETWEEN 40 AND 49 THEN '40-49'
     ELSE '50 and above'
END as age_group,
CASE WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
	 WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
	 ELSE 'New'
END customer_segment,
last_order_date,
DATEDIFF(month, last_order_date, GETDATE()) as recency,
total_orders,
total_sales,
total_quantity,
total_products,
lifespan,
-- compute average order value (AVO)
CASE WHEN total_orders = 0 THEN 0
    ELSE total_sales / total_orders 
END as avg_order_value
,
-- compute avg monthly spend (total sales/no of months)
CASE WHEN lifespan = 0 THEN total_sales
    ELSE total_sales / lifespan 
END as avg_monthly_spend
FROM customer_aggregations


