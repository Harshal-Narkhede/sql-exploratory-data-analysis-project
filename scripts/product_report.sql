/*
===========================================================================================================================
Product Report
===========================================================================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights : 
    1. Gather essential fields such as product name,category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valueable KPIs:
       - recency (months since last sales)
       - average order renvue (AOR)
       - average monthly revenue
===========================================================================================================================
*/
CREATE VIEW gold.report_products as 
WITH base_query as (
/* ------------------------------------------------------------------------------------------------------------------------
1) Base query : Retrives core columns from fact_sales and dim_products
--------------------------------------------------------------------------------------------------------------------------*/
SELECT 
f.order_number,
f.order_date,
f.customer_key,
f.sales_amount,
f.quantity,
p.product_key,
p.product_name,
p.category,
p.subcategory,
p.cost

FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key = p.product_key
WHERE order_date IS NOT NULL -- only consider valid sales dates
)
, product_aggregations as (
/* ------------------------------------------------------------------------------------------------------------------------
2) Product Aggregations : Summarizes key matrics at the product level
--------------------------------------------------------------------------------------------------------------------------*/
SELECT 
product_key,
product_name,
category,
subcategory,
cost,
DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) as lifespan,
MAX(order_date) as last_sale_date,
COUNT(DISTINCT order_number) as total_orders,
COUNT(DISTINCT customer_key) as total_customers,
SUM(sales_amount) as total_sales,
SUM(quantity) as total_quantity,
-- avg_selling_price --> total sales amount / qty
ROUND(AVG(CAST(sales_amount as FLOAT)/ NULLIF(quantity, 0)), 1) as avg_selling_price
FROM base_query

GROUP BY
    product_key,
    product_name,
    category,
    subcategory,
    cost
)
/* ------------------------------------------------------------------------------------------------------------------------
3) Final Query : Combines all product results into one output
--------------------------------------------------------------------------------------------------------------------------*/
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_sale_date,
    DATEDIFF(MONTH, last_sale_date, GETDATE()) as recency_in_months,
    CASE    
        WHEN total_sales > 50000 THEN 'High-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Performer'
        ELSE 'Low-Performer'
    END as product_segment,
    lifespan,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,

    -- Average Order Revenue (AOR)
    CASE    
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_revenue,

    -- Average montly revenue
    CASE    
        WHEN lifespan = 0 THEN total_sales
        ELSE total_sales / lifespan
    END AS avg_monthly_revenue

FROM product_aggregations