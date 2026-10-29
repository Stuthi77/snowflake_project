-- snapshots/snap_region_targets.sql
{% snapshot snap_region_targets %}
{{ config(
    target_schema = 'SNAPSHOTS',
    unique_key    = "region_name || '-' || target_year",
    strategy      = 'check',
    check_cols    = ['sales_target']
) }}
SELECT * FROM {{ ref('stg_raw__region_targets') }}
{% endsnapshot %}