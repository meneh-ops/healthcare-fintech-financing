SET search_path TO analytics;

-- fct_marketing_attribution: simple first-touch attribution at application level

CREATE TABLE IF NOT EXISTS fct_marketing_attribution AS
WITH ranked_touches AS (
    SELECT
        mt.marketing_touch_id,
        mt.customer_id,
        mt.application_id,
        mt.campaign_id,
        mt.channel,
        mt.vendor,
        mt.click_timestamp,
        mt.cost_usd,
        ROW_NUMBER() OVER (
            PARTITION BY mt.application_id
            ORDER BY mt.click_timestamp ASC
        ) AS rn
    FROM raw_marketing mt
),
first_touch AS (
    SELECT *
    FROM ranked_touches
    WHERE rn = 1
)
SELECT
    ft.application_id,
    ft.customer_id,
    ft.campaign_id,
    ft.channel,
    ft.vendor,
    ft.click_timestamp,
    ft.cost_usd AS first_touch_cost_usd
FROM first_touch ft;