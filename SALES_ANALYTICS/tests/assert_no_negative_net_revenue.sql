-- tests/assert_no_negative_net_revenue.sql
SELECT order_line_key, net_revenue
FROM {{ ref('fct_order_lines') }}
WHERE net_revenue < 0