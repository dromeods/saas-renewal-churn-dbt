SELECT *
FROM {{ ref('int_product_risk_flag') }}
WHERE product_usage_flag NOT IN ('CRITICAL', 'DECLINING', 'AT_RISK', 'GROWING', 'HEALTHY', 'UNKNOWN')
