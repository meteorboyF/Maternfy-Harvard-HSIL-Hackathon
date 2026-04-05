# Creating Firebase Demo Accounts

After running the seed script, create these two Firebase Auth accounts manually
(or via the Firebase Admin SDK / Console):

## Option A — Firebase Console (easiest)

1. Go to: https://console.firebase.google.com/project/maternify-91c75/authentication/users
2. Click **Add user**
3. Create:
   - Email: `demo.mother@maternify.app`  Password: `Demo@1234`
   - Email: `demo.doctor@maternify.app`  Password: `Demo@1234`

4. Copy the UID for `demo.mother@maternify.app` and run this SQL in Supabase:
   ```sql
   UPDATE patients
   SET id = '<FIREBASE_UID_OF_NUSRAT>'
   WHERE id = '00000000-0000-0000-0000-000000000001';
   ```
   Also update the foreign keys in vitals_logs, triage_events, epds_scores, messages, alerts.

## Option B — Use seed UUIDs as Firebase UIDs (recommended for demo)

The seed script uses fixed UUIDs for Nusrat and the Doctor.
If you can set custom UIDs in Firebase (requires Admin SDK), use:
  - Nusrat  UID: `00000000-0000-0000-0000-000000000001`
  - Doctor  UID: `00000000-0000-0000-0000-000000000002`

## Option C — Admin SDK script (one-time)

```python
import firebase_admin
from firebase_admin import auth, credentials

cred = credentials.Certificate('path/to/service-account.json')
firebase_admin.initialize_app(cred)

auth.create_user(
    uid='00000000-0000-0000-0000-000000000001',
    email='demo.mother@maternify.app',
    password='Demo@1234',
    display_name='Nusrat Jahan',
)
auth.create_user(
    uid='00000000-0000-0000-0000-000000000002',
    email='demo.doctor@maternify.app',
    password='Demo@1234',
    display_name='Dr. Fatema Khanam',
)
print("Done!")
```
