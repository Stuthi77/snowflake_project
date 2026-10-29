SELECT
    p_partkey       AS part_key,
    p_name          AS part_name,
    p_mfgr          AS manufacturer,
    p_brand         AS brand,
    p_type          AS part_type,
    p_size          AS part_size,
    p_container     AS container,
    p_retailprice::NUMBER(18,2) AS retail_price
FROM {{ source('tpch', 'part') }}