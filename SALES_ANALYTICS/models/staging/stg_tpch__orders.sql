SELECT
    o_orderkey        AS order_key,
    o_custkey         AS customer_key,
    o_orderstatus     AS order_status,
    o_totalprice::NUMBER(18,2) AS order_total_price,
    o_orderdate::DATE AS order_date,
    o_orderpriority   AS order_priority,
    o_clerk           AS clerk,
    o_shippriority    AS ship_priority
FROM {{ source('tpch', 'orders') }}