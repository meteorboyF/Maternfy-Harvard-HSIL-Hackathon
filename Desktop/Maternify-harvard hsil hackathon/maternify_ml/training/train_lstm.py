"""
Train LSTM anomaly detection model — F7
7-day rolling window on vitals. Uses autoencoder architecture —
reconstruction error above threshold = anomaly.
Run: python training/train_lstm.py
Output: saved_models/lstm_anomaly.keras + saved_models/lstm_threshold.pkl
"""

import joblib
import numpy as np
import pandas as pd
from pathlib import Path

from generate_synthetic_data import generate_dataset

VITALS_COLS = ['systolic_bp', 'diastolic_bp', 'weight_kg', 'blood_glucose', 'kick_count']
WINDOW = 7    # days

def build_sequences(df, window=WINDOW):
    """Slide a window over sorted vitals to build (N, window, features) array."""
    sequences = []
    labels = []
    for _, grp in df.groupby('patient_sim_id'):
        grp = grp.sort_values('day')
        vals = grp[VITALS_COLS].values
        tier = grp['risk_tier'].values
        for i in range(len(vals) - window + 1):
            sequences.append(vals[i:i+window])
            # Anomaly = any red day in window
            labels.append(1 if 'red' in tier[i:i+window] else 0)
    return np.array(sequences, dtype=np.float32), np.array(labels)

def simulate_time_series(df, days=14):
    """Attach a fake patient_sim_id and day column for sequence building."""
    rows = []
    for pid in range(len(df) // days):
        for day in range(days):
            idx = pid * days + day
            if idx >= len(df): break
            row = df.iloc[idx].to_dict()
            row['patient_sim_id'] = pid
            row['day'] = day
            rows.append(row)
    return pd.DataFrame(rows)

def build_autoencoder(timesteps, features):
    """LSTM autoencoder — encoder compresses, decoder reconstructs."""
    try:
        from tensorflow import keras
        from tensorflow.keras import layers
    except ImportError:
        print("TensorFlow not installed — skipping LSTM training (stub will be used)")
        return None

    inputs = keras.Input(shape=(timesteps, features))
    # Encoder
    encoded = layers.LSTM(32, return_sequences=False)(inputs)
    encoded = layers.RepeatVector(timesteps)(encoded)
    # Decoder
    decoded = layers.LSTM(32, return_sequences=True)(encoded)
    outputs = layers.TimeDistributed(layers.Dense(features))(decoded)

    model = keras.Model(inputs, outputs)
    model.compile(optimizer='adam', loss='mse')
    return model

def train():
    print("=== Maternify LSTM Anomaly Detector Training ===\n")

    df = generate_dataset()
    ts_df = simulate_time_series(df)
    X, y = build_sequences(ts_df)

    if len(X) == 0:
        print("Not enough data for sequences — increase dataset size")
        return

    print(f"Sequences: {X.shape}, Anomalies: {y.sum()} / {len(y)}")

    # Normalise
    mean = X.mean(axis=(0, 1), keepdims=True)
    std  = X.std(axis=(0, 1), keepdims=True) + 1e-8
    X_norm = (X - mean) / std

    # Train only on normal sequences (autoencoder unsupervised)
    X_normal = X_norm[y == 0]

    model = build_autoencoder(WINDOW, len(VITALS_COLS))
    if model is None:
        return

    model.fit(
        X_normal, X_normal,
        epochs=30,
        batch_size=32,
        validation_split=0.1,
        verbose=1,
    )

    # Determine reconstruction error threshold (95th percentile on normal)
    recon = model.predict(X_normal, verbose=0)
    errors = np.mean(np.abs(recon - X_normal), axis=(1, 2))
    threshold = float(np.percentile(errors, 95))
    print(f"\nAnomaly threshold (95th pct): {threshold:.4f}")

    out_dir = Path(__file__).parent.parent / 'saved_models'
    out_dir.mkdir(exist_ok=True)
    model.save(out_dir / 'lstm_anomaly.keras')
    joblib.dump({
        'threshold': threshold,
        'mean': mean,
        'std': std,
        'vitals_cols': VITALS_COLS,
        'window': WINDOW,
    }, out_dir / 'lstm_threshold.pkl')
    print(f"✅ Saved LSTM model → {out_dir}/lstm_anomaly.keras")
    print(f"✅ Saved threshold → {out_dir}/lstm_threshold.pkl")

if __name__ == '__main__':
    train()
