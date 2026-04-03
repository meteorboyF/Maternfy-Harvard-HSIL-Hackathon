# Maternify Build Progress

## Last Updated: 2026-04-03

## Completed Features
- [x] F1: Project scaffold (commit `362dfa3`)
- [x] F2: Supabase schema — 6 tables + RLS (commit `ab07e1e`)
- [x] F3: Firebase Auth custom claims (commit `ab07e1e`)
- [x] F4: Seed script — 5 patients, 14d vitals, 2 risk trajectories (commit `ab07e1e`)
- [x] F5: Claude API triage endpoint — Bangla NLP + Firestore hook (commit `d15cdbb`)
- [x] F6: XGBoost risk model + SHAP (commit `1bb9202`)
- [x] F7: LSTM anomaly detector — autoencoder, 7-day window (commit `1bb9202`)
- [x] F8: Firestore alert pipeline — onSnapshot listener + alert feed page (commit `1bb9202`)
- [x] F9: Vitals logging screen — Flutter form + fl_chart BP trend (commit `1605439`)
- [x] F10: Triage chat UI — bubble interface, Bangla toggle, tier borders (commit `1605439`)
- [x] F11: Voice input — hold-to-record mic, Whisper transcription via API (commit pending)
- [x] F13: SOS button — GPS + 24h vitals snapshot → Firestore + Supabase (commit pending)
- [x] F14: Traffic-light patient panel — sortable/filterable, Red at top (commit pending)

## In Progress
- F15: Patient detail page — AI summary + SHAP explanation + vitals chart
- F12: Pregnancy timeline calendar

## Next Up
- F16: Real-time alert feed (wire useAlerts into dashboard layout)
- F17: EPDS screening flow

## Known Issues
- Flutter SDK download in progress (~171MB/600MB) — Flutter preview pending
  - File locked by PowerShell process, will complete automatically
- saved_models/ not committed (large binaries — see TRAINING_GUIDE.md)
