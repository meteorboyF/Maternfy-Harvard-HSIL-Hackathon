"""
Generate synthetic maternal vitals dataset for XGBoost training.
Produces ~2000 samples with realistic preeclampsia risk labels.
Run: python training/generate_synthetic_data.py
Output: training/data/maternal_vitals.csv
"""

import numpy as np
import pandas as pd
from pathlib import Path

np.random.seed(42)
N = 2000

def generate_dataset():
    rows = []
    for i in range(N):
        is_risk = np.random.random() < 0.35   # 35% risk cases

        age = int(np.random.normal(28, 6))
        age = max(15, min(45, age))
        weeks = int(np.random.uniform(20, 40))
        gravida = int(np.random.choice([1, 2, 3, 4], p=[0.4, 0.3, 0.2, 0.1]))
        parity = max(0, gravida - 1)

        if is_risk:
            systolic  = int(np.random.normal(148, 12))
            diastolic = int(np.random.normal(96, 8))
            glucose   = round(np.random.normal(7.2, 1.1), 1)
            weight    = round(np.random.normal(72, 10), 1)
            kicks     = int(np.random.normal(8, 4))
        else:
            systolic  = int(np.random.normal(112, 10))
            diastolic = int(np.random.normal(74, 6))
            glucose   = round(np.random.normal(5.2, 0.7), 1)
            weight    = round(np.random.normal(62, 8), 1)
            kicks     = int(np.random.normal(14, 4))

        systolic  = max(80, min(200, systolic))
        diastolic = max(50, min(130, diastolic))
        glucose   = max(3.0, min(15.0, glucose))
        weight    = max(40.0, min(110.0, weight))
        kicks     = max(0, min(30, kicks))

        # Rule-based label: green / yellow / red
        if systolic >= 160 or diastolic >= 110 or (is_risk and glucose > 8.5):
            label = 'red'
        elif systolic >= 140 or diastolic >= 90 or (is_risk and glucose > 7.0):
            label = 'yellow'
        else:
            label = 'green'

        rows.append({
            'age': age,
            'weeks_gestation': weeks,
            'gravida': gravida,
            'parity': parity,
            'systolic_bp': systolic,
            'diastolic_bp': diastolic,
            'weight_kg': weight,
            'blood_glucose': glucose,
            'kick_count': kicks,
            'risk_tier': label,
        })

    df = pd.DataFrame(rows)
    out = Path(__file__).parent / 'data' / 'maternal_vitals.csv'
    out.parent.mkdir(exist_ok=True)
    df.to_csv(out, index=False)
    print(f"Generated {N} samples → {out}")
    print(df['risk_tier'].value_counts())
    return df

if __name__ == '__main__':
    generate_dataset()
