import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import csv

np.random.seed(42)

# -----------------------------
# 1. raw_applications.csv
# -----------------------------
n_apps = 500
start_date = datetime(2024, 1, 1)

application_ids = [f"APP_{i:05d}" for i in range(1, n_apps + 1)]
customer_ids = [f"CUST_{np.random.randint(1, 200):04d}" for _ in range(n_apps)]
created_at = [start_date + timedelta(days=int(np.random.randint(0, 365))) for _ in range(n_apps)]
product_type = np.random.choice(['Installment', 'BNPL', 'CareCredit-like'], size=n_apps)
source_system = np.random.choice(['web', 'mobile', 'call_center'], size=n_apps)
status = np.random.choice(['submitted', 'approved', 'rejected', 'withdrawn'], size=n_apps,
                          p=[0.3, 0.4, 0.2, 0.1])
requested_amount = np.round(np.random.uniform(200, 8000, size=n_apps), 2)
term_months = np.random.choice([6, 12, 18, 24, 36], size=n_apps)
channel = np.random.choice(['web', 'provider_referral', 'affiliate', 'paid_search', 'paid_social'],
                           size=n_apps)
vendor = np.random.choice(['VendorA', 'VendorB', 'VendorC'], size=n_apps)
provider_id = np.random.choice(['Prov1', 'Prov2', 'Prov3', 'Prov4'], size=n_apps)
service_line = np.random.choice(['Cardiology', 'Orthopedics', 'Dermatology', 'Oncology'], size=n_apps)
icd10_code = np.random.choice(['I10', 'E11', 'M17', 'L40', None],
                              size=n_apps, p=[0.25, 0.25, 0.2, 0.2, 0.1])

apps_df = pd.DataFrame({
    'application_id': application_ids,
    'customer_id': customer_ids,
    'created_at': created_at,
    'product_type': product_type,
    'source_system': source_system,
    'status': status,
    'requested_amount': requested_amount,
    'term_months': term_months,
    'channel': channel,
    'vendor': vendor,
    'provider_id': provider_id,
    'service_line': service_line,
    'icd10_code': icd10_code
})

apps_df.to_csv('raw_applications.csv', index=False)

# -----------------------------
# 2. raw_loans.csv
# -----------------------------
n_loans = int(n_apps * 0.5)
loan_app_ids = np.random.choice(application_ids, size=n_loans, replace=False)
loan_ids = [f"LOAN_{i:05d}" for i in range(1, n_loans + 1)]

funded_at = [start_date + timedelta(days=int(np.random.randint(10, 400))) for _ in range(n_loans)]
principal_amount = apps_df.set_index('application_id').loc[loan_app_ids, 'requested_amount'].values
interest_rate = np.round(np.random.uniform(0.05, 0.24, size=n_loans), 3)
term_months_l = apps_df.set_index('application_id').loc[loan_app_ids, 'term_months'].values
status_l = np.random.choice(['active', 'charged_off', 'paid_off'], size=n_loans,
                            p=[0.6, 0.15, 0.25])
vendor_l = apps_df.set_index('application_id').loc[loan_app_ids, 'vendor'].values
customer_l = apps_df.set_index('application_id').loc[loan_app_ids, 'customer_id'].values

loans_df = pd.DataFrame({
    'loan_id': loan_ids,
    'application_id': loan_app_ids,
    'customer_id': customer_l,
    'funded_at': funded_at,
    'principal_amount': principal_amount,
    'interest_rate': interest_rate,
    'term_months': term_months_l,
    'status': status_l,
    'vendor': vendor_l
})

loans_df.to_csv('raw_loans.csv', index=False)

# -----------------------------
# 3. raw_marketing.csv
# -----------------------------
n_touches = 800
mt_ids = [f"MT_{i:05d}" for i in range(1, n_touches + 1)]
app_ids_for_mt = np.random.choice(application_ids, size=n_touches, replace=True)
customers_for_mt = apps_df.set_index('application_id').loc[app_ids_for_mt, 'customer_id'].values
campaign_id = np.random.choice(['Camp1', 'Camp2', 'Camp3'], size=n_touches)
channel_mt = np.random.choice(['paid_search', 'paid_social', 'provider_referral', 'affiliate'],
                              size=n_touches)
vendor_mt = np.random.choice(['Google', 'Meta', 'ProviderNetwork'], size=n_touches)
click_ts = [start_date + timedelta(days=int(np.random.randint(0, 365))) for _ in range(n_touches)]
cost = np.round(np.random.uniform(1, 15, size=n_touches), 2)

mkt_df = pd.DataFrame({
    'marketing_touch_id': mt_ids,
    'customer_id': customers_for_mt,
    'application_id': app_ids_for_mt,
    'campaign_id': campaign_id,
    'channel': channel_mt,
    'vendor': vendor_mt,
    'click_timestamp': click_ts,
    'cost_usd': cost
})

mkt_df.to_csv('raw_marketing.csv', index=False)

# -----------------------------
# 4. raw_events.csv
# -----------------------------
n_events = 4000
event_ids = [f"EV_{i:06d}" for i in range(1, n_events + 1)]
app_ids_for_ev = np.random.choice(application_ids, size=n_events, replace=True)
customers_for_ev = apps_df.set_index('application_id').loc[app_ids_for_ev, 'customer_id'].values
session_ids = [f"SESS_{np.random.randint(1, 2000):05d}" for _ in range(n_events)]

steps = ['page_view_application', 'application_started', 'application_submitted']
event_names = np.random.choice(steps, size=n_events, p=[0.4, 0.35, 0.25])

base_ts = [start_date + timedelta(days=int(np.random.randint(0, 365))) for _ in range(n_events)]
source_system_ev = np.random.choice(['web', 'mobile', 'heap', 'amplitude'], size=n_events)
device_vals = np.random.choice(['desktop', 'mobile'], size=n_events)
url_path_options = ['/apply', '/apply/step1', '/apply/step2']
url_paths = np.random.choice(url_path_options, size=n_events)

with open('raw_events.csv', 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['event_id', 'customer_id', 'session_id', 'application_id',
                     'event_name', 'event_timestamp', 'source_system', 'device', 'url_path'])
    for i in range(n_events):
        writer.writerow([
            event_ids[i],
            customers_for_ev[i],
            session_ids[i],
            app_ids_for_ev[i],
            event_names[i],
            base_ts[i].isoformat(sep=' '),
            source_system_ev[i],
            device_vals[i],
            url_paths[i]
        ])

print("Written raw_applications.csv, raw_loans.csv, raw_marketing.csv, raw_events.csv")
