SET search_path TO analytics;

-- fct_funnel_events: event-level fact table for product analytics-style queries

CREATE TABLE IF NOT EXISTS fct_funnel_events AS
SELECT
    e.event_id,
    e.customer_id,
    e.session_id,
    e.application_id,
    e.event_name,
    e.event_timestamp,
    DATE(e.event_timestamp)          AS event_date,
    dd.year_month                    AS event_year_month,
    e.source_system,
    e.device,
    e.url_path
FROM raw_events e
LEFT JOIN dim_date dd
    ON DATE(e.event_timestamp) = dd.date_key;
