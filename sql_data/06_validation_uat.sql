SET search_path TO analytics;

-- BASIC COUNT VALIDATION: raw vs modeled

-- 1) Raw applications vs fct_applications
SELECT
    'applications' AS entity,
    (SELECT COUNT(*) FROM raw_applications) AS raw_count,
    (SELECT COUNT(*) FROM fct_applications) AS fact_count;

-- 2) Loans should always join to an application in fact table
SELECT
    'loans_with_missing_application' AS check_name,
    COUNT(*) AS loan_count
FROM raw_loans l
LEFT JOIN fct_applications fa
    ON l.application_id = fa.application_id
WHERE fa.application_id IS NULL;

-- 3) Events referencing non-existent applications
SELECT
    'events_with_missing_application' AS check_name,
    COUNT(*)```sql
SET search_path TO analytics;

-- BASIC COUNT VALIDATION: raw vs modeled

-- 1) Raw applications vs fct_applications
SELECT
    'applications' AS entity,
    (SELECT COUNT(*) FROM raw_applications) AS raw_count,
    (SELECT COUNT(*) FROM fct_applications) AS fact_count;

-- 2) Loans should always join to an application in fact table
SELECT
    'loans_with_missing_application' AS check_name,
    COUNT(*) AS loan_count
FROM raw_loans l
LEFT JOIN fct_applications fa
    ON l.application_id = fa.application_id
WHERE fa.application_id IS NULL;

-- 3) Events referencing non-existent applications
SELECT
    'events_with_missing_application' AS check_name,
    COUNT(*) AS event_count
FROM raw_events e
LEFT JOIN fct_applications fa
    ON e.application_id = fa.application_id
WHERE e.application_id IS NOT NULL
  AND fa.application_id IS NULL;

-- 4) Funnel sanity: you cannot be funded without submitted
SELECT
    'funded_without_submit' AS check_name,
    COUNT(*) AS application_count
FROM fct_applications
WHERE has_loan = TRUE
  AND COALESCE(application_submitted, 0) = 0;

-- 5) Metric reconciliation: approvals by vendor, raw vs fact
WITH raw_agg AS (
    SELECT
        vendor,
        COUNT(*) AS raw_approved
    FROM raw_applications
    WHERE status = 'approved'
    GROUP BY vendor
),
fact_agg AS (
    SELECT
        application_vendor AS vendor,
        COUNT(*) AS fact_approved
    FROM fct_applications
    WHERE application_status = 'approved'
    GROUP BY application_vendor
)
SELECT
    COALESCE(r.vendor, f.vendor) AS vendor,
    COALESCE(r.raw_approved, 0)  AS raw_approved,
    COALESCE(f.fact_approved, 0) AS fact_approved,
    COALESCE(f.fact_approved, 0) - COALESCE(r.raw_approved, 0) AS diff
FROM raw_agg r
FULL OUTER JOIN fact_agg f
    ON r.vendor = f.vendor;