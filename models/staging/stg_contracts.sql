{{ config(
    materialized='view',
    tags=['staging', 'contracts']
) }}

SELECT
    contract_id,
    account_id,
    start_date,
    renewal_date,
    product_list,
    contract_value,
    CURRENT_TIMESTAMP as dbt_loaded_at
FROM {{ source('main', 'contracts') }}
WHERE contract_id IS NOT NULL
