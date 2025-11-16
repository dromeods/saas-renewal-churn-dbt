{{ config(
    materialized='table',
    tags=['marts', 'dimensions']
) }}

SELECT
    c.contract_id,
    c.account_id,
    c.start_date,
    c.renewal_date,
    c.product_list,
    c.contract_value,
    DATEDIFF('day', c.renewal_date, CURRENT_DATE) as days_until_renewal,
    CASE 
        WHEN DATEDIFF('day', CURRENT_DATE, c.renewal_date) <= 0 THEN 'Active'
        WHEN DATEDIFF('day', CURRENT_DATE, c.renewal_date) <= 30 THEN 'Renewing Soon'
        WHEN DATEDIFF('day', CURRENT_DATE, c.renewal_date) <= 90 THEN 'Upcoming'
        ELSE 'Long Tail'
    END as renewal_status
FROM {{ ref('stg_contracts') }} c
