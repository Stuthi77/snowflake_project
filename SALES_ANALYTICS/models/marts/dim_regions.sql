-- Grain: one row per region
WITH nations AS (
    SELECT region_key, COUNT(*) AS nation_count
    FROM {{ ref('stg_tpch__nations') }}
    GROUP BY region_key
)

SELECT
    r.region_key,
    r.region_name,
    n.nation_count
FROM {{ ref('stg_tpch__regions') }} r
LEFT JOIN nations n ON r.region_key = n.region_key