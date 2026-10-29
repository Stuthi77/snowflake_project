SELECT
    n_nationkey     AS nation_key,
    UPPER(TRIM(n_name)) AS nation_name,
    n_regionkey     AS region_key,
    n_comment       AS comment
FROM {{ source('tpch', 'nation') }}