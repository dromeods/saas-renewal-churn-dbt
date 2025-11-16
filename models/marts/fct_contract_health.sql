{{ config(
    materialized='table',
    tags=['marts', 'facts']
) }}

WITH product_flags AS (
    SELECT * FROM {{ ref('int_product_risk_flag') }}
),

contract_aggregates AS (
    SELECT
        contract_id,
        COUNT(DISTINCT product_code) as total_products,
        SUM(CASE WHEN product_usage_flag IN ('CRITICAL', 'DECLINING') THEN 1 ELSE 0 END) as critical_declining_count,
        SUM(CASE WHEN product_usage_flag = 'AT_RISK' THEN 1 ELSE 0 END) as at_risk_count,
        SUM(CASE WHEN product_usage_flag = 'HEALTHY' THEN 1 ELSE 0 END) as healthy_count,
        SUM(CASE WHEN product_usage_flag = 'GROWING' THEN 1 ELSE 0 END) as growing_count,
        STRING_AGG(
            CASE WHEN product_usage_flag IN ('CRITICAL', 'DECLINING') THEN product_code ELSE NULL END, 
            ', '
        ) as downsell_risk_products,
        STRING_AGG(
            CASE WHEN product_usage_flag = 'HEALTHY' THEN product_code ELSE NULL END,
            ', '
        ) as healthy_products,
        STRING_AGG(
            CASE WHEN product_usage_flag = 'GROWING' THEN product_code ELSE NULL END,
            ', '
        ) as growing_products,
        MAX(month_date) as latest_usage_month
    FROM product_flags
    GROUP BY contract_id
),

contract_risk_scores AS (
    SELECT
        ca.contract_id,
        ca.total_products,
        ca.critical_declining_count,
        ca.at_risk_count,
        ca.healthy_count,
        ca.growing_count,
        ca.downsell_risk_products,
        ca.healthy_products,
        ca.growing_products,
        ca.latest_usage_month,
        CASE
            WHEN ca.total_products = 0 THEN 'USAGE_DATA_UNAVAILABLE'
            
            WHEN ca.critical_declining_count = ca.total_products AND ca.total_products > 0 THEN 'CHURN_RISK'
            
            WHEN ca.critical_declining_count > 0 
                 AND (ca.healthy_count > 0 OR ca.growing_count > 0) THEN 'MIXED_ENGAGEMENT_DECLINING'
            
            WHEN (ca.critical_declining_count + ca.at_risk_count) >= (ca.healthy_count + ca.growing_count)
                 AND ca.total_products > 0
                 AND ca.healthy_count > 0 THEN 'STAGNANT'
            
            WHEN ca.critical_declining_count = 0 
                 AND ca.at_risk_count = 0
                 AND ca.total_products > 0 THEN 'UPSELL_OPPORTUNITY'
            
            WHEN ca.healthy_count > 0 OR ca.growing_count > 0 THEN 'MONITOR'
            
            ELSE 'UNABLE_TO_DETERMINE'
        END as contract_risk_score
    FROM contract_aggregates ca
)

SELECT
    contract_id,
    total_products,
    critical_declining_count,
    at_risk_count,
    healthy_count,
    growing_count,
    downsell_risk_products,
    healthy_products,
    growing_products,
    latest_usage_month,
    contract_risk_score,
    CURRENT_TIMESTAMP as dbt_created_at
FROM contract_risk_scores
ORDER BY 
    CASE contract_risk_score
        WHEN 'CHURN_RISK' THEN 1
        WHEN 'MIXED_ENGAGEMENT_DECLINING' THEN 2
        WHEN 'STAGNANT' THEN 3
        WHEN 'MONITOR' THEN 4
        WHEN 'UPSELL_OPPORTUNITY' THEN 5
        ELSE 6
    END,
    critical_declining_count DESC
