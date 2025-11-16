SELECT *
FROM {{ ref('fct_contract_health') }}
WHERE contract_id IS NULL
