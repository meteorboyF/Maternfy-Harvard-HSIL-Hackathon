# Demo-First Agent Handoff (Flutter)

Last updated: 2026-04-10  
Repo root: `I:\maternify\Maternfy-Harvard-HSIL-Hackathon\Desktop\Maternify-harvard hsil hackathon`

## Goal
Ship an Android-emulator-ready maternal-care experience that feels product-real, interactive, and consistent across screens, using local seeded data where needed.

## What Is Done

### 1) Onboarding/Login flow is polished enough for demo use
- Role selection (mother/doctor) with cleaner product copy.
- Email/password sign-in UX cleaned up to remove developer/demo phrasing.
- Google sign-in message rewritten to neutral product language.
- Session restore/sign-out behavior wired through local repository state.
- Main edits:
  - `maternify_app/lib/screens/auth/login_screen.dart`
  - `maternify_app/lib/blocs/auth/auth_bloc.dart`
  - `maternify_app/lib/blocs/auth/auth_event.dart`
  - `maternify_app/lib/blocs/auth/auth_state.dart`

### 2) Maternal dashboard/home is presentation-ready baseline
- Home cards and actions now read like real maternal care actions.
- Risk status and alerts are visible with clearer user-facing labels.
- Doctor-side home wording adjusted away from internal/meta phrasing.
- Main edit:
  - `maternify_app/lib/screens/home/home_screen.dart`

### 3) AI triage chat flow supports Bangla symptom input and contextual response feel
- Chat responses use recent vitals/risk context from repository state.
- High-risk language adjusted to clinical/product wording.
- Main edit:
  - `maternify_app/lib/screens/triage/triage_screen.dart`

### 4) Vitals logging gives immediate visible updates
- Save flow updates visible state and downstream risk/alerts immediately.
- Copy updated to action-oriented clinical wording.
- Main edit:
  - `maternify_app/lib/screens/vitals/vitals_screen.dart`

### 5) SOS/high-risk transitions feel urgent and connected
- SOS action triggers high-risk state transition and notification updates.
- Confirmation/result copy now user-real and non-technical.
- Main edit:
  - `maternify_app/lib/screens/sos/sos_screen.dart`

### 6) Local seeded data + fake latency architecture exists and is wired
- Central local data/service layer powers auth, home, triage, vitals, SOS.
- Seed JSON drives consistent person, vitals, alerts, and chat starting state.
- Latency simulation included in repository operations.
- Main edits:
  - `maternify_app/lib/demo/demo_repository.dart`
  - `maternify_app/assets/demo/demo_seed.json`
  - `maternify_app/lib/main.dart`

### 7) Full copy audit completed for user-visible text cleanup
- Removed/replaced user-visible strings that sounded like scaffolding/dev notes.
- Focused files: login/home/triage/vitals/sos/auth errors + seed data strings.

## Verified Health
- `flutter analyze --no-fatal-infos` passes in `maternify_app`.
- `flutter test` passes in `maternify_app` (currently minimal smoke test coverage).

## What Still Needs Doing (Highest Value Next)

### A) Remove internal naming leakage from runtime surfaces (if any remain)
- Internal identifiers still use `Demo*` classes and `demo` folder names (fine internally).
- Confirm no remaining user-visible text contains banned/meta wording in all locales and less-traveled screens.
- Re-check:
  - `maternify_app/lib/screens/journal/`
  - `maternify_app/lib/screens/dietary/`
  - Any dialogs/snackbars/toasts not covered in main flow

### B) Upgrade loading/empty/error/success states across entire app
- Standardize skeleton/loading states (not just spinner).
- Add explicit empty-state guidance where lists can be empty (alerts, journals, care tasks).
- Ensure error states provide one-tap recovery (retry/back/contact).

### C) Make charts and trend interactions visibly richer
- Improve vitals chart readability (labels, ranges, last-value callouts).
- Add tiny “what changed today” insight text after each new reading.
- Ensure trend behavior is obvious during live demo in under 10 seconds.

### D) Tighten doctor workflow realism
- Improve clinician patient list sorting/filtering cues.
- Expand patient detail summary consistency with home/triage/vitals narrative.
- Add visible “last updated” timestamps where appropriate.

### E) Add deterministic demo script mode (optional but high presentation ROI)
- Single tap to reset all local state to known baseline before presentation.
- Useful for repeated emulator runs without manual clearing of app storage.

## Suggested Next Agent Task Order
1. Run a final user-visible string sweep across all Flutter screens and seed assets.
2. Implement unified loading/empty/error/success components and apply to top 5 screens.
3. Improve vitals trend chart UX + immediate post-save insight text.
4. Improve doctor-side patient flow coherence and timestamps.
5. Add “Reset App Data” debug action hidden behind long-press or dev gesture.

## Quick Start Commands For Next Agent
```powershell
cd "I:\maternify\Maternfy-Harvard-HSIL-Hackathon\Desktop\Maternify-harvard hsil hackathon\maternify_app"
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter run -d emulator-5554
```

## Notes
- There are many uncommitted changes across API/dashboard/app modules in this repo.  
- Do not reset the tree globally; scope edits to intended files only.
