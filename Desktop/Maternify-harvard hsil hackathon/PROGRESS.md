# Maternify Build Progress

## Last Updated: 2026-04-03T18:10

## Completed Features

### Phase 1 — Foundation ✅
- [x] F1: Project scaffold — Flutter + Next.js + Node API + FastAPI (`362dfa3`)
- [x] F2: Supabase schema — 6 tables + full RLS policies (`ab07e1e`)
- [x] F3: Firebase Auth — custom claims, patient/provider roles (`ab07e1e`)
- [x] F4: Seed script — 5 synthetic demo patients, 14d vitals, 2 preeclampsia-risk trajectories (`ab07e1e`)

### Phase 2 — AI/ML Core ✅
- [x] F5: Claude API triage endpoint — claude-sonnet-4-6, Bangla NLP, Red→Firestore pipeline (`d15cdbb`)
- [x] F6: XGBoost risk model — training script, SHAP top-3 features, FastAPI `/risk-score` (`1bb9202`)
- [x] F7: LSTM anomaly detector — autoencoder, 7-day window, FastAPI `/vitals-anomaly` (`1bb9202`)
- [x] F8: Firestore alert pipeline — onSnapshot listener in Next.js dashboard (`1bb9202`)

### Phase 3 — Flutter Mobile App (partial) ✅
- [x] F9: Vitals logging screen — form + fl_chart BP trend with 140/90 danger lines (`1605439`)
- [x] F10: Triage chat UI — bubble interface, Bangla/English toggle, typing indicator, tier color borders (`1605439`)
- [x] F11: Voice input — hold-to-record, WAV → Whisper → triage pipeline (`b61a032`)
- [x] F13: SOS button — GPS + 24h vitals snapshot → Firestore + Supabase alerts (`b61a032`)

### Phase 4 — Next.js Dashboard (partial) ✅
- [x] F14: Traffic-light patient panel — sortable, Red at top, search + tier filter, ISR (`b61a032`)
- [x] F8: Real-time alert feed page — onSnapshot, AudioContext ping, tier color cards

### Training Infrastructure ✅
- [x] `training/generate_synthetic_data.py` — 2000-sample synthetic vitals dataset
- [x] `training/train_xgboost.py` — standalone XGBoost trainer
- [x] `training/train_lstm.py` — standalone LSTM autoencoder trainer
- [x] `training/train_all.py` — unified script, auto-detects GPU (GTX 1060 → RTX 5060 Ti)
- [x] `TRAINING_GUIDE.md` — Kaggle dataset links, PyCharm setup, GPU config, model sharing

### Flutter SDK ✅
- [x] Flutter 3.29.2 installed at `C:/Users/ASUS/flutter/`
- [x] Added to Windows user PATH
- [x] Web support enabled (`flutter config --enable-web`)
- [x] `flutter pub get` succeeded (211 packages)

## In Progress
- F15: Patient detail page — AI summary (Claude), SHAP explanation, vitals chart
- F12: Pregnancy timeline calendar
- Flutter web run setup (next step after this commit)

## Next Up
- F16: Real-time alert feed (wire useAlerts hook into dashboard layout header)
- F17: EPDS screening flow
- F18: Dietary advisor (RAG pipeline)
- F19: NLP mood journal
- F20: Analytics page

## How to Run

### Flutter App (web preview in browser)
```bash
cd maternify_app
C:/Users/ASUS/flutter/bin/flutter run -d chrome
```
Or in VS Code: Ctrl+Shift+P → "Flutter: Select Device" → Chrome → F5

### Node API
```bash
cd maternify_api && cp .env.example .env   # fill secrets
npm install && npm run dev   # :3000
```

### Next.js Dashboard
```bash
cd maternify_dashboard && cp .env.local.example .env.local   # fill secrets
npm install && npm run dev   # :3001
```

### ML Service
```bash
cd maternify_ml && .venv\Scripts\activate
uvicorn app.main:app --reload --port 8000
```

### Train ML Models
```bash
cd maternify_ml && .venv\Scripts\activate
python training/train_all.py              # both models, auto GPU
python training/train_all.py --xgb-only  # XGBoost only (~30s, CPU)
python training/train_all.py --kaggle    # use Kaggle dataset
```

## Known Issues
- `saved_models/` not committed (binary — see TRAINING_GUIDE.md for sharing)
- Flutter Firebase config (`google-services.json`, `GoogleService-Info.plist`) not yet set up — needs real Firebase project keys
- Supabase/Firebase .env files need real credentials before app can connect
