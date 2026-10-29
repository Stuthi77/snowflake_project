-- models/intermediate/int_order_lines_enriched.sql
-- Grain: one row per order line (order_key + line_number)
WITH lines AS (
    SELECT * FROM {{ ref('stg_tpch__lineitems') }}
),
orders AS (
    SELECT * FROM {{ ref('stg_tpch__orders') }}
),
parts AS (
    SELECT * FROM {{ ref('stg_tpch__parts') }}
),
customers AS (
    SELECT * FROM {{ ref('int_customers_with_region') }}
)

SELECT
    MD5(l.order_key::VARCHAR || '-' || l.line_number::VARCHAR) AS order_line_key,
    l.order_key,
    l.line_number,
    o.order_date,
    YEAR(o.order_date)  AS order_year,
    o.order_status,
    c.customer_key,
    c.customer_name,
    c.market_segment,
    c.nation_name,
    c.region_name,
    l.part_key,
    p.part_name,
    p.brand,
    p.part_type,
    p.retail_price,
    l.supplier_key,
    l.quantity,
    l.extended_price,
    l.discount_pct,
    l.tax_pct,
    ROUND(l.extended_price * (1 - l.discount_pct), 2)                  AS net_revenue,
    ROUND(l.extended_price * (1 - l.discount_pct) * (1 + l.tax_pct), 2) AS net_revenue_with_tax,
    ROUND(l.extended_price * (1 - l.discount_pct) - (p.retail_price * l.quantity * 0.6), 2) AS gross_margin,
    l.return_flag,
    l.ship_date,
    l.ship_mode
FROM lines l
INNER JOIN orders    o ON l.order_key   = o.order_key
INNER JOIN parts     p ON l.part_key    = p.part_key
INNER JOIN customers c ON o.customer_key = c.customer_key