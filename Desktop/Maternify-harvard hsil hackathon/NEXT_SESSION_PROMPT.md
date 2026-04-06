# Prompt for Next Claude Session

Copy-paste this entire block into a new Claude Code chat:

---

Read PROJECT_CONTEXT.md, PROGRESS.md, and SETUP.md first to understand the full project.

## CURRENT STATE (as of 2026-04-06)

Maternify is a maternal health app for Bangladesh (Harvard HSIL Hackathon).
All features are built. We are in the final setup/demo phase.

### What is DONE:
- Flutter app: all screens built, brand theme (#993556), Nunito font, email+password login
- Node API: running, mock triage (keyword matching), no Claude key needed
- Next.js dashboard: patient panel, alerts, analytics, EPDS all built
- Supabase: all 6 tables created, 8 patients seeded, 14-day vitals for Nusrat
- Firebase Auth: 2 demo accounts created (demo.mother + demo.doctor)
- Android emulator: Maternify_Demo (Pixel 8 Pro, API 34) created and working
- Android build: scaffold regenerated (v1 embedding error fixed), Firebase gradle plugin added

### What STILL NEEDS to be done:

#### 1. Fix Firebase UID ↔ Supabase patient link (CRITICAL for demo)
Firebase Auth UIDs for the demo accounts need to be linked to the seeded patient records.
Get the full UIDs from Firebase Console:
- https://console.firebase.google.com/project/maternify-91c75/authentication/users
- Click each user to get full UID

Then run this SQL in Supabase SQL Editor (https://supabase.com/dashboard/project/vqwxggsymilsixrnnies/sql):

```sql
UPDATE patients SET id = 'NUSRAT_FIREBASE_UID'
WHERE id = '00000000-0000-0000-0000-000000000001';

UPDATE vitals_logs SET patient_id = 'NUSRAT_FIREBASE_UID'
WHERE patient_id = '00000000-0000-0000-0000-000000000001';

UPDATE triage_events SET patient_id = 'NUSRAT_FIREBASE_UID'
WHERE patient_id = '00000000-0000-0000-0000-000000000001';

UPDATE epds_scores SET patient_id = 'NUSRAT_FIREBASE_UID'
WHERE patient_id = '00000000-0000-0000-0000-000000000001';

UPDATE alerts SET patient_id = 'NUSRAT_FIREBASE_UID'
WHERE patient_id = '00000000-0000-0000-0000-000000000001';

UPDATE messages SET sender_id = 'NUSRAT_FIREBASE_UID'
WHERE sender_id = '00000000-0000-0000-0000-000000000001';

UPDATE messages SET receiver_id = 'NUSRAT_FIREBASE_UID'
WHERE receiver_id = '00000000-0000-0000-0000-000000000001';

UPDATE patients SET provider_id = 'DOCTOR_FIREBASE_UID'
WHERE provider_id = '00000000-0000-0000-0000-000000000002';

UPDATE alerts SET provider_id = 'DOCTOR_FIREBASE_UID'
WHERE provider_id = '00000000-0000-0000-0000-000000000002';
```

#### 2. Fix `record_linux` compile error FIRST (already done in pubspec.yaml)
The build failed with: `record_linux-0.7.2 missing implementations`.
Already fixed: `record: ^5.2.0` + `dependency_overrides: record_linux: ^0.8.0` in pubspec.yaml.

Open a **VS Code terminal** (Ctrl+`) and run:
```bash
cd "c:\Users\ASUS\Desktop\Maternify-harvard hsil hackathon\maternify_app"
flutter pub get
```

#### 3. Complete the Android Flutter build
The app was building when context ran out. Gradle was downloading (timed out once, was retrying).

Run command (emulator must be started first):
```bash
C:/Users/ASUS/flutter/bin/flutter emulators --launch Maternify_Demo
# wait 30 seconds
cd "c:\Users\ASUS\Desktop\Maternify-harvard hsil hackathon\maternify_app"
C:/Users/ASUS/flutter/bin/flutter run -d emulator-5554 \
  "--dart-define=SUPABASE_URL=https://vqwxggsymilsixrnnies.supabase.co" \
  "--dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZxd3hnZ3N5bWlsc2l4cm5uaWVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0MDg5MTMsImV4cCI6MjA5MDk4NDkxM30.Zni7NHvYfIjAtofwG8GBrPlCUU-XqWaD2VH4NZ8drYg" \
  "--dart-define=API_BASE_URL=http://10.0.2.2:3000/api"
```

If Gradle fails again, run this first to pre-download Gradle:
```bash
cd "c:\Users\ASUS\Desktop\Maternify-harvard hsil hackathon\maternify_app\android"
./gradlew assembleDebug
```

#### 3. Enable Email/Password sign-in in Firebase Console
Go to: https://console.firebase.google.com/project/maternify-91c75/authentication/providers
Click **Email/Password** → Enable → Save

Without this step, the email login on the Flutter app will fail.

#### 4. Start the Node API for triage to work
```bash
cd "c:\Users\ASUS\Desktop\Maternify-harvard hsil hackathon\maternify_api"
npm install
npm run dev
```

#### 5. Start the Next.js dashboard
```bash
cd "c:\Users\ASUS\Desktop\Maternify-harvard hsil hackathon\maternify_dashboard"
npm install
npm run dev
# Open: http://localhost:3001
```

#### 6. End-to-end demo test
- Sign in as `demo.mother@maternify.app / Demo@1234` on the Flutter app
- Should see Nusrat's dashboard with YELLOW risk badge, 28 weeks
- Log vitals → type symptom "চোখে ঝাপসা দেখছি" in triage → should get RED response
- Open dashboard on browser, sign in as `demo.doctor@maternify.app / Demo@1234`
- Should see patient list with RED patients at top

#### 7. Final commit and push
```bash
cd "c:\Users\ASUS\Desktop\Maternify-harvard hsil hackathon"
git add -A
git commit -m "chore: final demo setup — Android build fixed, Supabase wired"
git push origin main
```

---

## Key Files to Know
- `SETUP.md` — all credentials, run commands, known issues
- `maternify_app/android/app/build.gradle.kts` — has Firebase plugin applied
- `maternify_app/android/settings.gradle.kts` — has google-services plugin
- `maternify_api/.env` — Supabase keys filled in, no Claude key (mock mode)
- `maternify_dashboard/.env.local` — Supabase keys filled in
- `mock_data/triage_responses.json` — keyword→triage rules for demo
- `scripts/seed_demo_data.py` — run with `python -X utf8 scripts/seed_demo_data.py`

## Supabase Dashboard
https://supabase.com/dashboard/project/vqwxggsymilsixrnnies/editor

## GitHub
https://github.com/meteorboyF/Maternify-Harvard-HSIL-Hackathon
