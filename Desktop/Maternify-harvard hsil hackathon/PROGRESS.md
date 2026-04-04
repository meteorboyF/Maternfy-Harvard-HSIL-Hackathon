# Maternify Build Progress

## Last Updated: 2026-04-04T23:00

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
- [x] F12: Pregnancy timeline calendar — progress ring, baby-size card, month grid with vitals/triage dots, milestone timeline (`5fe9adb`)
- [x] F13: SOS button — GPS + 24h vitals → Firestore + Supabase alerts (`b61a032`)

### Phase 4 — Next.js Dashboard ✅
- [x] F14: Traffic-light patient panel — Red at top, search, tier filter, ISR (`b61a032`)
- [x] F15: Patient detail page — AI summary (Claude), SHAP bars, vitals chart, triage history (pending commit)
- [x] F16: Real-time alert bell — onSnapshot badge in sidebar, wired to alert feed (pending commit)
- [x] F17: EPDS screening — 10-question flow, auto-score, auto-alert if ≥12, Supabase persist (pending commit)

### Phase 5 — Polish ✅
- [x] F18: Dietary advisor — Claude RAG + Bangladeshi nutrition KB, Node API `/dietary`, Flutter DietaryScreen (`180c05f`)
- [x] F19: NLP mood journal — Claude sentiment analysis, mood score/emoji/themes, EPDS concern flag, Supabase persistence, Flutter JournalScreen with write tab + history tab + mood trend strip (`ce68a04`)
- [x] F20: Analytics page — Next.js dashboard: KPI strip, triage tier donut, population vitals trend, EPDS histogram, alert volume bar chart, top-5 risk table (Recharts + Supabase server queries)

### Infrastructure & Fixes ✅
- [x] Firebase packages upgraded to v3/v5 (Dart 3.7 web compat) (`e8d07d2`)
- [x] `firebase_options.dart` — real credentials for web + android (`e8d07d2`)
- [x] `device_preview` added — phone-frame live preview in Chrome (`b17fb9f`)
- [x] Flutter SDK 3.29.2 at `C:/Users/ASUS/flutter/bin` — in Windows PATH
- [x] ML training infrastructure — `train_all.py`, `TRAINING_GUIDE.md`

---

## How to Run

### Flutter App (Chrome)
```bash
cd "Desktop/Maternify-harvard hsil hackathon/maternify_app"
C:/Users/ASUS/flutter/bin/flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=API_BASE_URL=http://localhost:3000/api
```

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

---

## Firebase Setup (DONE ✅)
- **Project:** `maternify-91c75`
- **Project number:** `1045513431035`
- **Web app ID:** `1:1045513431035:web:d2b900b98ab8d027808d5e`
- **Android app ID:** `1:1045513431035:android:4d0cddf3675d8e49808d5e`
- **Auth:** Google Sign-In enabled, support email: fardinjahangir9@gmail.com
- **Config files:**
  - `maternify_app/lib/firebase_options.dart` — web + android options filled in
  - `maternify_app/android/app/google-services.json` — real credentials
- **Remaining for Android Google Sign-In:** add debug SHA-1 fingerprint in Firebase Console → Project Settings → Your apps → Maternify Android

---

## In Progress
- All features complete ✅ — Maternify v1.0 ready for demo

## Known Issues
- Supabase URL + anon key still needed as `--dart-define` flags (see run command above)
- `saved_models/` not committed — see `maternify_ml/TRAINING_GUIDE.md`
- Android Google Sign-In requires SHA-1 fingerprint (Chrome works without it)
- Node API `.env` needs `ANTHROPIC_API_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, Firebase service account keys
