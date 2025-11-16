{{ config(
    materialized='table',
    tags=['intermediate', 'metrics']
) }}

WITH monthly_usage AS (
    SELECT * FROM {{ ref('int_monthly_usage') }}
),

metrics_window AS (
    SELECT
        contract_id,
        product_code,
        month_date,
        test_count,
        region,
        recency_rank,
        CAST(COALESCE(
            (SUM(test_count) OVER (PARTITION BY contract_id, product_code ORDER BY month_date ROWS BETWEEN 5 PRECEDING AND CURRENT ROW) - 
             SUM(test_count) OVER (PARTITION BY contract_id, product_code ORDER BY month_date ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING)) 
            / NULLIF(6, 0), 0
        ) AS FLOAT) as six_month_slope,
        
        CAST(COALESCE(
            (test_count - 
             LAG(test_count, 3) OVER (PARTITION BY contract_id, product_code ORDER BY month_date)) 
            / NULLIF(3, 0), 0
        ) AS FLOAT) as three_month_velocity,
        
        CAST(COALESCE(
            test_count - LAG(test_count, 1) OVER (PARTITION BY contract_id, product_code ORDER BY month_date), 
            0
        ) AS FLOAT) as month_over_month
    FROM monthly_usage
)

SELECT
    contract_id,
    product_code,
    month_date,
    test_count,
    region,
    recency_rank,
    six_month_slope,
    three_month_velocity,
    month_over_month
FROM metrics_window
WHERE recency_rank = 1
