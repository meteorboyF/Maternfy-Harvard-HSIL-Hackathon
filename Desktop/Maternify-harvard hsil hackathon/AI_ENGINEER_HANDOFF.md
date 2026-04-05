# AI Engineer Handoff — Maternify

> Last updated: 2026-04-05  
> Status: App fully demoable. All AI features run on mock/keyword mode.  
> Your job: Replace mocks with real ML + real Claude API calls.

---

## 1. Mock Endpoints to Replace

### 1.1 Triage — keyword mock → Claude API

**File:** `maternify_api/src/services/triageService.js`  
**Trigger:** `USE_MOCK = !process.env.ANTHROPIC_API_KEY`  

When `ANTHROPIC_API_KEY` is set in `.env`, the service **automatically switches** from keyword mock to real Claude API. No code change needed — just set the env var.

```env
ANTHROPIC_API_KEY=sk-ant-...
```

**Claude model:** `claude-sonnet-4-6`  
**System prompt:** See `triageService.js` lines 14-33. Template vars: `{{vitals_json}}`, `{{week_or_day}}`, `{{risk_tier}}`

**Input JSON:**
```json
{
  "patient_id": "uuid",
  "input_text": "চোখে ঝাপসা দেখছি",
  "input_lang": "bn",
  "ml_risk_tier": "yellow"
}
```

**Output JSON (Claude must return):**
```json
{
  "triage_tier": "green|yellow|red",
  "advice_bangla": "...",
  "advice_english": "...",
  "escalation_required": true,
  "suggested_action": "..."
}
```

---

### 1.2 Risk Score — BP threshold → XGBoost

**File:** `maternify_ml/app/routers/risk_score.py`  
**Current behavior:** If no saved model found, falls back to BP-threshold logic.

**Real model path:** `maternify_ml/saved_models/xgboost_risk.json`  
**Training script:** `maternify_ml/training/train_xgboost.py`

**Input features (22 total):**
```python
features = [
    'systolic_bp', 'diastolic_bp', 'weight_kg', 'blood_glucose', 'kick_count',
    'bp_change_7d', 'weight_change_7d', 'glucose_trend',  # derived
    'weeks_gestation', 'gravida', 'parity', 'age',         # patient metadata
    # + 10 more lag features from LSTM window
]
```

**Output:**
```json
{
  "risk_tier": "green|yellow|red",
  "risk_score": 0.73,
  "shap_values": {
    "systolic_bp": 0.41,
    "weight_change_7d": 0.28,
    "bp_change_7d": 0.19
  }
}
```

**Training time:** ~20 min on any GPU (XGBoost is CPU-friendly, 30s on CPU too)  
**Dataset:** See Section 4 for reference datasets.

---

### 1.3 LSTM Anomaly Detector — train + plug in

**File:** `maternify_ml/app/routers/vitals_anomaly.py`  
**Training script:** `maternify_ml/training/train_lstm.py`

**Input:** 7-day rolling window of vitals (7 rows × 5 features)  
**Output:** anomaly score 0.0–1.0. Threshold > 0.6 → flag as anomaly.

**Training time:** ~2 hours on RTX 5060 (16GB VRAM is overkill, 4GB sufficient)

```bash
cd maternify_ml
python training/train_all.py
# or separately:
python training/train_all.py --xgb-only   # 30s
python training/train_all.py --lstm-only  # ~2h
```

---

### 1.4 Voice Input — mock delay → Whisper

**File:** `maternify_app/lib/screens/triage/voice_input_widget.dart`  
**Current behavior:** Records audio → 1.5s fake delay → returns pre-written text.

**Real implementation:**
1. Upload WAV to Node API `POST /api/triage/voice` (multipart form)
2. Node API runs Whisper on the file
3. Returns transcript → runs through triage

**Whisper setup:**
```bash
pip install openai-whisper
# In Python:
import whisper
model = whisper.load_model("small")  # ~460MB, good for Bangla
result = model.transcribe("audio.wav", language="bn")
print(result["text"])
```

**Node API voice endpoint:** `maternify_api/src/controllers/triageController.js` → `triageFromVoice()` — currently returns 501, implement here.

---

### 1.5 Patient Summary — hardcoded → Claude generation

**File:** `maternify_dashboard/src/app/(dashboard)/patients/[id]/page.tsx`  
**Current behavior:** Shows a hardcoded summary string.

**Real implementation:** POST to Node API `/api/patients/:id/summary` which calls Claude with patient vitals context.

**Prompt template:**
```
Given these 14 days of vitals for {name} ({weeks}w pregnant):
{vitals_csv}

Latest triage events: {triage_summary}

Write a 2-3 sentence clinical summary in Bangla for the attending physician.
Focus on: BP trend, weight change, fetal movement, risk trajectory.
```

---

## 2. Training Data Format

### CSV schema for vitals + risk label:

```csv
patient_id,date,systolic_bp,diastolic_bp,weight_kg,blood_glucose,kick_count,weeks_gestation,gravida,parity,age,risk_label
uuid-001,2025-01-01,118,76,68.0,5.2,18,28,2,1,26,0
uuid-001,2025-01-02,120,77,68.1,5.3,18,28,2,1,26,0
...
uuid-001,2025-01-13,138,89,70.1,6.8,12,28,2,1,26,1
```

`risk_label`: 0=green, 1=yellow, 2=red  
Label is assigned by clinical outcome (actual preeclampsia diagnosis within 7 days).

---

## 3. Reference Datasets

| Dataset | Notes |
|---------|-------|
| [PIERS dataset](https://journals.plos.org/plosmedicine/article?id=10.1371/journal.pmed.1001898) | Preeclampsia outcome prediction, 2023 patients |
| [Maternal Health Risk Dataset (Kaggle)](https://www.kaggle.com/datasets/csafrit2/maternal-health-risk-data-set) | 1014 rows, features: age, systolic, diastolic, glucose, temp, HR, risk_level |
| [UCI Fetal Health](https://archive.ics.uci.edu/ml/datasets/cardiotocography) | CTG features + fetal health classification |

**Synthetic data generator:** `maternify_ml/training/generate_synthetic_data.py`  
Use `--kaggle` flag to train on real Kaggle dataset.

---

## 4. Python Model Stubs (replace mock logic here)

| File | What to replace |
|------|----------------|
| `maternify_ml/app/routers/risk_score.py` | BP threshold → `xgboost_service.predict()` |
| `maternify_ml/app/routers/vitals_anomaly.py` | Hardcoded score → `lstm_service.detect()` |
| `maternify_ml/app/services/xgboost_service.py` | Load `saved_models/xgboost_risk.json` |
| `maternify_ml/app/services/lstm_service.py` | Load `saved_models/lstm_anomaly.h5` |
| `maternify_api/src/services/triageService.js` | Auto-switches when ANTHROPIC_API_KEY set |
| `maternify_api/src/controllers/triageController.js` | `triageFromVoice()` needs Whisper |

---

## 5. Required Environment Variables

### Node API (`.env` in `maternify_api/`):
```env
ANTHROPIC_API_KEY=sk-ant-api03-...        # Claude API
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
FIREBASE_PROJECT_ID=maternify-91c75
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@...
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n..."
ML_SERVICE_URL=http://localhost:8000
```

### FastAPI ML service (`maternify_ml/.env`):
```env
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
```

### Flutter app (run command):
```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=API_BASE_URL=http://localhost:3000/api
```

### Next.js dashboard (`.env.local`):
```env
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...
NEXT_PUBLIC_FIREBASE_PROJECT_ID=maternify-91c75
NEXT_PUBLIC_FIREBASE_API_KEY=AIza...
```

---

## 6. GPU Training Setup (RTX 5060)

```bash
# Create conda environment
conda create -n maternify python=3.11
conda activate maternify

# Install PyTorch with CUDA 12.x
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121

# Install project deps
cd maternify_ml
pip install -r requirements.txt

# Train
python training/train_all.py
# XGBoost: ~20 min | LSTM: ~2h
```

Output: `maternify_ml/saved_models/xgboost_risk.json` + `lstm_anomaly.h5`

---

## 7. Demo Credentials

```
Patient:  demo.mother@maternify.app / Demo@1234  (Nusrat Jahan, 28w, YELLOW)
Doctor:   demo.doctor@maternify.app / Demo@1234  (Dr. Fatema Khanam)
```

**Firebase project:** `maternify-91c75`  
**Supabase project:** see `.env.seed` for URL  
**GitHub:** https://github.com/meteorboyF/Maternify-Harvard-HSIL-Hackathon

---

## 8. What's Already Working (Don't Touch)

- Firebase Auth (Google Sign-In + Email/Password)
- Supabase schema + RLS policies (all 6 tables)
- Firestore real-time alert pipeline (onSnapshot listener)
- Flutter app: all screens built and styled
- Next.js dashboard: patient panel, detail page, alerts, EPDS, analytics
- Node API: routing, auth middleware, dietary advisor, mood journal
- Mock triage: keyword matching → correct tier in <100ms
- Seed data: 8 patients, 14-day vitals trajectory, 6 triage events, 4 messages

---

*Happy training! The model stubs are clean — just drop in real inference code.*
