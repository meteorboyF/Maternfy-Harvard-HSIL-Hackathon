# Maternify — Complete Setup Guide

## Project Structure
```
Maternify-harvard hsil hackathon/
├── maternify_app/          # Flutter mobile app (patient-facing)
├── maternify_api/          # Node.js Express API (port 3000)
├── maternify_dashboard/    # Next.js doctor dashboard (port 3001)
├── maternify_ml/           # FastAPI ML service (port 8000)
├── scripts/                # Seed scripts
├── mock_data/              # Mock AI responses (keyword triage)
├── .env.seed               # Supabase credentials for seed script
├── AI_ENGINEER_HANDOFF.md  # Instructions for ML engineer
├── PROGRESS.md             # Build progress tracker
└── SETUP.md                # This file
```

---

## Credentials & Keys

### Supabase
- **URL:** `https://vqwxggsymilsixrnnies.supabase.co`
- **Anon key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZxd3hnZ3N5bWlsc2l4cm5uaWVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0MDg5MTMsImV4cCI6MjA5MDk4NDkxM30.Zni7NHvYfIjAtofwG8GBrPlCUU-XqWaD2VH4NZ8drYg`
- **Service role key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZxd3hnZ3N5bWlsc2l4cm5uaWVzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NTQwODkxMywiZXhwIjoyMDkwOTg0OTEzfQ.DhYo1lOXzVvL2drrrYzEcXeGk77amZJMbdY-NaV4qv0`

### Firebase
- **Project ID:** `maternify-91c75`
- **Auth domain:** `maternify-91c75.firebaseapp.com`
- **Android app ID:** `1:1045513431035:android:4d0cddf3675d8e49808d5e`
- **Web app ID:** `1:1045513431035:web:d2b900b98ab8d027808d5e`

### Demo Accounts (Firebase Auth — already created)
| Role | Email | Password |
|------|-------|----------|
| Patient (Nusrat) | `demo.mother@maternify.app` | `Demo@1234` |
| Doctor (Dr. Fatema) | `demo.doctor@maternify.app` | `Demo@1234` |

> **TODO:** Get full UIDs from Firebase Console and run the SQL in Step 5 below.

---

## Step-by-Step Run Instructions

### Prerequisites
- Flutter 3.29.2 at `C:/Users/ASUS/flutter/bin/flutter`
- Node.js + npm
- Python 3.13 at `C:/Users/ASUS/AppData/Local/Programs/Python/Python313/python.exe`
- Android Studio Panda 3 (2025.3.3) installed
- Android emulator `Maternify_Demo` (Pixel 8 Pro, API 34) — already created

---

### 1. Start the Android Emulator

```bash
C:/Users/ASUS/flutter/bin/flutter emulators --launch Maternify_Demo
```

Wait ~30 seconds until it fully boots. Verify:
```bash
C:/Users/ASUS/flutter/bin/flutter devices
# Should show: sdk gphone64 x86 64 • emulator-5554 • android-x64 • Android 14
```

---

### 2. Start the Node API (port 3000)

```bash
cd "Desktop/Maternify-harvard hsil hackathon/maternify_api"
npm install
npm run dev
```

Expected output: `Maternify API running on port 3000`

> The `.env` file is already filled in. Triage works in mock mode (no Claude key needed).

---

### 3. Start the Next.js Dashboard (port 3001)

```bash
cd "Desktop/Maternify-harvard hsil hackathon/maternify_dashboard"
npm install
npm run dev
```

Open: http://localhost:3001

---

### 4. Run the Flutter App on Emulator

```bash
cd "Desktop/Maternify-harvard hsil hackathon/maternify_app"
C:/Users/ASUS/flutter/bin/flutter run -d emulator-5554 \
  "--dart-define=SUPABASE_URL=https://vqwxggsymilsixrnnies.supabase.co" \
  "--dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZxd3hnZ3N5bWlsc2l4cm5uaWVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0MDg5MTMsImV4cCI6MjA5MDk4NDkxM30.Zni7NHvYfIjAtofwG8GBrPlCUU-XqWaD2VH4NZ8drYg" \
  "--dart-define=API_BASE_URL=http://10.0.2.2:3000/api"
```

> `10.0.2.2` = Android emulator's alias for your PC's localhost

**Hot reload:** Press `r` in terminal | **Hot restart:** Press `R`

---

### 5. Link Firebase UIDs to Supabase (ONE-TIME SETUP)

After signing in with `demo.mother@maternify.app`, Firebase assigns a UID.
Run this SQL in **Supabase SQL Editor** to link that UID to Nusrat's data:

```sql
-- Replace FIREBASE_UID_NUSRAT with the actual UID from Firebase Console
-- Firebase Console → Authentication → Users → click demo.mother@maternify.app

UPDATE patients
SET id = 'FIREBASE_UID_NUSRAT'
WHERE id = '00000000-0000-0000-0000-000000000001';

UPDATE vitals_logs
SET patient_id = 'FIREBASE_UID_NUSRAT'
WHERE patient_id = '00000000-0000-0000-0000-000000000001';

UPDATE triage_events
SET patient_id = 'FIREBASE_UID_NUSRAT'
WHERE patient_id = '00000000-0000-0000-0000-000000000001';

UPDATE epds_scores
SET patient_id = 'FIREBASE_UID_NUSRAT'
WHERE patient_id = '00000000-0000-0000-0000-000000000001';

UPDATE alerts
SET patient_id = 'FIREBASE_UID_NUSRAT'
WHERE patient_id = '00000000-0000-0000-0000-000000000001';

UPDATE messages
SET sender_id = 'FIREBASE_UID_NUSRAT'
WHERE sender_id = '00000000-0000-0000-0000-000000000001';

UPDATE messages
SET receiver_id = 'FIREBASE_UID_NUSRAT'
WHERE receiver_id = '00000000-0000-0000-0000-000000000001';

-- Also update doctor UID (get from Firebase Console → demo.doctor@maternify.app)
UPDATE patients
SET provider_id = 'FIREBASE_UID_DOCTOR'
WHERE provider_id = '00000000-0000-0000-0000-000000000002';

UPDATE alerts
SET provider_id = 'FIREBASE_UID_DOCTOR'
WHERE provider_id = '00000000-0000-0000-0000-000000000002';
```

---

### 6. Re-run Seed Script (if needed)

```bash
cd "Desktop/Maternify-harvard hsil hackathon"
C:/Users/ASUS/AppData/Local/Programs/Python/Python313/python.exe -X utf8 scripts/seed_demo_data.py
```

---

## Known Issues & Fixes

### Gradle timeout on first Android build
If `flutter run` fails with "Timeout waiting for gradle":
```bash
cd maternify_app/android
./gradlew assembleDebug   # let it download Gradle fully first
# Then re-run flutter run
```

### Android v1 embedding error
Already fixed — `flutter create --platforms=android .` was run on 2026-04-06.
Google Services plugin added to `settings.gradle.kts` and `app/build.gradle.kts`.

### Supabase "no profile" screen on login
Means Firebase UID ≠ patient ID in Supabase. Run Step 5 SQL above.

### Node API auth middleware blocks requests
The middleware requires a Firebase JWT. For local testing, the mock triage
works without a real token if you disable middleware temporarily.

---

## Demo Flow (end-to-end)

1. Launch emulator → start Node API → run Flutter app
2. Sign in as `demo.mother@maternify.app / Demo@1234`
3. See Nusrat's dashboard (YELLOW risk, 28 weeks)
4. Tap **ভাইটালস লগ** → log BP 138/89 → see red trend line
5. Tap **AI ট্রায়াজ** → type "চোখে ঝাপসা দেখছি" → get RED response instantly
6. Open http://localhost:3001 → sign in as doctor → see Sumaiya + Taslima in RED
7. Click alert bell → see Nusrat's RED triage alert

---

## GitHub
```
https://github.com/meteorboyF/Maternify-Harvard-HSIL-Hackathon
```

Push command:
```bash
cd "Desktop/Maternify-harvard hsil hackathon"
git push origin main
```
