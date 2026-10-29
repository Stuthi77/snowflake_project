-- Grain: one row per customer
SELECT
    customer_key,
    customer_name,
    market_segment,
    account_balance,
    nation_key,
    nation_name,
    region_key,
    region_name
FROM {{ ref('int_customers_with_region') }}