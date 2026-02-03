# QA / UAT Strategy

This document summarizes the quality assurance (QA) and user acceptance testing (UAT) approach for the **Healthcare Fintech Lending Funnel Metrics & Data Quality** project.

It explains what is tested, how it is tested, and how these checks would be automated in a production environment.

***

## 1. Objectives

The QA/UAT process is designed to:

- Ensure modeled tables accurately reflect source data (no unexpected row loss or duplication).  
- Catch structural issues (bad joins, orphan records, impossible funnel states).  
- Surface healthcare‑specific data quality issues (e.g., missing provider IDs, unmapped ICD‑10 codes).  
- Build trust in funnel, provider, and vendor metrics before they are used in dashboards or partner‑facing reports.

Most checks are implemented as SQL queries in `sql/06_validation_uat.sql` and demonstrated in `notebooks/lending_funnel_case_study.ipynb`.

***

## 2. Scope of QA / UAT

The QA/UAT scope covers:

- **Row‑level completeness**  
  - Raw vs modeled row counts for core entities (applications, financing plans).  

- **Referential integrity**  
  - Loans referencing missing applications.  
  - Events referencing missing applications.  

- **Funnel consistency**  
  - Applications funded without a submit event.  
  - Other impossible or suspicious state combinations.  

- **Metric reconciliation**  
  - Vendor/provider‑level metrics in raw vs modeled tables.  

- **Healthcare‑specific checks**  
  - Presence and uniqueness of provider IDs.  
  - Distribution and mapping of ICD‑10 codes (where present).  

***

## 3. Core Checks

### 3.1 Row‑count Reconciliation

Purpose: Verify that modeling does not unintentionally drop or duplicate records.

Example logic (implemented in `06_validation_uat.sql`):

```sql
SELECT
    'applications' AS entity,
    (SELECT COUNT(*) FROM raw_applications) AS raw_count,
    (SELECT COUNT(*) FROM fct_applications) AS fact_count;

SELECT
    'loans' AS entity,
    (SELECT COUNT(*) FROM raw_loans) AS raw_count,
    (SELECT COUNT(*) FROM dim_loan)  AS fact_count;
```

Acceptance criteria:

- `raw_count` and `fact_count` should match, or any differences must be documented (e.g., intentional filtering of test data).

***

### 3.2 Referential Integrity

Purpose: Ensure relationships between applications, loans, and events are intact.

Key checks:

- Loans without applications:

```sql
SELECT
    COUNT(*) AS loans_with_missing_application
FROM raw_loans l
LEFT JOIN fct_applications fa
  ON l.application_id = fa.application_id
WHERE fa.application_id IS NULL;
```

- Events referencing missing applications:

```sql
SELECT
    COUNT(*) AS events_with_missing_application
FROM raw_events e
LEFT JOIN fct_applications fa
  ON e.application_id = fa.application_id
WHERE e.application_id IS NOT NULL
  AND fa.application_id IS NULL;
```

Acceptance criteria:

- Counts should be zero or very small.  
- Any non‑zero counts are investigated and either:
  - Fixed upstream (e.g., missing records), or  
  - Explicitly excluded and documented as limitations.

***

### 3.3 Funnel Sanity Checks

Purpose: Detect impossible or suspicious funnel states.

Key example:

- Funded without submit:

```sql
SELECT
    COUNT(*) AS applications_funded_without_submit
FROM fct_applications
WHERE has_loan = TRUE
  AND COALESCE(application_submitted, 0) = 0;
```

Acceptance criteria:

- Ideally zero.  
- If non‑zero:
  - Investigate whether these are special workflows (e.g., internal manual entry) or missing event tracking.  
  - Decide how to handle and document (e.g., exclude from standard funnel reporting).

***

### 3.4 Vendor / Provider Metric Reconciliation

Purpose: Ensure that vendor/provider‑level counts match between raw tables and modeled facts.

Example vendor approval reconciliation:

```sql
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
  ON r.vendor = f.vendor
ORDER BY vendor;
```

Acceptance criteria:

- `diff` should be zero for all vendors (or within an expected tolerance if intentional filters are applied).  
- Any discrepancies must be traced back to specific transformations and either fixed or documented.

***

### 3.5 Healthcare‑Specific Checks (Providers & ICD‑10)

Purpose: Surface clinical/healthcare data quality issues relevant to migrations and reporting.

Example profiles:

- Provider and service line presence:

```sql
SELECT
    COUNT(*)                         AS total_rows,
    COUNT(provider_id)               AS rows_with_provider,
    COUNT(service_line)              AS rows_with_service_line,
    COUNT(icd10_code)                AS rows_with_icd10
FROM raw_applications;
```

- Unmapped ICD‑10 codes:

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

Acceptance criteria:

- Provider and clinical fields should be present at an acceptable coverage level for the target use cases.  
- All high‑volume `icd10_code` values should be mapped; any unmapped codes are queued for review and mapping.

***

## 4. UAT Flow with Stakeholders

A typical UAT flow for this project would be:

1. **Developer / Analyst QA**  
   - Run all SQL checks in `sql/06_validation_uat.sql`.  
   - Review results in the notebook and resolve obvious data issues.

2. **Technical review (Data Engineering / Product Analytics)**  
   - Validate entity definitions, joins, and metrics.  
   - Confirm that the modeled layer aligns with event schemas and upstream contracts.

3. **Business review (Product, Growth, Provider Partnerships)**  
   - Walk through funnel and provider/vendor dashboards.  
   - Sanity‑check numbers against known historical trends and spot‑check partner metrics.

4. **Healthcare / Clinical review (if applicable)**  
   - For any clinical fields (e.g., ICD‑10, service line), review unmapped or suspicious values with clinical/coding SMEs.  
   - Confirm that clinical fields are used only at an appropriate level of aggregation.

5. **Sign‑off**  
   - Document agreed‑upon definitions, assumptions, and known limitations.  
   - Mark the modeled tables as “ready” for use in production dashboards and partner‑facing reporting.

***

## 5. Automation & Productionization

In a production environment, these checks would be automated and monitored:

- **dbt tests**  
  - Uniqueness tests on primary keys (e.g., `application_id` in `fct_applications`).  
  - Not‑null tests on key join columns.  
  - Relationship tests between fact and dimension tables.

- **Scheduled validation queries**  
  - Run `06_validation_uat.sql` as part of a daily/weekly job in the warehouse.  
  - Save results to a `data_quality_checks` table for trend monitoring.

- **Orchestration with Azure Data Factory / native schedulers**  
  - Use ADF pipelines or Snowflake/BigQuery schedulers to:
    - Ingest CSV/Excel feeds from providers and upstream systems.  
    - Run transformation/modeling steps (potentially via dbt).  
    - Execute validation queries and halt or flag downstream dashboard refreshes if thresholds are breached.

- **Alerting & reporting**  
  - Configure alerts (email/Slack) when:
    - Row‑count diffs exceed thresholds.  
    - Orphan loans/events appear.  
    - Unmapped ICD‑10 codes exceed a defined count.  

***

## 6. Known Limitations & Assumptions

During QA/UAT, the following assumptions and limitations are acknowledged:

- Event data may not fully cover all application steps for legacy periods or specific partners; funnel metrics are most reliable for recent cohorts with consistent tracking.  
- Provider and clinical fields (`provider_id`, `service_line`, `icd10_code`) may be partially populated; analyses using these fields are interpreted with that context.  
- ICD‑10 mapping is illustrative and not exhaustive; in a real environment, mappings would be maintained centrally and governed by clinical/coding teams.

These items are called out in `README.md` and should be referenced whenever the data is used for decision‑making or external reporting.