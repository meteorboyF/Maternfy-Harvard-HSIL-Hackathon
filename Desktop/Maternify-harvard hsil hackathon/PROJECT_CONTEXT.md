# Maternify — Project Context

## What is Maternify?
A maternal health ecosystem for Bangladesh targeting the Harvard HSIL Hackathon at UIU.
Two platforms: (1) Flutter mobile app for mothers, (2) Next.js clinical dashboard for doctors.

## Core Innovation
- Bangla-first NLP triage — mothers type or speak symptoms in Bangla, AI classifies urgency.
- Predictive vitals analytics — LSTM detects preeclampsia risk 48-72h before crisis.
- Real-time alert pipeline — patient Red alert → Firestore → doctor dashboard in <2 seconds.

## Tech Stack
- Mobile: Flutter (Dart)
- Dashboard: Next.js 14 + Tailwind CSS + shadcn/ui
- Auth: Firebase Auth (Google sign-in, custom claims for patient/provider roles)
- Primary DB: Supabase (PostgreSQL) — patients, vitals_logs, triage_events, epds_scores, alerts
- Real-time: Firebase Firestore + FCM push notifications
- AI/NLP: Claude API (claude-sonnet-4-6) — triage, dietary advice, patient summaries
- ASR: OpenAI Whisper (small model, on-device) — Bangla voice input
- ML Models: Python + scikit-learn + XGBoost — risk stratification + LSTM anomaly detection
- ML Backend: FastAPI (Python 3.11) on Render.com
- Node API: Express.js — orchestration layer between clients and AI/ML services
- Deployment: Vercel (Next.js), Render (FastAPI + Node), Firebase, Supabase Cloud

## Supabase Schema
Tables:
- patients: id, name, age, phone, gravida, parity, weeks_gestation, blood_type, provider_id, created_at
- vitals_logs: id, patient_id, systolic_bp, diastolic_bp, weight_kg, blood_glucose, kick_count, logged_at
- triage_events: id, patient_id, input_text, input_lang, triage_tier (green/yellow/red), advice_bangla, advice_english, escalation_required, created_at
- epds_scores: id, patient_id, score, flagged, administered_at
- alerts: id, patient_id, provider_id, alert_type, message, read, created_at
- messages: id, sender_id, receiver_id, content, sent_at

## Feature Build Order

### PHASE 1 — Foundation
[x] F1: Project scaffold — Flutter app + Next.js dashboard + Node API + FastAPI service
[ ] F2: Supabase schema — create all tables with RLS policies
[ ] F3: Firebase Auth — Google sign-in, custom claims (patient vs provider role)
[ ] F4: Seed script — 5 synthetic demo patients with 14 days of vitals history

### PHASE 2 — AI/ML Core
[ ] F5: Claude API triage endpoint
[ ] F6: XGBoost risk model
[ ] F7: LSTM anomaly detector
[ ] F8: Firestore alert pipeline

### PHASE 3 — Flutter Mobile App
[ ] F9: Vitals logging screen
[ ] F10: Triage chat UI
[ ] F11: Voice input
[x] F12: Pregnancy timeline calendar
[ ] F13: SOS button

### PHASE 4 — Next.js Clinical Dashboard
[ ] F14: Traffic-light patient panel
[ ] F15: Patient detail page
[ ] F16: Real-time alert feed
[ ] F17: EPDS screening flow

### PHASE 5 — Polish
[ ] F18: Dietary advisor
[ ] F19: NLP mood journal
[ ] F20: Analytics page

## Claude API System Prompt Template
```
SYSTEM:
You are the AI triage engine for Maternify, a maternal health platform for Bangladesh.
The patient's recent vitals: {{vitals_json}}
Gestational week or postpartum day: {{week_or_day}}
Current ML risk tier: {{risk_tier}}

Classify the symptom input and respond ONLY with valid JSON:
{
  "triage_tier": "green|yellow|red",
  "advice_bangla": "...",
  "advice_english": "...",
  "escalation_required": true|false,
  "suggested_action": "..."
}

Rules:
- Never diagnose. Never name specific medications.
- Yellow/Red always recommend contacting provider.
- Red responses must include emergency positioning instructions.
- Bangla responses must be Grade 6 reading level.
```

## Commit Message Convention
feat(F1): project scaffold — Flutter + Next.js + Node + FastAPI
feat(F5): Claude API triage endpoint with Bangla NLP
fix(F6): correct SHAP value extraction for XGBoost
chore: update PROGRESS.md

## Working Rules
1. Do ONE feature at a time. Do not start F2 until F1 is committed.
2. After every feature: update PROGRESS.md, then git add && commit && push.
3. If blocked, write in PROGRESS.md under "Known Issues" and move to next feature.
4. Always read PROJECT_CONTEXT.md at the start of a new session.
5. Keep code modular — each feature in its own file/folder.
6. Flutter: use BLoC pattern for state management.
7. Node API: use Express Router with one router file per domain.
