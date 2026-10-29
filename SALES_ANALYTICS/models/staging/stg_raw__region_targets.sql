-- models/staging/stg_raw__region_targets.sql
SELECT
    UPPER(TRIM(region))        AS region_name,
    target_year::NUMBER(4,0)   AS target_year,
    sales_target::NUMBER(18,2) AS sales_target,
    loaded_at::TIMESTAMP_NTZ   AS loaded_at
FROM {{ source('raw', 'region_targets') }}