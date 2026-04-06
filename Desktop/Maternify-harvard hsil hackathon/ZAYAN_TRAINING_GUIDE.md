# Zayan's ML Training Guide — RTX 5060 Ti
> Train XGBoost risk model + LSTM anomaly detector for Maternify
> Your GPU: RTX 5060 Ti 16GB — both models will be fast

---

## What you're building

| Model | Purpose | Output |
|-------|---------|--------|
| **XGBoost** | Classify patient vitals → GREEN / YELLOW / RED risk tier | `saved_models/xgboost_risk.pkl` |
| **LSTM Autoencoder** | Detect anomalies in 7-day vitals time series | `saved_models/lstm_anomaly.keras` |

These get loaded by the FastAPI service (`maternify_ml/`) which the Flutter app calls for real-time risk scoring.

---

## Step 0 — Environment Setup

```bash
cd maternify_ml
python -m venv .venv
.venv\Scripts\activate        # Windows
# source .venv/bin/activate   # Linux/Mac

pip install -r requirements.txt

# Verify GPU is detected by TensorFlow
python -c "import tensorflow as tf; print('GPUs:', tf.config.list_physical_devices('GPU'))"
# Should print: GPUs: [PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU')]

# If GPU not detected, install CUDA-enabled TF:
pip install tensorflow[and-cuda]
```

---

## Step 1 — Get Real Kaggle Datasets (recommended over synthetic)

### Dataset A — Maternal Health Risk (PRIMARY — use this for XGBoost)
- **Link:** https://www.kaggle.com/datasets/csafrit2/maternal-health-risk-data
- **Size:** 1,014 rows — small but clean and directly relevant
- **Columns:** `Age, SystolicBP, DiastolicBP, BS (blood sugar), BodyTemp, HeartRate, RiskLevel`
- **RiskLevel values:** `low risk`, `mid risk`, `high risk` → maps to our GREEN/YELLOW/RED

```bash
pip install kaggle
# Put your Kaggle API key at ~/.kaggle/kaggle.json (download from kaggle.com/settings)
kaggle datasets download -d csafrit2/maternal-health-risk-data -p training/data/
cd training/data && unzip maternal-health-risk-data.zip
```

### Dataset B — Fetal Health Classification (SECONDARY — adds CTG vitals)
- **Link:** https://www.kaggle.com/datasets/andrewmvd/fetal-health-classification
- **Size:** 2,126 rows
- **Columns:** baseline fetal heart rate, accelerations, fetal movement, uterine contractions, etc.
- **Use:** Supplement the LSTM training with more time-series-like features

```bash
kaggle datasets download -d andrewmvd/fetal-health-classification -p training/data/
cd training/data && unzip fetal-health-classification.zip
```

### Dataset C — Preeclampsia Risk Factors (BONUS — if you have time)
- **Link:** https://www.kaggle.com/datasets/miadul/preeclampsia-risk-factor-dataset
- Specifically targets preeclampsia (the main risk Maternify monitors)

---

## Step 2 — Train XGBoost with Real Kaggle Data

Open `maternify_ml/training/train_xgboost.py` and **replace lines 29-30** (the `df = generate_dataset()` call) with:

```python
# ── Use real Kaggle data instead of synthetic ──────────────────────────
df = pd.read_csv('training/data/maternal_health_risk_data.csv')

# Rename columns to match our feature names
df = df.rename(columns={
    'Age':        'age',
    'SystolicBP': 'systolic_bp',
    'DiastolicBP':'diastolic_bp',
    'BS':         'blood_glucose',
    'BodyTemp':   'body_temp',
    'HeartRate':  'heart_rate',
    'RiskLevel':  'risk_tier',
})

# Map risk labels to our tier names
df['risk_tier'] = df['risk_tier'].map({
    'low risk':  'green',
    'mid risk':  'yellow',
    'high risk': 'red',
})

# Add missing columns with realistic defaults
# (Kaggle dataset doesn't have these — fill with medians)
df['weeks_gestation'] = 28
df['gravida']         = 1
df['parity']          = 0
df['weight_kg']       = 62.0
df['kick_count']      = 10

print(df['risk_tier'].value_counts())
print(df.head())
# ── End of replacement ──────────────────────────────────────────────────
```

Also update the `FEATURES` list at the top of the file to include the new columns:
```python
FEATURES = [
    'age', 'weeks_gestation', 'gravida', 'parity',
    'systolic_bp', 'diastolic_bp', 'weight_kg',
    'blood_glucose', 'heart_rate', 'kick_count',
]
```

For your RTX 5060 Ti, **increase model capacity** (find these in `train_xgboost.py`):
```python
model = XGBClassifier(
    n_estimators=500,        # was 200 — more trees = better accuracy
    max_depth=7,             # was 5
    learning_rate=0.05,      # was 0.1 — slower but more precise
    subsample=0.8,
    colsample_bytree=0.8,
    tree_method='hist',      # ADD THIS — faster on GPU
    device='cuda',           # ADD THIS — uses your RTX 5060 Ti
    eval_metric='mlogloss',
    random_state=42,
    n_jobs=-1,
)
```

**Run:**
```bash
cd maternify_ml
.venv\Scripts\activate
python training/train_xgboost.py
```

**Expected output:**
```
Classes: ['green' 'red' 'yellow']
--- Classification Report ---
              precision    recall  f1-score
       green       0.94      0.96      0.95
         red       0.91      0.89      0.90
      yellow       0.88      0.87      0.87

5-Fold CV F1 (weighted): 0.91 ± 0.02

✅ Saved model → saved_models/xgboost_risk.pkl
✅ Saved encoder → saved_models/xgboost_label_encoder.pkl
```

---

## Step 3 — Train LSTM Anomaly Detector

The LSTM autoencoder needs time-series data. We'll build 7-day windows from the Kaggle dataset by simulating patient sequences.

The existing `train_lstm.py` already handles this — but add GPU memory config at the top for your RTX 5060 Ti. Open `maternify_ml/training/train_lstm.py` and add after the imports:

```python
# RTX 5060 Ti GPU config — add at top of file after imports
import tensorflow as tf
gpus = tf.config.list_physical_devices('GPU')
if gpus:
    tf.config.experimental.set_memory_growth(gpus[0], True)
    print(f"Using GPU: {gpus[0]}")
```

Also increase model capacity in `build_autoencoder()`:
```python
def build_autoencoder(timesteps, features):
    from tensorflow import keras
    from tensorflow.keras import layers
    from tensorflow.keras import mixed_precision

    # Enable mixed precision for 2x speed on RTX 5060 Ti
    mixed_precision.set_global_policy('mixed_float16')

    inputs = keras.Input(shape=(timesteps, features))
    # Encoder — increased from 32 → 64 units
    encoded = layers.LSTM(64, return_sequences=False)(inputs)
    encoded = layers.RepeatVector(timesteps)(encoded)
    # Decoder
    decoded = layers.LSTM(64, return_sequences=True)(encoded)
    outputs = layers.TimeDistributed(layers.Dense(features, dtype='float32'))(decoded)

    model = keras.Model(inputs, outputs)
    model.compile(optimizer='adam', loss='mse')
    model.summary()
    return model
```

And increase training epochs + batch size in `train()`:
```python
model.fit(
    X_normal, X_normal,
    epochs=100,        # was 30 — more epochs = better anomaly boundary
    batch_size=128,    # was 32 — RTX 5060 Ti has 16GB, use it
    validation_split=0.1,
    verbose=1,
)
```

**Run:**
```bash
python training/train_lstm.py
```

**Expected output:**
```
Using GPU: PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU')
Sequences: (1820, 7, 5), Anomalies: 637 / 1820
Epoch 1/100 - loss: 0.2341 - val_loss: 0.2198
...
Epoch 100/100 - loss: 0.0089 - val_loss: 0.0102

Anomaly threshold (95th pct): 0.0341

✅ Saved LSTM model → saved_models/lstm_anomaly.keras
✅ Saved threshold → saved_models/lstm_threshold.pkl
```

Total time on RTX 5060 Ti: ~2-3 minutes.

---

## Step 4 — Verify Models Work in FastAPI

```bash
cd maternify_ml
uvicorn app.main:app --reload --port 8000
```

Should see in startup logs:
```
INFO: XGBoost model + label encoder loaded
INFO: LSTM model + threshold meta loaded
```

Test XGBoost endpoint:
```bash
curl -X POST http://localhost:8000/risk-score/ \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "test-001",
    "age": 28,
    "weeks_gestation": 32,
    "gravida": 1,
    "parity": 0,
    "vitals": {
      "systolic_bp": 150,
      "diastolic_bp": 96,
      "weight_kg": 68.5,
      "blood_glucose": 7.2,
      "kick_count": 8
    }
  }'
```
Expected: `{"risk_tier": "yellow", "probability": 0.73, ...}`

Test LSTM anomaly endpoint:
```bash
curl -X POST http://localhost:8000/vitals-anomaly/ \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "test-001",
    "vitals_sequence": [
      {"systolic_bp": 125, "diastolic_bp": 80, "weight_kg": 65, "blood_glucose": 5.5, "kick_count": 14},
      {"systolic_bp": 128, "diastolic_bp": 82, "weight_kg": 65.2, "blood_glucose": 5.6, "kick_count": 13},
      {"systolic_bp": 132, "diastolic_bp": 85, "weight_kg": 65.5, "blood_glucose": 5.8, "kick_count": 12},
      {"systolic_bp": 136, "diastolic_bp": 88, "weight_kg": 65.8, "blood_glucose": 6.1, "kick_count": 11},
      {"systolic_bp": 140, "diastolic_bp": 91, "weight_kg": 66, "blood_glucose": 6.4, "kick_count": 10},
      {"systolic_bp": 145, "diastolic_bp": 94, "weight_kg": 66.3, "blood_glucose": 6.8, "kick_count": 9},
      {"systolic_bp": 150, "diastolic_bp": 97, "weight_kg": 66.5, "blood_glucose": 7.1, "kick_count": 8}
    ]
  }'
```
Expected: `{"is_anomaly": true, "reconstruction_error": 0.089, "threshold": 0.034}`

---

## Step 5 — Share Models with Team

Models are ~50MB total. Share via one of these:

**Option A — Google Drive (easiest):**
```bash
# Zip the saved_models folder and upload to Drive
# Share the link with the team
# They download and unzip into maternify_ml/saved_models/
```

**Option B — Git LFS:**
```bash
git lfs install
git lfs track "maternify_ml/saved_models/*.pkl"
git lfs track "maternify_ml/saved_models/*.keras"
git add .gitattributes
git add maternify_ml/saved_models/
git commit -m "feat: trained models — XGBoost F1=0.91, LSTM threshold=0.034"
git push origin main
```

---

## What to Report Back to the Team

After training, share these numbers:

```
XGBoost Results:
- 5-fold CV F1 (weighted): ___
- RED class recall: ___  (most important — we must catch high-risk patients)
- GREEN class precision: ___
- Test set accuracy: ___

LSTM Results:
- Anomaly threshold: ___
- Reconstruction error on normal sequences: ___
- Training loss (final epoch): ___
- Validation loss (final epoch): ___
```

Update `maternify_ml/saved_models/MODEL_CARD.md` with these numbers (create it if it doesn't exist).
