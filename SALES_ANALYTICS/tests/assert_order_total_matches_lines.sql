-- tests/assert_order_total_matches_lines.sql
-- fct_orders.net_revenue must equal the sum of its lines, within 1 currency unit
WITH line_totals AS (
    SELECT order_key, SUM(net_revenue) AS line_revenue
    FROM {{ ref('fct_order_lines') }}
    GROUP BY order_key
)
SELECT
    o.order_key,
    o.net_revenue,
    l.line_revenue,
    ABS(o.net_revenue - l.line_revenue) AS diff
FROM {{ ref('fct_orders') }} o
INNER JOIN line_totals l ON o.order_key = l.order_key
WHERE ABS(o.net_revenue - l.line_revenue) > 1.00