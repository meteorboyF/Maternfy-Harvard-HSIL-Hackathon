# Maternify Build Progress

## Last Updated: 2026-04-03

## Completed Features
- [x] F1: Project scaffold — Flutter + Next.js + Node API + FastAPI (commit `362dfa3`)
- [x] F2: Supabase schema — 6 tables + full RLS policies (commit pending)
  - `patients`, `vitals_logs`, `triage_events`, `epds_scores`, `alerts`, `messages`
  - RLS: provider owns their patients, patients own their own vitals/triage
  - Migration file: `maternify_api/src/db/001_schema.sql`
- [x] F3: Firebase Auth custom claims — `authService.js`, `/api/auth/register-provider` + `/register-patient` (commit pending)
- [x] F4: Seed script — 5 demo patients, 14 days vitals, 2 preeclampsia-risk trajectories (commit pending)
  - Risk patients: Shirin Sultana (36w), Mina Parvin (32w) — escalating BP trend toward today

## In Progress
- F5: Claude API triage endpoint — Node.js /api/triage with Bangla NLP

## Next Up
- F6: XGBoost risk model training + SHAP
- F7: LSTM anomaly detector
- F8: Firestore alert pipeline

## Known Issues
- Flutter SDK download in progress (~600MB) — Flutter UI preview pending
- `@radix-ui/react-badge` removed from dashboard deps (does not exist in registry)
