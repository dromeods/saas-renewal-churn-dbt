{{ config(
    materialized='view',
    tags=['staging', 'usage']
) }}

SELECT
    contract_id,
    product_code,
    month_date,
    test_count,
    region,
    CURRENT_TIMESTAMP as dbt_loaded_at
FROM {{ source('main', 'product_usage') }}
WHERE contract_id IS NOT NULL
  AND product_code IS NOT NULL
  AND month_date IS NOT NULL
  AND test_count >= 0
