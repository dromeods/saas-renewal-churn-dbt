{{ config(
    materialized='table',
    tags=['intermediate', 'usage']
) }}

WITH usage_data AS (
    SELECT
        contract_id,
        product_code,
        month_date,
        test_count,
        region,
        ROW_NUMBER() OVER (PARTITION BY contract_id, product_code ORDER BY month_date DESC) as recency_rank
    FROM {{ ref('stg_product_usage') }}
)

SELECT
    contract_id,
    product_code,
    month_date,
    test_count,
    region,
    recency_rank
FROM usage_data
