SELECT
    r_regionkey     AS region_key,
    UPPER(TRIM(r_name)) AS region_name,
    r_comment       AS comment
FROM {{ source('tpch', 'region') }}