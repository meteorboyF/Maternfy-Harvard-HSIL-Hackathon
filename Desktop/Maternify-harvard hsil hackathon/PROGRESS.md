# Maternify Build Progress

## Last Updated: 2026-04-03T20:15

## Completed Features

### Phase 1 — Foundation ✅
- [x] F1: Project scaffold — Flutter + Next.js + Node API + FastAPI (`362dfa3`)
- [x] F2: Supabase schema — 6 tables + full RLS (`ab07e1e`)
- [x] F3: Firebase Auth — custom claims, patient/provider roles (`ab07e1e`)
- [x] F4: Seed script — 5 demo patients, 14d vitals, 2 preeclampsia-risk trajectories (`ab07e1e`)

### Phase 2 — AI/ML Core ✅
- [x] F5: Claude API triage — claude-sonnet-4-6, Bangla NLP, Red→Firestore pipeline (`d15cdbb`)
- [x] F6: XGBoost risk model — training script, SHAP top-3 features, FastAPI `/risk-score` (`1bb9202`)
- [x] F7: LSTM anomaly detector — autoencoder, 7-day window, FastAPI `/vitals-anomaly` (`1bb9202`)
- [x] F8: Firestore alert pipeline — onSnapshot listener, real-time alert feed (`1bb9202`)

### Phase 3 — Flutter Mobile App ✅
- [x] F9: Vitals logging screen — form + fl_chart BP trend with danger lines (`1605439`)
- [x] F10: Triage chat UI — bubbles, Bangla/English toggle, typing indicator (`1605439`)
- [x] F11: Voice input — hold-to-record mic, WAV → Whisper → triage (`b61a032`)
- [x] F12: Pregnancy timeline calendar — progress ring, baby-size card, month grid with vitals/triage dots, milestone timeline (pending commit)
- [x] F13: SOS button — GPS + 24h vitals → Firestore + Supabase alerts (`b61a032`)

### Phase 4 — Next.js Dashboard ✅
- [x] F14: Traffic-light patient panel — Red at top, search, tier filter, ISR (`b61a032`)
- [x] F15: Patient detail page — AI summary (Claude), SHAP bars, vitals chart, triage history (pending commit)
- [x] F16: Real-time alert bell — onSnapshot badge in sidebar, wired to alert feed (pending commit)
- [x] F17: EPDS screening — 10-question flow, auto-score, auto-alert if ≥12, Supabase persist (pending commit)

### Training Infrastructure ✅
- [x] `train_all.py` — unified, auto-detects GPU (GTX 1060 → RTX 5060 Ti)
- [x] `TRAINING_GUIDE.md` — Kaggle datasets, PyCharm setup, model sharing

### Flutter SDK ✅
- [x] Flutter 3.29.2 at `C:/Users/ASUS/flutter/bin` — added to Windows PATH
- [x] Web support enabled, `flutter pub get` done (211 packages)

## How to Run

### Flutter App (Chrome — side-by-side with code)
```bash
# Open NEW terminal (PATH refresh needed)
cd "Desktop/Maternify-harvard hsil hackathon/maternify_app"
flutter run -d chrome
```
VS Code: Ctrl+Shift+P → Flutter: Select Device → Chrome → F5

### Node API
```bash
cd maternify_api && cp .env.example .env  # add real keys
npm install && npm run dev   # :3000
```

### Next.js Dashboard
```bash
cd maternify_dashboard && cp .env.local.example .env.local  # add real keys
npm install && npm run dev   # :3001
```

### FastAPI ML Service
```bash
cd maternify_ml && .venv\Scripts\activate
uvicorn app.main:app --reload --port 8000
```

### Train ML Models
```bash
cd maternify_ml && .venv\Scripts\activate
python training/train_all.py              # both models
python training/train_all.py --xgb-only  # XGBoost only, ~30s CPU
python training/train_all.py --kaggle    # use Kaggle dataset
```

### Phase 5 — Polish 🔄
- [x] F18: Dietary advisor — Claude RAG + Bangladeshi nutrition KB, Node API `/dietary`, Flutter DietaryScreen (pending commit)

## In Progress
- F19: NLP mood journal
- F20: Analytics page
- F19: NLP mood journal
- F20: Analytics page

## Known Issues
- Flutter requires real Firebase `google-services.json` before it can connect
- Supabase/Firebase env keys needed for dashboard and API
- `saved_models/` not committed — see TRAINING_GUIDE.md
