"""
Maternify — Master training script
Trains both XGBoost and LSTM models in sequence.
Automatically detects GPU and adjusts batch size / model capacity.

Run from PyCharm: right-click → Run 'train_all'
Or terminal: python training/train_all.py

Flags:
  --xgb-only     Train only XGBoost
  --lstm-only    Train only LSTM
  --kaggle       Use Kaggle maternal health dataset (must be in training/data/)
  --epochs N     LSTM epochs (default: 30 on CPU/GTX, 100 on RTX 5060 Ti)
"""

import argparse
import os
import sys
import time
from pathlib import Path

# Add parent to path so imports work from PyCharm
sys.path.insert(0, str(Path(__file__).parent))

def detect_gpu():
    """Returns (has_gpu, vram_gb, gpu_name)"""
    try:
        import tensorflow as tf
        gpus = tf.config.list_physical_devices('GPU')
        if not gpus:
            return False, 0, "CPU"
        tf.config.experimental.set_memory_growth(gpus[0], True)
        # Try to get GPU name
        try:
            from tensorflow.python.client import device_lib
            for d in device_lib.list_local_devices():
                if d.device_type == 'GPU':
                    name = d.physical_device_desc
                    vram = d.memory_limit / (1024**3)
                    return True, round(vram, 1), name
        except Exception:
            pass
        return True, 0, "Unknown GPU"
    except ImportError:
        return False, 0, "CPU (TensorFlow not installed)"


def train_xgboost(use_kaggle=False):
    print("\n" + "="*50)
    print("STEP 1: XGBoost Risk Model")
    print("="*50)
    start = time.time()

    import numpy as np
    import pandas as pd
    import joblib
    from sklearn.model_selection import train_test_split
    from sklearn.preprocessing import LabelEncoder
    from sklearn.metrics import classification_report
    from xgboost import XGBClassifier

    DATA_DIR = Path(__file__).parent / 'data'
    MODEL_DIR = Path(__file__).parent.parent / 'saved_models'
    MODEL_DIR.mkdir(exist_ok=True)

    FEATURES = ['age','weeks_gestation','gravida','parity',
                'systolic_bp','diastolic_bp','weight_kg','blood_glucose','kick_count']

    if use_kaggle:
        csv = DATA_DIR / 'Maternal Health Risk Data Set.csv'
        if not csv.exists():
            print(f"ERROR: Kaggle dataset not found at {csv}")
            print("Download: kaggle datasets download -d csafrit2/maternal-health-risk-data")
            return
        df = pd.read_csv(csv)
        df = df.rename(columns={
            'Age': 'age', 'SystolicBP': 'systolic_bp', 'DiastolicBP': 'diastolic_bp',
            'BS': 'blood_glucose', 'RiskLevel': 'risk_tier',
        })
        df['weeks_gestation'] = 30
        df['gravida'] = 1
        df['parity'] = 0
        df['weight_kg'] = 60.0
        df['kick_count'] = 10
    else:
        from generate_synthetic_data import generate_dataset
        df = generate_dataset()

    print(f"Dataset: {len(df)} samples")
    print(df['risk_tier'].value_counts())

    le = LabelEncoder()
    y = le.fit_transform(df['risk_tier'])
    X = df[FEATURES].values

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

    model = XGBClassifier(
        n_estimators=300, max_depth=5, learning_rate=0.08,
        subsample=0.8, colsample_bytree=0.8,
        eval_metric='mlogloss', random_state=42, n_jobs=-1,
    )
    model.fit(X_train, y_train, eval_set=[(X_test, y_test)], verbose=100)

    y_pred = model.predict(X_test)
    print("\n" + classification_report(y_test, y_pred, target_names=le.classes_))

    joblib.dump(model, MODEL_DIR / 'xgboost_risk.pkl')
    joblib.dump(le, MODEL_DIR / 'xgboost_label_encoder.pkl')
    print(f"✅ XGBoost saved ({time.time()-start:.1f}s)")


def train_lstm(has_gpu, vram_gb, epochs=None):
    print("\n" + "="*50)
    print(f"STEP 2: LSTM Anomaly Detector  [GPU={has_gpu}, VRAM={vram_gb}GB]")
    print("="*50)

    try:
        import tensorflow as tf
    except ImportError:
        print("TensorFlow not installed — skipping LSTM training")
        print("Install: pip install tensorflow")
        return

    # Auto-configure based on GPU
    if vram_gb >= 12:  # RTX 5060 Ti
        lstm_units = 64
        batch_size = 128
        default_epochs = 100
        print("RTX 5060 Ti detected — using full model capacity")
        # Enable mixed precision
        from tensorflow.keras import mixed_precision
        mixed_precision.set_global_policy('mixed_float16')
    elif vram_gb >= 4:  # GTX 1060
        lstm_units = 32
        batch_size = 32
        default_epochs = 50
        print("GTX 1060 detected — using standard model capacity")
    else:  # CPU
        lstm_units = 32
        batch_size = 32
        default_epochs = 30
        print("CPU mode — training will be slower")

    if epochs:
        default_epochs = epochs

    start = time.time()
    import numpy as np
    import pandas as pd
    import joblib
    from generate_synthetic_data import generate_dataset
    from tensorflow import keras
    from tensorflow.keras import layers

    VITALS_COLS = ['systolic_bp', 'diastolic_bp', 'weight_kg', 'blood_glucose', 'kick_count']
    WINDOW = 7
    MODEL_DIR = Path(__file__).parent.parent / 'saved_models'
    MODEL_DIR.mkdir(exist_ok=True)

    df = generate_dataset()

    # Simulate time-series
    rows = []
    for pid in range(len(df) // 14):
        for day in range(14):
            idx = pid * 14 + day
            if idx >= len(df): break
            row = df.iloc[idx].to_dict()
            row['patient_sim_id'] = pid
            row['day'] = day
            rows.append(row)
    ts_df = pd.DataFrame(rows)

    # Build windows
    seqs, labels = [], []
    for _, grp in ts_df.groupby('patient_sim_id'):
        grp = grp.sort_values('day')
        vals = grp[VITALS_COLS].values
        tier = grp['risk_tier'].values
        for i in range(len(vals) - WINDOW + 1):
            seqs.append(vals[i:i+WINDOW])
            labels.append(1 if 'red' in tier[i:i+WINDOW] else 0)

    X = np.array(seqs, dtype=np.float32)
    y = np.array(labels)
    print(f"Sequences: {X.shape}, Anomalies: {y.sum()}/{len(y)}")

    mean = X.mean(axis=(0,1), keepdims=True)
    std  = X.std(axis=(0,1), keepdims=True) + 1e-8
    X_norm = (X - mean) / std
    X_normal = X_norm[y == 0]

    # Build autoencoder
    inp = keras.Input(shape=(WINDOW, len(VITALS_COLS)))
    x = layers.LSTM(lstm_units, return_sequences=False)(inp)
    x = layers.RepeatVector(WINDOW)(x)
    x = layers.LSTM(lstm_units, return_sequences=True)(x)
    out = layers.TimeDistributed(layers.Dense(len(VITALS_COLS)))(x)
    model = keras.Model(inp, out)
    model.compile(optimizer='adam', loss='mse')
    model.summary()

    history = model.fit(
        X_normal, X_normal,
        epochs=default_epochs, batch_size=batch_size,
        validation_split=0.1, verbose=1,
    )

    recon = model.predict(X_normal, verbose=0)
    errors = np.mean(np.abs(recon - X_normal), axis=(1,2))
    threshold = float(np.percentile(errors, 95))
    print(f"\nAnomaly threshold (95th pct): {threshold:.4f}")

    model.save(MODEL_DIR / 'lstm_anomaly.keras')
    joblib.dump({
        'threshold': threshold, 'mean': mean, 'std': std,
        'vitals_cols': VITALS_COLS, 'window': WINDOW,
    }, MODEL_DIR / 'lstm_threshold.pkl')
    print(f"✅ LSTM saved ({time.time()-start:.1f}s)")


def main():
    parser = argparse.ArgumentParser(description='Maternify model trainer')
    parser.add_argument('--xgb-only',  action='store_true')
    parser.add_argument('--lstm-only', action='store_true')
    parser.add_argument('--kaggle',    action='store_true', help='Use Kaggle dataset for XGBoost')
    parser.add_argument('--epochs',    type=int, default=None, help='LSTM epochs override')
    args = parser.parse_args()

    print("╔══════════════════════════════════╗")
    print("║  Maternify ML Training Pipeline  ║")
    print("╚══════════════════════════════════╝")

    has_gpu, vram_gb, gpu_name = detect_gpu()
    print(f"\nCompute: {gpu_name} ({vram_gb}GB VRAM)")

    if not args.lstm_only:
        train_xgboost(use_kaggle=args.kaggle)

    if not args.xgb_only:
        train_lstm(has_gpu, vram_gb, epochs=args.epochs)

    print("\n🎉 All models trained! Start the FastAPI service:")
    print("   uvicorn app.main:app --reload --port 8000")


if __name__ == '__main__':
    main()
