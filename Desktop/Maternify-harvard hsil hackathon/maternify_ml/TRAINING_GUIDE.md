# Maternify ML Training Guide

## Hardware Setup

| Machine | GPU | VRAM | Best for |
|---------|-----|------|----------|
| Your machine | GTX 1060 6GB | 6GB | XGBoost, data prep, quick LSTM tests |
| Zayan's machine | RTX 5060 Ti 16GB | 16GB | Full LSTM training, larger models |

---

## Step 0 — Environment Setup (both machines)

```bash
# Create and activate venv
cd maternify_ml
python -m venv .venv

# Windows
.venv\Scripts\activate

# Install all dependencies
pip install -r requirements.txt

# Verify GPU (for LSTM training)
python -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
```

**PyCharm setup:**
1. Open `maternify_ml/` as project root
2. Settings → Python Interpreter → Add → Existing → select `.venv/Scripts/python.exe`
3. Mark `training/` as Sources Root (right-click → Mark Directory as → Sources Root)

---

## Step 1 — Generate Synthetic Training Data

```bash
cd maternify_ml
python training/generate_synthetic_data.py
```

Output: `training/data/maternal_vitals.csv` (~2000 rows)

**Alternatively — use real open datasets (recommended for demo):**

| Dataset | Link | Use |
|---------|------|-----|
| MIMIC-III maternal subset | https://physionet.org/content/mimiciii/1.4/ | Vitals time-series (requires credentialing) |
| CDC PRAMS (maternal health) | https://www.cdc.gov/prams/index.htm | Epidemiology features |
| Kaggle: Maternal Health Risk | https://www.kaggle.com/datasets/csafrit2/maternal-health-risk-data | Direct drop-in for XGBoost (small, clean) |
| Kaggle: Fetal Health (CTG) | https://www.kaggle.com/datasets/andrewmvd/fetal-health-classification | Kick count + vitals → risk classification |

**Easiest Kaggle dataset to use (no credentialing):**
```bash
pip install kaggle
kaggle datasets download -d csafrit2/maternal-health-risk-data
unzip maternal-health-risk-data.zip -d training/data/
```

The Kaggle maternal health risk CSV has columns:
`Age, SystolicBP, DiastolicBP, BS (blood sugar), BodyTemp, HeartRate, RiskLevel`
→ maps directly to our feature set.

---

## Step 2 — Train XGBoost Risk Model (your GTX 1060 / CPU)

XGBoost runs on CPU — GPU not needed. ~30 seconds.

```bash
python training/train_xgboost.py
```

Output:
- `saved_models/xgboost_risk.pkl`
- `saved_models/xgboost_label_encoder.pkl`

Expected performance (synthetic data):
- F1 (weighted) ~0.92–0.95
- Red class recall ~0.89+

**If using Kaggle dataset**, edit `train_xgboost.py` line 18:
```python
df = pd.read_csv('training/data/Maternal Health Risk Data Set.csv')
df = df.rename(columns={
    'Age': 'age',
    'SystolicBP': 'systolic_bp',
    'DiastolicBP': 'diastolic_bp',
    'BS': 'blood_glucose',
    'RiskLevel': 'risk_tier',
})
df['weeks_gestation'] = 30  # not in dataset — use median
df['gravida'] = 1
df['parity'] = 0
df['weight_kg'] = 60.0
df['kick_count'] = 10
```

---

## Step 3 — Train LSTM Anomaly Detector (Zayan's RTX 5060 Ti — recommended)

LSTM autoencoder benefits significantly from GPU. 30 epochs on 2000 samples:
- CPU: ~8 minutes
- GTX 1060: ~90 seconds
- RTX 5060 Ti: ~20 seconds

```bash
# On Zayan's machine (RTX 5060 Ti)
python training/train_lstm.py
```

Output:
- `saved_models/lstm_anomaly.keras`
- `saved_models/lstm_threshold.pkl`

**Transfer the saved_models/ files** back to your machine (or shared network drive / git LFS).

### Increase model capacity on RTX 5060 Ti

Edit `train_lstm.py`, in `build_autoencoder()`:
```python
encoded = layers.LSTM(64, return_sequences=False)(inputs)   # 32 → 64
decoded = layers.LSTM(64, return_sequences=True)(encoded)   # 32 → 64
```

Also increase epochs:
```python
model.fit(..., epochs=100, ...)
```

16GB VRAM means you can also increase batch size:
```python
model.fit(..., batch_size=128, ...)  # 32 → 128
```

---

## Step 4 — Verify Models Load in FastAPI

```bash
uvicorn app.main:app --reload --port 8000
```

On startup you should see:
```
INFO:     XGBoost model + label encoder loaded
INFO:     LSTM model + threshold meta loaded
```

Test the endpoints:
```bash
# XGBoost risk score
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

# Expected: {"risk_tier": "yellow", "probability": 0.73, "shap_features": [...]}
```

---

## Step 5 — GPU Memory Tips

### GTX 1060 (6GB)
- TensorFlow may OOM on large batches. If it crashes:
  ```python
  import tensorflow as tf
  tf.config.experimental.set_memory_growth(
      tf.config.list_physical_devices('GPU')[0], True
  )
  ```
- Stick to batch_size=32, LSTM units=32

### RTX 5060 Ti (16GB)
- No memory concerns for these model sizes
- Can train multiple models in parallel with different hyperparameters
- Enable mixed precision for faster training:
  ```python
  from tensorflow.keras import mixed_precision
  mixed_precision.set_global_policy('mixed_float16')
  ```

---

## Step 6 — Save & Share Models

Models are in `.gitignore` (too large for git). Options:

**Option A — Google Drive share** (easiest for hackathon):
```bash
# Install gdown
pip install gdown
# Upload saved_models/ to Drive, share link, then download:
gdown --folder "your_drive_folder_id" -O saved_models/
```

**Option B — Git LFS** (if repo has LFS enabled):
```bash
git lfs install
git lfs track "maternify_ml/saved_models/*.pkl"
git lfs track "maternify_ml/saved_models/*.keras"
git add .gitattributes
git add maternify_ml/saved_models/
git commit -m "chore: add trained models via LFS"
git push origin main
```

---

## Recommended Training Order for Demo Day

1. **Day before:** Zayan trains LSTM on RTX 5060 Ti, saves to Drive
2. **Morning of:** Everyone downloads models from Drive to their `saved_models/`
3. **Verify:** `uvicorn app.main:app` shows both models loaded
4. **Test:** Run the curl commands above to confirm predictions work
