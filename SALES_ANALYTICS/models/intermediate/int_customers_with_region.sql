-- models/intermediate/int_customers_with_region.sql
WITH customers AS (
    SELECT * FROM {{ ref('stg_tpch__customers') }}
),
nations AS (
    SELECT * FROM {{ ref('stg_tpch__nations') }}
),
regions AS (
    SELECT * FROM {{ ref('stg_tpch__regions') }}
)

SELECT
    c.customer_key,
    c.customer_name,
    c.market_segment,
    c.account_balance,
    n.nation_key,
    n.nation_name,
    r.region_key,
    r.region_name
FROM customers c
INNER JOIN nations n ON c.nation_key = n.nation_key
INNER JOIN regions r ON n.region_key = r.region_key