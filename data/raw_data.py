import os
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
import random

np.random.seed(42)
random.seed(42)

OUT_DIR = "./data/csv"
os.makedirs(OUT_DIR, exist_ok=True)

# -----------------------
# 1. Static reference data
# -----------------------

SNAPSHOT_DATES = [
    pd.Timestamp("2023-01-01"),
    pd.Timestamp("2024-01-01")
]

HOSPITALS = [
    "North Valley Medical Center",
    "Eastside Community Hospital",
    "Lakeshore Surgical Institute",
    "Pinecrest Rural Hospital"
]

NJ_ZIPS = [
    "07054", "07960", "07052", "07039",
    "07006", "07044", "07042", "07003"
]

PAYORS = [
    ("UnitedHealthcare", "Commercial"),
    ("Blue Cross", "Commercial"),
    ("Medicare", "Government"),
    ("Medicaid", "Government"),
    ("Self-Pay", "Self-Pay")
]

SPECIALTIES = [
    "General Surgery", "Orthopedics", "Neurosurgery",
    "Cardiothoracic", "ENT", "Urology", "Gynecology"
]

ANESTHESIA_TYPES = ["General", "Regional", "MAC", "Local"]
ASA_CLASSES = [1, 2, 3, 4]

ICD10_CODES = [
    "K35.80", "K40.20", "M17.11", "N20.0",
    "K80.20", "S83.511A", "M48.061"
]

CPT_CODES = [
    ("44970", 18.0),
    ("49505", 16.0),
    ("29881", 15.0),
    ("52356", 19.0),
    ("47562", 20.0),
    ("29888", 22.0),
    ("63047", 24.0)
]

LOINC_CODES = ["718-7", "4548-4", "6690-2", "2951-2", "2345-7"]

RXNORM_CODES = [
    ("Ketorolac", "RX100001"),
    ("Cefazolin", "RX100002"),
    ("Heparin", "RX100003"),
    ("Propofol", "RX100004"),
    ("Ondansetron", "RX100005")
]

# -----------------------
# 2. Helpers
# -----------------------

def make_row_status(n):
    return np.random.choice(["0", "-1", "-2", "-3"], size=n, p=[0.9, 0.05, 0.03, 0.02])

def to_varchar(df: pd.DataFrame) -> pd.DataFrame:
    for c in df.columns:
        df[c] = df[c].astype(str)
    return df

# -----------------------
# NEW REALISTIC ADMIT TIME GENERATOR
# -----------------------

def generate_realistic_admit_times(start, end, n):
    dates = []
    current = start

    weekday_weights = {
        0: 1.3,  # Monday
        1: 1.25, # Tuesday
        2: 1.2,  # Wednesday
        3: 1.15, # Thursday
        4: 0.9,  # Friday
        5: 0.35, # Saturday
        6: 0.30  # Sunday
    }

    seasonal_weights = {
        1: 1.15, 2: 1.10, 12: 1.20,
        6: 0.85, 7: 0.80, 8: 0.90
    }

    all_days = pd.date_range(start, end, freq="D")
    day_weights = []

    for d in all_days:
        w = weekday_weights[d.weekday()]
        w *= seasonal_weights.get(d.month, 1.0)
        day_weights.append(w)

    day_weights = np.array(day_weights)
    day_weights = day_weights / day_weights.sum()

    sampled_days = np.random.choice(all_days, size=n, p=day_weights)

    admit_times = []
    for d in sampled_days:
        hour = np.random.normal(loc=9.5, scale=2.5)
        hour = np.clip(hour, 6, 17)
        minute = np.random.randint(0, 60)
        admit_times.append(d + pd.Timedelta(hours=hour, minutes=minute))

    return pd.to_datetime(admit_times)

# -----------------------
# 3. Dimensions
# -----------------------

def build_hospital_dim():
    rows = []
    for snap in SNAPSHOT_DATES:
        for i, name in enumerate(HOSPITALS, start=1):
            rows.append({
                "HospitalDurableKey": i,
                "HospitalName": name,
                "SnapshotDateTime": snap,
                "RowStatus": "0"
            })
    return to_varchar(pd.DataFrame(rows))

def build_payor_dim():
    rows = []
    for snap in SNAPSHOT_DATES:
        for i, (name, ptype) in enumerate(PAYORS, start=1):
            rows.append({
                "PayorDurableKey": i,
                "PayorName": name,
                "PayorType": ptype,
                "SnapshotDateTime": snap,
                "RowStatus": "0"
            })
    return to_varchar(pd.DataFrame(rows))

def build_provider_dim(n_providers=24):
    rows = []
    for snap in SNAPSHOT_DATES:
        for pid in range(1, n_providers + 1):
            rows.append({
                "ProviderDurableKey": pid,
                "ProviderName": f"Surgeon {pid}",
                "Specialty": random.choice(SPECIALTIES),
                "SnapshotDateTime": snap,
                "RowStatus": "0"
            })
    return to_varchar(pd.DataFrame(rows))

def build_patient_dim(n_patients=50000):
    rows = []
    genders = ["M", "F", "O"]
    for snap in SNAPSHOT_DATES:
        for pid in range(1, n_patients + 1):
            dob = datetime(1940, 1, 1) + timedelta(days=int(np.random.randint(0, 80*365)))
            rows.append({
                "PatientDurableKey": pid,
                "Gender": random.choice(genders),
                "DOB": dob.date().isoformat(),
                "ZipCode": random.choice(NJ_ZIPS),
                "SnapshotDateTime": snap,
                "RowStatus": "0"
            })
    return to_varchar(pd.DataFrame(rows))

# -----------------------
# 4. EncounterFact
# -----------------------

def build_encounter_fact(n_encounters=150000):
    start = pd.Timestamp("2022-01-01")
    end = pd.Timestamp("2024-12-31")

    encounter_ids = np.arange(1, n_encounters + 1)
    patient_ids = np.random.randint(1, 50000, size=n_encounters)
    hospital_ids = np.random.randint(1, len(HOSPITALS) + 1, size=n_encounters)
    provider_ids = np.random.randint(1, 24 + 1, size=n_encounters)
    payor_ids = np.random.randint(1, len(PAYORS) + 1, size=n_encounters)

    admit_times = generate_realistic_admit_times(start, end, n_encounters)

    month = admit_times.month
    seasonal_multiplier = np.where(month.isin([12,1,2]), 1.2,
                            np.where(month.isin([6,7,8]), 0.8, 1.0))
    base_hours = np.random.randint(1, 72, size=n_encounters)
    surgery_starts = admit_times + pd.to_timedelta(base_hours * seasonal_multiplier, unit="h")

    hospital_complexity = {1: 1.2, 2: 1.0, 3: 1.1, 4: 0.8}
    base_duration = np.random.normal(loc=120, scale=40, size=n_encounters).clip(30, 480)
    duration_adj = np.array([hospital_complexity[h] for h in hospital_ids])
    durations_min = base_duration * duration_adj
    surgery_ends = surgery_starts + pd.to_timedelta(durations_min, unit="m")

    asa = np.random.choice(ASA_CLASSES, size=n_encounters, p=[0.1, 0.4, 0.35, 0.15])
    anesthesia = np.random.choice(ANESTHESIA_TYPES, size=n_encounters)

    snapshot = pd.Timestamp("2024-12-31")

    df = pd.DataFrame({
        "EncounterDurableKey": encounter_ids,
        "PatientDurableKey": patient_ids,
        "HospitalDurableKey": hospital_ids,
        "SurgeonDurableKey": provider_ids,
        "PayorDurableKey": payor_ids,

        "AdmitDateTime": admit_times.strftime("%Y-%m-%d %H:%M:%S"),
        "SurgeryStart": surgery_starts.strftime("%Y-%m-%d %H:%M:%S"),
        "SurgeryEnd": surgery_ends.strftime("%Y-%m-%d %H:%M:%S"),

        "ASAClass": asa,
        "AnesthesiaType": anesthesia,
        "SnapshotDateTime": snapshot.strftime("%Y-%m-%d %H:%M:%S"),
        "RowStatus": make_row_status(n_encounters)
    })
    return to_varchar(df)

# -----------------------
# 5. ProcedureFact
# -----------------------

def build_procedure_fact(encounters_df, n_procedures=200000):
    encounter_keys = np.random.choice(encounters_df["EncounterDurableKey"].astype(int), size=n_procedures, replace=True)
    proc_ids = np.arange(1, n_procedures + 1)

    cpt_choices = [c[0] for c in CPT_CODES]
    cpt_to_rvu = {c: rvu for c, rvu in CPT_CODES}
    cpt_assigned = np.random.choice(cpt_choices, size=n_procedures, replace=True)
    total_rvu = [cpt_to_rvu[c] + np.random.normal(0, 1) for c in cpt_assigned]
    total_rvu = np.round(np.clip(total_rvu, 5, 40), 1)

    primary_flags = np.random.choice(["0", "1"], size=n_procedures, p=[0.6, 0.4])

    df = pd.DataFrame({
        "ProcedureDurableKey": proc_ids,
        "EncounterDurableKey": encounter_keys,
        "CPTCode": cpt_assigned,
        "PrimaryProcedureFlag": primary_flags,
        "TotalRVU": total_rvu,
        "SnapshotDateTime": "2024-12-31 00:00:00",
        "RowStatus": make_row_status(n_procedures)
    })
    return to_varchar(df)

# -----------------------
# 6. DiagnosisFact
# -----------------------

def build_diagnosis_fact(encounters_df, n_dx=150000):
    encounter_keys = np.random.choice(encounters_df["EncounterDurableKey"].astype(int), size=n_dx, replace=True)
    dx_ids = np.arange(1, n_dx + 1)
    icd_assigned = np.random.choice(ICD10_CODES, size=n_dx, replace=True)

    df = pd.DataFrame({
        "DiagnosisDurableKey": dx_ids,
        "EncounterDurableKey": encounter_keys,
        "ICD10Code": icd_assigned,
        "SnapshotDateTime": "2024-12-31 00:00:00",
        "RowStatus": make_row_status(n_dx)
    })
    return to_varchar(df)

# -----------------------
# 7. MedicationFact
# -----------------------

def build_medication_fact(encounters_df, n_meds=120000):
    encounter_keys = np.random.choice(encounters_df["EncounterDurableKey"].astype(int), size=n_meds, replace=True)
    med_ids = np.arange(1, n_meds + 1)
    names = [m[0] for m in RXNORM_CODES]
    codes = {m[0]: m[1] for m in RXNORM_CODES}
    med_names = np.random.choice(names, size=n_meds, replace=True)
    rxnorm_codes = [codes[n] for n in med_names]

    df = pd.DataFrame({
        "MedicationDurableKey": med_ids,
        "EncounterDurableKey": encounter_keys,
        "RxNormCode": rxnorm_codes,
        "SnapshotDateTime": "2024-12-31 00:00:00",
        "RowStatus": make_row_status(n_meds)
    })
    return to_varchar(df)

# -----------------------
# 8. LabResultFact
# -----------------------

def build_lab_result_fact(encounters_df, n_labs=250000):
    encounter_keys = np.random.choice(encounters_df["EncounterDurableKey"].astype(int), size=n_labs, replace=True)
    lab_ids = np.arange(1, n_labs + 1)
    loinc_assigned = np.random.choice(LOINC_CODES, size=n_labs, replace=True)

    values = []
    flags = []
    for code in loinc_assigned:
        if code == "718-7":
            v = np.random.normal(13.5, 1.5)
            f = "N" if 12 <= v <= 16 else ("L" if v < 12 else "H")
        elif code == "6690-2":
            v = np.random.normal(8, 3)
            f = "N" if 4 <= v <= 11 else ("L" if v < 4 else "H")
        elif code == "2951-2":
            v = np.random.normal(140, 4)
            f = "N" if 135 <= v <= 145 else ("L" if v < 135 else "H")
        elif code == "2345-7":
            v = np.random.normal(110, 30)
            f = "N" if 70 <= v <= 140 else ("L" if v < 70 else "H")
        else:
            v = np.random.normal(40, 5)
            f = "N"
        values.append(round(v, 1))
        flags.append(f)

    df = pd.DataFrame({
        "LabResultDurableKey": lab_ids,
        "EncounterDurableKey": encounter_keys,
        "LOINCCode": loinc_assigned,
        "ResultValue": values,
        "ResultFlag": flags,
        "SnapshotDateTime": "2024-12-31 00:00:00",
        "RowStatus": make_row_status(n_labs)
    })
    return to_varchar(df)

# -----------------------
# 9. Main
# -----------------------

def main():
    hospital_dim = build_hospital_dim()
    payor_dim = build_payor_dim()
    provider_dim = build_provider_dim()
    patient_dim = build_patient_dim()

    encounter_fact = build_encounter_fact()
    procedure_fact = build_procedure_fact(encounter_fact)
    diagnosis_fact = build_diagnosis_fact(encounter_fact)
    medication_fact = build_medication_fact(encounter_fact)
    labresult_fact = build_lab_result_fact(encounter_fact)

    hospital_dim.to_csv(f"{OUT_DIR}/HospitalDim.csv", index=False)
    payor_dim.to_csv(f"{OUT_DIR}/PayorDim.csv", index=False)
    provider_dim.to_csv(f"{OUT_DIR}/ProviderDim.csv", index=False)
    patient_dim.to_csv(f"{OUT_DIR}/PatientDim.csv", index=False)

    encounter_fact.to_csv(f"{OUT_DIR}/EncounterFact.csv", index=False)
    procedure_fact.to_csv(f"{OUT_DIR}/ProcedureFact.csv", index=False)
    diagnosis_fact.to_csv(f"{OUT_DIR}/DiagnosisFact.csv", index=False)
    medication_fact.to_csv(f"{OUT_DIR}/MedicationFact.csv", index=False)
    labresult_fact.to_csv(f"{OUT_DIR}/LabResultFact.csv", index=False)

    print("CSV generation complete.")

if __name__ == "__main__":
    main()
