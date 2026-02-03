# Metrics Glossary

This document defines the core metrics used in the **Healthcare Fintech Lending Funnel Metrics & Data Quality** project.  
Each metric includes a business definition, grain, example SQL, and notes.

***

## 1. Funnel & Volume Metrics

### Application Volume

- Definition (business): The number of patient financing applications created in a given period.  
- Grain: Reporting by day, month, provider, vendor, or channel; base grain is application (`application_id` in `fct_applications`).  

Example SQL:

```sql
SELECT
    DATE(application_date) AS application_date,
    COUNT(*)              AS application_volume
FROM fct_applications
GROUP BY DATE(application_date);
```

Notes:
- Includes all applications regardless of status.
- Can be filtered by `provider_id`, `service_line`, `channel`, or `application_vendor`.

***

### Started Applications

- Definition (business): Count of applications where a patient has started filling out the financing form (but may not have submitted).  
- Grain: Application.

Example SQL:

```sql
SELECT
    DATE(application_date) AS application_date,
    SUM(application_started) AS started_applications
FROM fct_applications
GROUP BY DATE(application_date);
```

Notes:
- `application_started` is a flag derived from funnel events in `raw_events`.

***

### Submitted Applications

- Definition (business): Count of applications where the patient successfully submitted the financing application.  
- Grain: Application.

Example SQL:

```sql
SELECT
    DATE(application_date) AS application_date,
    SUM(application_submitted) AS submitted_applications
FROM fct_applications
GROUP BY DATE(application_date);
```

Notes:
- `application_submitted` is a flag derived from funnel events.
- Used as the denominator for approval rate.

***

### Approved Applications (Count)

- Definition (business): Number of submitted applications that were approved by underwriting/policy.  
- Grain: Application.

Example SQL:

```sql
SELECT
    DATE(application_date) AS application_date,
    COUNT(*) AS approved_applications
FROM fct_applications
WHERE application_status = 'approved'
GROUP BY DATE(application_date);
```

Notes:
- Approval is based on `application_status` in `fct_applications`.

***

### Funded Plans (Count)

- Definition (business): Number of applications that resulted in a funded financing plan (loan).  
- Grain: Application (with `has_loan = TRUE`).

Example SQL:

```sql
SELECT
    DATE(application_date) AS application_date,
    COUNT(*) AS funded_plans
FROM fct_applications
WHERE has_loan = TRUE
GROUP BY DATE(application_date);
```

Notes:
- This is the key “success” metric for the financing funnel.

***

## 2. Conversion & Rate Metrics

### Start Rate

- Definition (business): Share of financing applications that reach the “started” step out of all created applications.  

Formula:  
Start Rate = Started Applications / Application Volume

Example SQL:

```sql
SELECT
    DATE(application_date) AS application_date,
    COUNT(*)                                   AS applications,
    SUM(application_started)                   AS started,
    SUM(application_started)::DECIMAL
      / NULLIF(COUNT(*), 0)                    AS start_rate
FROM fct_applications
GROUP BY DATE(application_date);
```

Notes:
- Highlights engagement issues from marketing and provider workflows.

***

### Submit Rate (of Starters)

- Definition (business): Share of started applications that were actually submitted.  

Formula:  
Submit Rate = Submitted Applications / Started Applications

Example SQL:

```sql
SELECT
    DATE(application_date) AS application_date,
    SUM(application_started)            AS started,
    SUM(application_submitted)          AS submitted,
    SUM(application_submitted)::DECIMAL
      / NULLIF(SUM(application_started), 0) AS submit_rate
FROM fct_applications
GROUP BY DATE(application_date);
```

Notes:
- Drops here often indicate friction in the form or process.

***

### Approval Rate

- Definition (business): Share of submitted applications that are approved.  

Formula:  
Approval Rate = Approved Applications / Submitted Applications

Example SQL:

```sql
SELECT
    DATE(application_date) AS application_date,
    SUM(application_submitted)                           AS submitted,
    COUNT(*) FILTER (WHERE application_status = 'approved') AS approved,
    COUNT(*) FILTER (WHERE application_status = 'approved')::DECIMAL
      / NULLIF(SUM(application_submitted), 0)            AS approval_rate
FROM fct_applications
GROUP BY DATE(application_date);
```

Notes:
- Sensitive to underwriting criteria and patient mix.

***

### Funded Rate (of Approvals)

- Definition (business): Share of approved applications that convert into funded plans.  

Formula:  
Funded Rate = Funded Plans / Approved Applications

Example SQL:

```sql
SELECT
    DATE(application_date) AS application_date,
    COUNT(*) FILTER (WHERE application_status = 'approved') AS approved,
    COUNT(*) FILTER (WHERE has_loan = TRUE)                 AS funded,
    COUNT(*) FILTER (WHERE has_loan = TRUE)::DECIMAL
      / NULLIF(COUNT(*) FILTER (WHERE application_status = 'approved'), 0) AS funded_rate
FROM fct_applications
GROUP BY DATE(application_date);
```

Notes:
- Captures post‑approval drop‑off.

***

### Default Rate

- Definition (business): Share of funded plans that eventually default/charge off.  

Formula:  
Default Rate = Defaulted Plans / Funded Plans

Example SQL:

```sql
SELECT
    DATE(application_date) AS application_date,
    COUNT(*) FILTER (WHERE has_loan = TRUE)          AS funded,
    COUNT(*) FILTER (WHERE has_default = TRUE)       AS defaulted,
    COUNT(*) FILTER (WHERE has_default = TRUE)::DECIMAL
      / NULLIF(COUNT(*) FILTER (WHERE has_loan = TRUE), 0) AS default_rate
FROM fct_applications
GROUP BY DATE(application_date);
```

Notes:
- Often analyzed by funding cohort.

***

## 3. Partner, Provider & Channel Metrics

### Vendor / Provider Funnel Metrics

- Definition (business): Funnel metrics (applications, approvals, funded plans, and rates) sliced by partner vendors and healthcare providers.  
- Grain: Vendor or provider by period; base grain is application.

Example SQL (by vendor):

```sql
WITH base AS (
    SELECT
        application_vendor AS vendor,
        application_started,
        application_submitted,
        CASE WHEN application_status = 'approved' THEN 1 ELSE 0 END AS is_approved,
        CASE WHEN has_loan THEN 1 ELSE 0 END                        AS is_funded
    FROM fct_applications
)
SELECT
    vendor,
    COUNT(*)                AS applications,
    SUM(application_started) AS started,
    SUM(application_submitted) AS submitted,
    SUM(is_approved)         AS approved,
    SUM(is_funded)           AS funded
FROM base
GROUP BY vendor;
```

Notes:
- Same pattern applies to `provider_id` or `service_line`.

***

### CAC per Funded Plan

- Definition (business): Average acquisition cost per funded plan, by channel/vendor/provider.  

Formula:  
CAC (Funded) = Marketing Spend / Funded Plans

Example SQL (by channel):

```sql
WITH app_mkt AS (
    SELECT
        fa.application_id,
        COALESCE(fm.channel, fa.channel) AS channel,
        CASE WHEN fa.has_loan THEN 1 ELSE 0 END       AS is_funded,
        fm.first_touch_cost_usd
    FROM fct_applications fa
    LEFT JOIN fct_marketing_attribution fm
      ON fa.application_id = fm.application_id
)
SELECT
    channel,
    SUM(first_touch_cost_usd)                     AS spend_usd,
    SUM(is_funded)                                AS funded_plans,
    SUM(first_touch_cost_usd)::DECIMAL
      / NULLIF(SUM(is_funded), 0)                 AS cac_funded
FROM app_mkt
GROUP BY channel;
```

Notes:
- Uses first‑touch attribution at the application level.

***

## 4. Data Quality & QA Metrics

### Raw vs Fact Row Count Difference

- Definition (business): Difference between row counts in raw tables and their corresponding modeled tables.  

Formula:  
Diff = Fact Row Count − Raw Row Count

Example SQL:

```sql
SELECT
    'applications' AS entity,
    (SELECT COUNT(*) FROM raw_applications) AS raw_count,
    (SELECT COUNT(*) FROM fct_applications) AS fact_count,
    (SELECT COUNT(*) FROM fct_applications)
      - (SELECT COUNT(*) FROM raw_applications) AS diff;
```

Notes:
- Should generally be zero; any non‑zero difference must be explained.

***

### Orphan Loans / Events

- Definition (business): Loans or events that reference an application that does not exist in the modeled applications table.  
- Grain: Loan (`loan_id`) or event (`event_id`).

Example SQL (loans):

```sql
SELECT
    COUNT(*) AS loans_with_missing_application
FROM raw_loans l
LEFT JOIN fct_applications fa
  ON l.application_id = fa.application_id
WHERE fa.application_id IS NULL;
```

Notes:
- Indicates incomplete migrations, missing joins, or legacy data.

***

### Unmapped ICD‑10 Codes

- Definition (business): Count of applications whose `icd10_code` does not have a corresponding entry in the `icd10_mapping` table.  
- Grain: ICD‑10 code.

Example SQL:

```sql
SELECT
    a.icd10_code,
    COUNT(*) AS application_count
FROM raw_applications a
LEFT JOIN icd10_mapping m
  ON a.icd10_code = m.raw_icd10_code
WHERE a.icd10_code IS NOT NULL
  AND m.normalized_icd10_code IS NULL
GROUP BY a.icd10_code
ORDER BY application_count DESC;
```

Notes:
- Used to drive mapping/cleanup work with clinical or coding SMEs.
- Unmapped codes are excluded from ICD‑10–level breakdowns but still counted in overall funnel metrics.

***

This metrics glossary is intended to be read alongside:

- `README.md` – project overview, methodology, and business context.  
- `docs/data_dictionary.md` – table and column‑level definitions.  
- `sql/06_validation_uat.sql` – QA/UAT queries implementing many of the checks above.