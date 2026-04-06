# Maternify — Team Setup Guide
> Harvard HSIL Hackathon | Last updated: 2026-04-06

---

## Tech Stack

| Layer | Tech | Port |
|-------|------|------|
| Mobile App | Flutter 3.29.2 (Dart) | — |
| Triage API | Node.js + Express | 3000 |
| Doctor Dashboard | Next.js 14 + Tailwind | 3001 |
| ML Service | FastAPI + Python 3.13 | 8000 |
| Auth | Firebase Auth (Email/Password) | — |
| Database | Supabase (PostgreSQL) | — |
| AI Triage | Claude API (mock mode without key) | — |

---

## Project Structure

```
Maternify-harvard hsil hackathon/
├── maternify_app/        Flutter mobile app (patient-facing)
├── maternify_api/        Node.js triage + alerts API
├── maternify_dashboard/  Next.js doctor dashboard
├── maternify_ml/         FastAPI ML service (XGBoost + LSTM)
├── scripts/              Supabase seed script
├── mock_data/            Keyword-based triage rules (no AI key needed)
└── TEAM_SETUP.md         This file
```

---

## Credentials

### Firebase
- **Project:** `maternify-91c75`
- **Console:** https://console.firebase.google.com/project/maternify-91c75

### Supabase
- **Project URL:** `https://vqwxggsymilsixrnnies.supabase.co`
- **Anon key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZxd3hnZ3N5bWlsc2l4cm5uaWVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0MDg5MTMsImV4cCI6MjA5MDk4NDkxM30.Zni7NHvYfIjAtofwG8GBrPlCUU-XqWaD2VH4NZ8drYg`
- **Dashboard:** https://supabase.com/dashboard/project/vqwxggsymilsixrnnies/editor

### Demo Accounts (already in Firebase Auth)
| Role | Email | Password |
|------|-------|----------|
| Patient — Nusrat Jahan | `demo.mother@maternify.app` | `Demo@1234` |
| Doctor — Dr. Fatema | `demo.doctor@maternify.app` | `Demo@1234` |

### Seeded Patient Data (already in Supabase)
- **Nusrat Jahan** — 26 years old, 28 weeks pregnant, B+ blood, YELLOW risk tier
- 14 days of vitals history (BP trending upward 130→138 systolic)
- 8 other patients seeded (Sumaiya, Taslima, etc.) with mixed risk tiers
- Patient ID in Supabase is currently `00000000-0000-0000-0000-000000000001`
  → Must be updated to Nusrat's Firebase UID (see Step 5 below)

---

## Prerequisites

### All machines
- **Git** — to clone the repo
- **Node.js 20+** — for API and dashboard
- **Python 3.10+** — for ML service and seed script
- **Flutter 3.29.2** — for mobile app

### Flutter installation (if not installed)
```bash
# Windows — download from https://docs.flutter.dev/get-started/install/windows
# After install, add to PATH and run:
flutter doctor
```

### Android Studio setup (CRITICAL — read before opening)
1. Install Android Studio from https://developer.android.com/studio
2. **Install Flutter + Dart plugins BEFORE opening the project:**
   - Open Android Studio → File → Settings → Plugins → Marketplace
   - Search **"Flutter"** → Install → it auto-installs Dart too → Restart
3. Open `maternify_app/` as the project root (NOT the `android/` subfolder)
4. On first open it will ask for Flutter SDK path — point it to wherever `flutter` is installed (e.g. `C:\Users\YourName\flutter`)

> **Why:** Without the Flutter plugin, Android Studio shows a blank project with no Dart support.

---

## Running Everything

### Terminal 1 — Node Triage API
```bash
cd maternify_api
npm install
npm run dev
# Running on http://localhost:3000
```

### Terminal 2 — Next.js Doctor Dashboard
```bash
cd maternify_dashboard
npm install
npm run dev
# Open http://localhost:3001
```

### Terminal 3 — Flutter App (Web — fastest for testing)
```bash
cd maternify_app
flutter pub get
flutter run -d chrome --web-port 8080 \
  "--dart-define=SUPABASE_URL=https://vqwxggsymilsixrnnies.supabase.co" \
  "--dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZxd3hnZ3N5bWlsc2l4cm5uaWVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0MDg5MTMsImV4cCI6MjA5MDk4NDkxM30.Zni7NHvYfIjAtofwG8GBrPlCUU-XqWaD2VH4NZ8drYg" \
  "--dart-define=API_BASE_URL=http://localhost:3000/api"
# Opens Chrome automatically at http://localhost:8080
```

### Terminal 3 (alternative) — Flutter App on Android Emulator
```bash
# First create an AVD in Android Studio: Tools → Device Manager → Create Virtual Device
# Pixel 8 Pro, API 34, x86_64
# Then:
flutter emulators --launch <your_avd_name>
# Wait 30 seconds, then:
flutter run -d emulator-5554 \
  "--dart-define=SUPABASE_URL=https://vqwxggsymilsixrnnies.supabase.co" \
  "--dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZxd3hnZ3N5bWlsc2l4cm5uaWVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0MDg5MTMsImV4cCI6MjA5MDk4NDkxM30.Zni7NHvYfIjAtofwG8GBrPlCUU-XqWaD2VH4NZ8drYg" \
  "--dart-define=API_BASE_URL=http://10.0.2.2:3000/api"
# Note: 10.0.2.2 = Android emulator's alias for localhost
```

### Terminal 4 (optional) — ML FastAPI Service
```bash
cd maternify_ml
python -m venv .venv
.venv\Scripts\activate        # Windows
# source .venv/bin/activate   # Mac/Linux
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
# Open http://localhost:8000/docs for Swagger UI
```
> ML service works without trained models — falls back to rule-based scoring.
> See **ZAYAN_TRAINING_GUIDE.md** to train the actual XGBoost and LSTM models.

---

## One-Time Firebase Setup

### Enable Email/Password sign-in (REQUIRED)
1. Go to https://console.firebase.google.com/project/maternify-91c75/authentication/providers
2. Click **Email/Password** → Enable → Save

Without this step login will fail silently.

---

## One-Time Supabase Setup — Link Firebase UIDs

The demo patient (Nusrat) is seeded with a placeholder UUID. After first login, update it to her real Firebase UID:

1. Sign in as `demo.mother@maternify.app` in the app
2. Go to Firebase Console → Authentication → Users → click `demo.mother@maternify.app` → copy the **User UID**
3. Do the same for `demo.doctor@maternify.app`
4. Run this SQL in https://supabase.com/dashboard/project/vqwxggsymilsixrnnies/sql:

```sql
-- Replace NUSRAT_UID and DOCTOR_UID with the actual Firebase UIDs

UPDATE patients SET id = 'NUSRAT_UID'
WHERE id = '00000000-0000-0000-0000-000000000001';

UPDATE vitals_logs SET patient_id = 'NUSRAT_UID'
WHERE patient_id = '00000000-0000-0000-0000-000000000001';

UPDATE triage_events SET patient_id = 'NUSRAT_UID'
WHERE patient_id = '00000000-0000-0000-0000-000000000001';

UPDATE epds_scores SET patient_id = 'NUSRAT_UID'
WHERE patient_id = '00000000-0000-0000-0000-000000000001';

UPDATE alerts SET patient_id = 'NUSRAT_UID'
WHERE patient_id = '00000000-0000-0000-0000-000000000001';

UPDATE messages SET sender_id = 'NUSRAT_UID'
WHERE sender_id = '00000000-0000-0000-0000-000000000001';

UPDATE messages SET receiver_id = 'NUSRAT_UID'
WHERE receiver_id = '00000000-0000-0000-0000-000000000001';

UPDATE patients SET provider_id = 'DOCTOR_UID'
WHERE provider_id = '00000000-0000-0000-0000-000000000002';

UPDATE alerts SET provider_id = 'DOCTOR_UID'
WHERE provider_id = '00000000-0000-0000-0000-000000000002';
```

---

## Re-seed Supabase (if data gets wiped)

```bash
cd "Maternify-harvard hsil hackathon"
pip install supabase python-dotenv
python -X utf8 scripts/seed_demo_data.py
```

---

## Demo Script (for presentation)

1. Open http://localhost:8080 (Flutter web) or run on Android
2. Tap **"Demo: ট্যাপ করুন অটো-ফিল করতে →"** — auto-fills patient credentials
3. Login → see Nusrat's dashboard: **28 weeks, YELLOW risk, due June 29 2026**
4. Tap **ভাইটালস লগ** → enter BP `140/92`, glucose `7.5` → submit → see trend chart update
5. Tap **AI ট্রায়াজ** → type `চোখে ঝাপসা দেখছি` → instant **RED** response
6. Tap **ক্যালেন্ডার** → see week 28 milestone, 3rd trimester badge, baby-size card (cabbage)
7. Tap **খাদ্য পরামর্শ** → 3rd trimester Bangladesh-specific food recommendations
8. Tap **মেজাজ জার্নাল** → tap a prompt chip → tap **AI বিশ্লেষণ করুন** → Claude mood analysis
9. Tap **SOS** button → see emergency info card with patient name, blood group, location
10. Open http://localhost:3001 → login as doctor → see patient list with risk tiers

---

## Common Issues

| Problem | Fix |
|---------|-----|
| Login fails silently | Enable Email/Password in Firebase Console (see above) |
| "No profile" screen after login | Firebase UID not linked to Supabase — run the SQL above |
| Flutter: `record_linux` build error | Already fixed in pubspec.yaml — run `flutter pub get` |
| Android emulator crashes on launch | Intel UHD GPU doesn't support Vulkan 1.3 — use Chrome instead (`-d chrome`) |
| Gradle times out on first build | Run `cd maternify_app/android && ./gradlew assembleDebug` first to pre-download |
| AI Triage returns nothing | Node API not running — start Terminal 1 first |
| Dashboard shows no patients | Firebase UID not linked — run the SQL above |
| `flutter` command not found | Add Flutter bin to PATH, or use full path `C:/Users/YourName/flutter/bin/flutter` |

---

## GitHub
```
https://github.com/meteorboyF/Maternify-Harvard-HSIL-Hackathon
```
