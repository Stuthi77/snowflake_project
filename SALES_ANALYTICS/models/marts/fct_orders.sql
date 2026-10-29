-- Grain: one row per order
WITH lines AS (
    SELECT
        order_key,
        COUNT(*)            AS line_count,
        SUM(quantity)       AS total_quantity,
        SUM(net_revenue)    AS net_revenue,
        SUM(gross_margin)   AS gross_margin
    FROM {{ ref('int_order_lines_enriched') }}
    GROUP BY order_key
)

SELECT
    o.order_key,
    o.customer_key,
    o.order_date,
    YEAR(o.order_date) AS order_year,
    o.order_status,
    o.order_priority,
    o.order_total_price,
    l.line_count,
    l.total_quantity,
    l.net_revenue,
    l.gross_margin
FROM {{ ref('stg_tpch__orders') }} o
INNER JOIN lines l ON o.order_key = l.order_key