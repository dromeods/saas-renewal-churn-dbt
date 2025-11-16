{{ config(
    materialized='table',
    tags=['intermediate', 'risk']
) }}

WITH metrics AS (
    SELECT * FROM {{ ref('int_usage_metrics') }}
),

product_flags AS (
    SELECT
        contract_id,
        product_code,
        month_date,
        test_count,
        six_month_slope,
        three_month_velocity,
        month_over_month,
        CASE
            WHEN test_count < 5 THEN 'CRITICAL'
            
            WHEN test_count < 20 AND month_over_month < -10 THEN 'CRITICAL'
            
            WHEN test_count < 20 AND six_month_slope < -5 AND three_month_velocity < -3 THEN 'DECLINING'
            
            WHEN test_count < 20 AND three_month_velocity < -5 THEN 'DECLINING'
            
            WHEN test_count < 20 AND six_month_slope < -3 THEN 'AT_RISK'
            
            WHEN test_count < 20 THEN 'AT_RISK'
            
            WHEN test_count >= 20 AND three_month_velocity > 0 THEN 'GROWING'
            
            WHEN test_count >= 20 THEN 'HEALTHY'
            
            ELSE 'UNKNOWN'
        END AS product_usage_flag
    FROM metrics
)

SELECT
    contract_id,
    product_code,
    month_date,
    test_count,
    six_month_slope,
    three_month_velocity,
    month_over_month,
    product_usage_flag
FROM product_flags
