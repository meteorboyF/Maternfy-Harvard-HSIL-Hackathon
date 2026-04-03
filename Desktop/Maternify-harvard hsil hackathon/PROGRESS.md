# Maternify Build Progress

## Last Updated: 2026-04-03

## Completed Features
- [x] F1: Project scaffold — Flutter + Next.js + Node API + FastAPI (commit `362dfa3`)
- [x] F2: Supabase schema — 6 tables + full RLS policies (commit `ab07e1e`)
- [x] F3: Firebase Auth custom claims — authService + /api/auth routes (commit `ab07e1e`)
- [x] F4: Seed script — 5 demo patients, 14d vitals, 2 preeclampsia-risk trajectories (commit `ab07e1e`)
- [x] F5: Claude API triage endpoint — full pipeline with Bangla NLP + Firestore hook (commit `d15cdbb`)
- [x] F6: XGBoost risk model — training script, SHAP top-3 features, FastAPI endpoint (commit pending)
- [x] F7: LSTM anomaly detector — autoencoder training, 7-day window inference, FastAPI endpoint (commit pending)
- [x] F8: Firestore alert pipeline — onSnapshot listener in Next.js, real-time alert feed page (commit pending)

## In Progress
- F9: Vitals logging screen — Flutter form + fl_chart trend chart

## Next Up
- F10: Triage chat UI (Flutter bubbles, Bangla keyboard)
- F11: Voice input (Whisper)
- F14: Traffic-light patient panel (Next.js dashboard)

## Known Issues
- Flutter SDK download still in progress (~600MB) — preview pending
- Models in saved_models/ not committed (large binary — run training scripts locally)
