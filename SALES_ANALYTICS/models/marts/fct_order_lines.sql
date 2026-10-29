{{ config(
    materialized   = 'incremental',
    unique_key     = 'order_line_key',
    incremental_strategy = 'merge',
    on_schema_change = 'append_new_columns'
) }}

-- Grain: one row per order line
SELECT *
FROM {{ ref('int_order_lines_enriched') }}

{% if is_incremental() %}
WHERE order_date > (SELECT COALESCE(MAX(order_date), '1900-01-01') FROM {{ this }})
{% endif %}