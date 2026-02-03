# Data Dictionary

## raw_applications
- **Grain:** 1 row per application_id  
- **Primary key:** application_id  

- **Important columns:**
  - `application_id` – Unique identifier for the financing application.
  - `customer_id` – Foreign key to the patient/customer.
  - `created_at` – Timestamp when the application was created.
  - `status` – Application status (submitted, approved, rejected, withdrawn).
  - `vendor` – Third-party partner / financing vendor.
  - `channel` – Acquisition channel (web, provider_referral, partner_widget, affiliate, etc.).
  - `provider_id` – Identifier for the healthcare provider or facility (e.g., hospital, clinic) associated with the application.
  - `service_line` – High-level clinical area for the associated service (e.g., cardiology, orthopedics, dermatology).
  - `icd10_code` – An anonymized diagnosis or procedure code (ICD‑10) used for reporting at a high level; may be partially populated and requires mapping/validation.

- **Notes / limitations:**
  - Some applications may be missing `provider_id`, `service_line`, or `icd10_code` due to legacy feeds or incomplete upstream data.
  - These fields are not used for individual‑patient clinical decisions, but for aggregate reporting and quality/segment analysis.

---

## fct_applications
- **Grain:** 1 row per application_id  
- **Primary key:** application_id  

- **Important columns:**
  - `application_status` – Final status of the application (e.g., approved, rejected, withdrawn).
  - `application_started` – Flag: patient started the application (derived from events).
  - `application_submitted` – Flag: patient submitted the application (derived from events).
  - `has_loan` – Flag: application resulted in a funded financing plan.
  - `has_default` – Flag: funded plan charged off / defaulted.
  - `application_vendor` – Vendor or partner associated with the application.
  - `application_date` – Date the application was created.
  - `max_funded_at` – Timestamp of the latest funding event associated with this application (if any).
  - `saw_application_page` – Flag: patient viewed the application page (from events).
  - `customer_id` – Patient/customer identifier, carried through for joins to `dim_customer` and downstream analyses.
  - `provider_id` – Provider/facility associated with the application (brought through from `raw_applications` where available).
  - `service_line` – Clinical service line associated with the application (brought through from `raw_applications` where available).
  - `icd10_code` – Raw ICD‑10 code associated with the application (if present), used for joining to `icd10_mapping` for normalized reporting.

- **Notes / limitations:**
  - Provider and clinical fields may be missing for some legacy or non‑provider‑referred applications; these are flagged and documented in QA.

---

## icd10_mapping
- **Grain:** 1 row per raw_icd10_code  
- **Primary key:** raw_icd10_code  

- **Important columns:**
  - `raw_icd10_code` – ICD‑10 code as received from source systems (hospital/clinic feeds, billing exports, etc.).
  - `normalized_icd10_code` – Cleaned or standardized ICD‑10 code used for reporting and downstream joins.
  - `description` – Human‑readable description of the normalized code (e.g., high‑level diagnosis/procedure group).
  - `is_valid` – Flag indicating whether the raw code is considered valid and mapped, vs. deprecated or erroneous.
  - `last_reviewed_at` – Timestamp of the last time this mapping entry was reviewed or updated.

- **How unmapped codes are handled:**
  - Applications with an `icd10_code` that does **not** match any `raw_icd10_code` in `icd10_mapping` are considered **unmapped**.
  - Unmapped codes are surfaced in QA queries (e.g., counts of unmapped codes by provider/service_line) so they can be:
    - Reviewed by data analysts and, when needed, clinical or coding SMEs.
    - Added to the mapping table with an appropriate `normalized_icd10_code` and `description`, or marked as invalid.
  - Until they are mapped, unmapped codes:
    - Are excluded from ICD‑10–level aggregations, but
    - Still contribute to aggregate funnel and financing metrics (applications, approvals, funded plans) so business reporting is not blocked.


  