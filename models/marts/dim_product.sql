{{ config(
    materialized='table',
    tags=['marts', 'dimensions']
) }}

SELECT DISTINCT
    product_code,
    product_code as product_name,
    COUNT(*) OVER (PARTITION BY product_code) as num_contracts
FROM {{ ref('int_product_risk_flag') }}
WHERE product_code IS NOT NULL
