-- Grain: one row per part
SELECT
    part_key,
    part_name,
    manufacturer,
    brand,
    part_type,
    part_size,
    container,
    retail_price
FROM {{ ref('stg_tpch__parts') }}