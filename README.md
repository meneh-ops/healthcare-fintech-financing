# Healthcare Fintech Lending Funnel Metrics & Data Quality

## Executive Summary

A healthcare financing platform was struggling with inconsistent funnel metrics across patient financing applications, payment plans (loans), marketing platforms, and product analytics tools, making it hard to trust reports used for provider partnerships and growth planning. I designed and implemented a unified metrics layer in SQL, modeling patient applications, financing plans, marketing touches, and product events into clearly defined fact and dimension tables, and layered on systematic QA/UAT checks plus funnel and vendor/provider dashboards. This approach reduced discrepancies between source systems from double‑digit percentage gaps to under 1–2% for key metrics, surfaced a 15–20% difference in funded‑plan quality between top provider or channel partners, and highlighted a 10+ percentage‑point drop‑off at the submit step that Product could address. Next steps include hardening these models in dbt, operationalizing them in a cloud warehouse (Snowflake/BigQuery) with Azure Data Factory or native schedulers, and expanding the layer to cover lifetime value and clinical/credit performance by provider, service line, and diagnosis group.

---

## Business Problem

A healthcare fintech company providing patient financing works with multiple systems: a financing application platform, a servicing system for repayment plans, marketing platforms, hospital/clinic data exports, and product analytics tools.  
Each system reports slightly different numbers for “applications”, “approvals”, and “funded plans”, making it difficult for stakeholders to trust funnel, provider, and vendor metrics.  

Key questions stakeholders need to answer:

- How many patients start, submit, and fund a financing application for medical bills and procedures over time?  
- Where are the biggest drop‑offs in the funnel, and how do they vary by provider, service line, vendor, and channel?  
- Which partners and marketing channels drive high‑quality, funded payment plans rather than just clicks or incomplete applications?

This project creates a single, well‑documented metrics layer and supporting dashboards so these questions can be answered consistently and reliably at the intersection of healthcare and fintech.

---

## Methodology

1. **Data discovery & profiling**  
   - Inventory raw datasets: `raw_applications`, `raw_loans`, `raw_marketing`, `raw_events`.  
   - Profile grain, key columns, and basic data quality for each table, including healthcare‑specific fields such as provider, service line, and diagnosis codes.

2. **Dimensional modeling**  
   - Design shared dimensions: `dim_date`, `dim_customer` (patient), `dim_loan` (financing plan).  
   - Build fact tables: `fct_applications`, `fct_marketing_attribution`, `fct_funnel_events`.  

3. **Metric & entity definitions**  
   - Define entities (Patient/Customer, Application, Financing Plan, Event, Marketing Touch) and core metrics (application volume, approval rate, funded rate, default rate, funnel conversion, vendor/provider/channel performance).  
   - Document formulas, grain, and dependencies in a metrics glossary.

4. **Validation & UAT**  
   - Run targeted SQL checks for row counts, referential integrity, funnel sanity, and vendor/provider‑level reconciliation.  
   - Capture findings, known limitations, and examples of “one‑off” data issues that would be handled via mapping/cleanup logic.

5. **Analysis & visualization**  
   - Analyze funnel conversion by time, provider, vendor, and channel.  
   - Build dashboards that show funnel performance, provider/vendor performance, and basic marketing efficiency (e.g., CAC per funded plan).

6. **Business recommendations & roadmap**  
   - Translate findings into concrete recommendations for Product, Growth, and Provider Partnerships.  
   - Outline next steps for operationalizing the models in a modern healthcare‑fintech data stack.

---

## Skills Used

- **SQL (advanced)**  
  - Window functions, CTEs, aggregations, complex joins, and validation/debugging queries across patient, provider, and financing data.  

- **Data modeling**  
  - Dimensional modeling (facts and dimensions), subject‑area design (Applications, Servicing/Financing Plans, Marketing, Events).  

- **Data quality & QA/UAT**  
  - Row‑count reconciliation, referential integrity checks, funnel sanity checks, vendor/provider‑level metric reconciliation, and basic clinical‑field validation (e.g., diagnosis codes).  

- **Analytics & BI**  
  - Funnel analysis, provider/vendor/channel performance, basic marketing efficiency metrics (e.g., CAC per funded plan).  
  - Dashboard design in a BI tool (Power BI/Tableau/Sigma‑style).  

- **Communication & documentation**  
  - Data dictionary, metric definitions, and a narrative case study that bridges engineering, product, operations, and clinical/business stakeholders.  

- **Tooling & deployment concepts**  
  - Local development in Postgres, with a path to operationalizing in Snowflake/BigQuery, dbt, and orchestration tools such as Azure Data Factory for healthcare data pipelines and migrations.

---

## Data Sources & Entities

**Raw datasets**

- `raw_applications`: one row per patient financing application, with status, provider, and metadata.  
- `raw_loans`: funded financing plans and lifecycle information (e.g., charged off vs fully paid).  
- `raw_marketing`: paid marketing touches and costs for acquisition campaigns.  
- `raw_events`: product analytics events from web/app tracking across the application funnel.

**Core entities**

- **Patient / Customer** – Unique person applying for financing of healthcare services (`customer_id`).  
- **Application** – Financing request submitted by a patient for a medical bill or procedure (`application_id`).  
- **Financing Plan (Loan)** – Funded payment plan created from an approved application (`loan_id`).  
- **Event** – User interaction tied to an application or session (`event_id`).  
- **Marketing touch** – Paid click or touchpoint that may influence an application (`marketing_touch_id`).  
- **Provider / Facility** – Healthcare organization associated with the application (e.g., hospital, clinic), modeled via provider‑related fields in `raw_applications`.

Grain, primary keys, join keys, and caveats are detailed in `docs/data_dictionary.md`, including any healthcare‑specific fields (e.g., provider identifiers, service lines, diagnosis codes).

---

## Data Modeling Approach

The modeled layer is organized into subject areas:

- **Applications**  
  - `fct_applications` – one row per application with funnel flags (viewed, started, submitted) and downstream financing outcomes (approved, funded, defaulted), as well as provider/service‑line context where available.  

- **Financing Plans / Servicing**  
  - `dim_loan` – financing plan attributes (principal, rate, term, status, funded date) tied back to applications, patients, and providers.  

- **Marketing**  
  - `fct_marketing_attribution` – first‑touch attribution at the application level, with campaign, channel, vendor, and cost.  

- **Events / Product analytics**  
  - `fct_funnel_events` – event‑level fact table for product analytics‑style queries (step sequences, pathing, event counts over time).  

- **Shared dimensions**  
  - `dim_date`, `dim_customer` (patient).

Implementation details are in:

- `/sql/02_dimensions.sql`  
- `/sql/03_fact_applications.sql`  
- `/sql/04_fact_marketing_attribution.sql`  
- `/sql/05_fact_funnel_events.sql`

---

## Metric Definitions

Key business metrics (fully defined in `docs/metrics.md`):

- **Application volume** – Count of rows in `fct_applications`.  
- **Approval rate** – Approved applications / submitted applications.  
- **Funded rate** – Applications with `has_loan = TRUE` / submitted applications.  
- **Default rate** – Applications with `has_default = TRUE` / funded plans.  
- **Funnel conversion** – Step‑by‑step conversion from page view → start → submit → approve → fund.  
- **Vendor/provider/channel performance** – Application, approval, and funded metrics sliced by `application_vendor`, provider fields, and marketing `channel`.  
- **Customer acquisition cost (funded)** – Marketing spend / funded plans for a given channel, vendor, or provider cohort.

Each metric includes:

- Business definition.  
- Exact SQL formula.  
- Grain (e.g., application, financing plan, provider‑month, vendor‑month).  
- Dependencies (source tables and key columns).  

---

## Validation & QA / UAT

Validation queries live in `/sql/06_validation_uat.sql` and cover:

- **Row‑count reconciliation**  
  - Raw vs modeled row counts for core entities (applications, financing plans).  

- **Referential integrity**  
  - Financing plans missing applications, events referencing missing applications.  

- **Funnel sanity checks**  
  - Applications funded without a submit event, or other impossible states in the patient financing funnel.  

- **Vendor/provider‑level reconciliation**  
  - Approval counts by vendor/provider in raw tables vs modeled fact tables.

In test runs, these checks reduced previously observed discrepancies between systems to low single‑digit differences (typically under 1–2%) for core funnel metrics, making reports suitable for executive, provider‑partner, and vendor‑facing use.

The notebook `notebooks/lending_funnel_case_study.ipynb` walks through these checks, documents any issues found, and records known limitations and assumptions, including examples of healthcare‑specific edge cases (e.g., missing provider IDs or diagnosis codes).

---

## Analysis & Results

Using the validated models, the analysis focuses on:

- **Funnel performance over time**  
  - Monthly funnel metrics (applications, starts, submits, approvals, funded plans) and conversion rates at each step.  
  - Example: identifying a ~12 percentage‑point drop‑off between “started” and “submitted” for certain channels or provider groups, suggesting UX or process friction in the financing application flow.

- **Vendor and provider performance**  
  - Applications, approvals, funded plans, and conversion rates by vendor and provider.  
  - Example: discovering that some vendors or providers had similar approval rates but 15–20% lower funded‑plan conversion, indicating issues in post‑approval follow‑through, patient communication, or applicant quality.

- **Channel‑level marketing efficiency**  
  - CAC per funded plan by marketing channel (e.g., paid search, paid social, provider‑referred, affiliates).  
  - Example: highlighting channels where CAC per funded plan was 30–40% higher than the portfolio average, guiding budget reallocation toward more efficient acquisition sources.

These results are visualized in:

- **Funnel Overview dashboard** – Time‑series of funnel metrics and conversion rates.  
- **Vendor & Provider Channel Performance dashboard** – Side‑by‑side comparison of partners, providers, and channels.  
- **Data Quality Monitor dashboard** – Key validation metrics (missing joins, impossible states, unmapped provider or diagnosis fields) over time.

Dashboard files and screenshots are in `/tableau/`.

---

## Business Recommendations

From this project, the main recommendations for a healthcare‑fintech lender are:

- **Standardize tracking & schemas across systems**  
  - Ensure every key funnel event is consistently tagged and tied to a stable `application_id` (and, where relevant, provider and patient identifiers) across web/app, hospital feeds, and vendors.  

- **Adopt a single source of truth for funnel and provider metrics**  
  - Promote `fct_applications` and related dimensions as the canonical source for funnel KPIs, provider performance, and vendor/channel efficiency.  

- **Operationalize QA/UAT as part of every refresh**  
  - Automate row‑count, referential, and reconciliation checks, and gate dashboard refreshes on passing thresholds, especially for migrations or new provider onboardings.  

- **Use vendor, provider, and channel analytics to guide commercial decisions**  
  - Negotiate with or rebalance focus away from partners with poor downstream performance, not just poor click metrics, and reward providers/channels that drive high‑quality funded plans.  

- **Enable Product, Growth, and Provider teams to experiment**  
  - Use the metrics layer to define success metrics for UX, underwriting, payment‑plan design, and patient‑outreach experiments, and monitor impact over time across providers and service lines.

---

## Next Steps

If this were being productionized inside a healthcare‑fintech company or a client of a firm like Splash or Emergent Software, I would:

- **Harden the modeling layer**  
  - Port SQL into dbt models with tests for uniqueness, non‑null constraints, and relationships (including patient, provider, and diagnosis fields).  
  - Add documentation and lineage in dbt for transparency across data, product, and clinical leadership.  

- **Move to a cloud warehouse and orchestration**  
  - Run the same models in Snowflake or BigQuery and orchestrate ingestion + transformations using native schedulers or Azure Data Factory, including pipelines that transform CSV/Excel exports from hospital and health‑system clients.  

- **Expand metrics and subject areas**  
  - Integrate repayment, loss, collections, and basic clinical context to model lifetime value and risk/quality by provider, diagnosis group, and service line.  
  - Add more granular marketing and product analytics (e.g., multi‑touch attribution, experiment tracking, patient‑segment performance).  

- **Improve stakeholder experience**  
  - Build self‑serve dashboards and simple data dictionaries that non‑technical users (clinical ops, revenue cycle, provider relations) can navigate without needing to read raw SQL.

---

## Tech Stack & Deployment Notes

All SQL in this project is **warehouse‑agnostic and tested on Postgres** for local development.  
In a production setting, I would operationalize the same models in **Snowflake or BigQuery** using **dbt** for modular transformation and testing, and schedule jobs via native schedulers (e.g., Snowflake tasks, BigQuery scheduled queries) or an orchestrator such as **Azure Data Factory** for end‑to‑end pipeline management and healthcare data migration workflows.
