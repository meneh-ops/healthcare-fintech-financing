SET search_path TO analytics;

-- dim_date
CREATE TABLE IF NOT EXISTS dim_date AS
SELECT
    d::date                     AS date_key,
    EXTRACT(YEAR  FROM d)       AS year,
    EXTRACT(MONTH FROM d)       AS month,
    EXTRACT(DAY   FROM d)       AS day,
    EXTRACT(QUARTER FROM d)     AS quarter,
    TO_CHAR(d::date, 'YYYY-MM') AS year_month
FROM generate_series(
    DATE '2024-01-01',
    DATE '2026-12-31',
    INTERVAL '1 day'
) AS d;

-- dim_customer (patient)
CREATE TABLE IF NOT EXISTS dim_customer AS
SELECT
    customer_id,
    MIN(created_at)                       AS first_seen_at,
    COUNT(DISTINCT application_id)        AS lifetime_applications
FROM raw_applications
GROUP BY customer_id;

-- dim_loan (financing plan)
CREATE TABLE IF NOT EXISTS dim_loan AS
SELECT
    l.loan_id,
    l.application_id,
    l.customer_id,
    l.vendor,
    l.principal_amount,
    l.interest_rate,
    l.term_months,
    l.status,
    DATE(l.funded_at)         AS funded_date,
    dd.year                   AS funded_year,
    dd.year_month             AS funded_year_month
FROM raw_loans l
LEFT JOIN dim_date dd
    ON DATE(l.funded_at) = dd.date_key;
