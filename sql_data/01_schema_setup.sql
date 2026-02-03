-- SCHEMA / DATABASE SETUP
CREATE SCHEMA IF NOT EXISTS analytics;

SET search_path TO analytics;

CREATE TABLE IF NOT EXISTS raw_applications (
    application_id      VARCHAR PRIMARY KEY,
    customer_id         VARCHAR,
    created_at          TIMESTAMP,
    product_type        VARCHAR,
    source_system       VARCHAR,
    status              VARCHAR,   -- submitted, approved, rejected, withdrawn
    requested_amount    NUMERIC(18,2),
    term_months         INT,
    channel             VARCHAR,   -- web, provider_referral, affiliate, etc.
    vendor              VARCHAR,   -- 3rd-party partner / financing vendor
    provider_id         VARCHAR,   -- hospital / clinic
    service_line        VARCHAR,   -- cardiology, orthopedics, etc.
    icd10_code          VARCHAR    -- diagnosis/procedure code (optional)
);

CREATE TABLE IF NOT EXISTS raw_loans (
    loan_id             VARCHAR PRIMARY KEY,
    application_id      VARCHAR,
    customer_id         VARCHAR,
    funded_at           TIMESTAMP,
    principal_amount    NUMERIC(18,2),
    interest_rate       NUMERIC(6,3),
    term_months         INT,
    status              VARCHAR,   -- active, charged_off, paid_off
    vendor              VARCHAR
);

CREATE TABLE IF NOT EXISTS raw_marketing (
    marketing_touch_id  VARCHAR PRIMARY KEY,
    customer_id         VARCHAR,
    application_id      VARCHAR,
    campaign_id         VARCHAR,
    channel             VARCHAR,   -- paid_search, paid_social, provider_referral, etc.
    vendor              VARCHAR,   -- Google, Meta, PartnerX, etc.
    click_timestamp     TIMESTAMP,
    cost_usd            NUMERIC(18,4)
);

CREATE TABLE IF NOT EXISTS raw_events (
    event_id            VARCHAR PRIMARY KEY,
    customer_id         VARCHAR,
    session_id          VARCHAR,
    application_id      VARCHAR,
    event_name          VARCHAR,   -- page_view_application, application_started, etc.
    event_timestamp     TIMESTAMP,
    source_system       VARCHAR,   -- Heap, Amplitude, app, web
    device              VARCHAR,
    url_path            VARCHAR
);
