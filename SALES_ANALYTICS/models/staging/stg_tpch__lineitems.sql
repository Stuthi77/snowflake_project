-- models/staging/stg_tpch__lineitems.sql
SELECT
    l_orderkey      AS order_key,
    l_linenumber    AS line_number,
    l_partkey       AS part_key,
    l_suppkey       AS supplier_key,
    l_quantity::NUMBER(12,2)      AS quantity,
    l_extendedprice::NUMBER(18,2) AS extended_price,
    l_discount::NUMBER(5,4)       AS discount_pct,
    l_tax::NUMBER(5,4)            AS tax_pct,
    l_returnflag    AS return_flag,
    l_linestatus    AS line_status,
    l_shipdate::DATE AS ship_date,
    l_commitdate::DATE AS commit_date,
    l_receiptdate::DATE AS receipt_date,
    l_shipmode      AS ship_mode
FROM {{ source('tpch', 'lineitem') }}