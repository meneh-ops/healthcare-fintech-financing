SET search_path TO analytics;

-- fct_applications: one row per application, with funnel outcomes and provider/clinical context

CREATE TABLE IF NOT EXISTS fct_applications AS
WITH app_base AS (
    SELECT
        a.application_id,
        a.customer_id,
        a.created_at,
        DATE(a.created_at)                    AS application_date,
        a.product_type,
        a.source_system,
        a.status                               AS application_status,
        a.requested_amount,
        a.term_months,
        a.channel,
        a.vendor                               AS application_vendor,
        a.provider_id,
        a.service_line,
        a.icd10_code
    FROM raw_applications a
),

loan_flags AS (
    SELECT
        application_id,
        COUNT(*) > 0 AS has_loan,
        MAX(CASE WHEN status = 'charged_off' THEN 1 ELSE 0 END) AS has_default,
        MAX(funded_at) AS max_funded_at
    FROM raw_loans
    GROUP BY application_id
),

funnel_flags AS (
    SELECT
        application_id,
        MAX(CASE WHEN event_name = 'page_view_application' THEN 1 ELSE 0 END) AS saw_application_page,
        MAX(CASE WHEN event_name = 'application_started' THEN 1 ELSE 0 END)    AS application_started,
        MAX(CASE WHEN event_name = 'application_submitted' THEN 1 ELSE 0 END)  AS application_submitted
    FROM raw_events
    GROUP BY application_id
)

SELECT
    ab.*,
    lf.has_loan,
    lf.has_default,
    lf.max_funded_at,
    ff.saw_application_page,
    ff.application_started,
    ff.application_submitted
FROM app_base ab
LEFT JOIN loan_flags   lf ON ab.application_id = lf.application_id
LEFT JOIN funnel_flags ff ON ab.application_id = ff.application_id;
