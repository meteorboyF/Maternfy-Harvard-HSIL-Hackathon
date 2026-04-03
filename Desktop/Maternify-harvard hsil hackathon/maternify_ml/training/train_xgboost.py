"""
Train XGBoost risk stratification model — F6
Run: python training/train_xgboost.py
Output: saved_models/xgboost_risk.pkl + saved_models/xgboost_label_encoder.pkl
"""

import joblib
import numpy as np
import pandas as pd
from pathlib import Path

from sklearn.model_selection import train_test_split, StratifiedKFold, cross_val_score
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import classification_report, confusion_matrix
from xgboost import XGBClassifier

from generate_synthetic_data import generate_dataset

FEATURES = [
    'age', 'weeks_gestation', 'gravida', 'parity',
    'systolic_bp', 'diastolic_bp', 'weight_kg',
    'blood_glucose', 'kick_count',
]
TARGET = 'risk_tier'

def train():
    print("=== Maternify XGBoost Risk Model Training ===\n")

    # 1. Data
    df = generate_dataset()
    X = df[FEATURES].values
    le = LabelEncoder()
    y = le.fit_transform(df[TARGET])   # green=0, red=1, yellow=2 (sorted)
    print(f"\nClasses: {le.classes_}")

    # 2. Split
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    # 3. Train
    model = XGBClassifier(
        n_estimators=200,
        max_depth=5,
        learning_rate=0.1,
        subsample=0.8,
        colsample_bytree=0.8,
        use_label_encoder=False,
        eval_metric='mlogloss',
        random_state=42,
        n_jobs=-1,
    )
    model.fit(
        X_train, y_train,
        eval_set=[(X_test, y_test)],
        verbose=50,
    )

    # 4. Evaluate
    y_pred = model.predict(X_test)
    print("\n--- Classification Report ---")
    print(classification_report(y_test, y_pred, target_names=le.classes_))
    print("Confusion Matrix:")
    print(confusion_matrix(y_test, y_pred))

    # 5. Cross-validation
    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
    cv_scores = cross_val_score(model, X, y, cv=cv, scoring='f1_weighted')
    print(f"\n5-Fold CV F1 (weighted): {cv_scores.mean():.3f} ± {cv_scores.std():.3f}")

    # 6. Save
    out_dir = Path(__file__).parent.parent / 'saved_models'
    out_dir.mkdir(exist_ok=True)
    joblib.dump(model, out_dir / 'xgboost_risk.pkl')
    joblib.dump(le, out_dir / 'xgboost_label_encoder.pkl')
    print(f"\n✅ Saved model → {out_dir}/xgboost_risk.pkl")
    print(f"✅ Saved encoder → {out_dir}/xgboost_label_encoder.pkl")

if __name__ == '__main__':
    train()
