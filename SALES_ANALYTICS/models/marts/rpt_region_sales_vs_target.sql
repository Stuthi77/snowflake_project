WITH actuals AS (
    SELECT
        region_name,
        order_year,
        SUM(net_revenue) AS actual_revenue
    FROM {{ ref('fct_order_lines') }}
    GROUP BY region_name, order_year
),
targets AS (
    SELECT region_name, target_year, sales_target
    FROM {{ ref('stg_raw__region_targets') }}
)

SELECT
    COALESCE(a.region_name, t.region_name) AS region_name,
    COALESCE(a.order_year,  t.target_year) AS fiscal_year,
    a.actual_revenue,
    t.sales_target,
    a.actual_revenue - t.sales_target      AS variance_amount,
    ROUND(100.0 * (a.actual_revenue - t.sales_target) / NULLIF(t.sales_target, 0), 2) AS variance_pct
FROM actuals a
FULL OUTER JOIN targets t
    ON  a.region_name = t.region_name
    AND a.order_year  = t.target_year