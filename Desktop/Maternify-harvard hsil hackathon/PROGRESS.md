# Maternify Build Progress

## Last Updated: 2026-04-03

## Completed Features
- [x] F1: Project scaffold — Flutter + Next.js + Node API + FastAPI (commit `362dfa3`)
  - `maternify_app/` — Flutter BLoC skeleton, Auth, models, login/home screens, services
  - `maternify_dashboard/` — Next.js 14 + Tailwind skeleton, Firebase + Supabase clients, TypeScript types
  - `maternify_api/` — Express with 4 domain routers, Firebase token middleware, Supabase service client
  - `maternify_ml/` — FastAPI with XGBoost stub + LSTM stub + Pydantic schemas + model loader

## In Progress
- F2: Supabase schema — create all 6 tables with RLS policies + seed migration

## Next Up
- F3: Firebase Auth — Google sign-in, custom claims (patient vs provider role)
- F4: Seed script — 5 synthetic demo patients with 14 days of vitals history

## Known Issues
- (none)
