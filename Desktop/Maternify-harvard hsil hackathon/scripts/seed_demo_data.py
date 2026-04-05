"""
Maternify Demo Seed Script
Creates demo accounts + realistic clinical data in Supabase.
Run once before demo day.

Usage:
  pip install supabase python-dotenv requests
  python scripts/seed_demo_data.py

Set environment variables (or create a .env file next to this script):
  SUPABASE_URL=https://xxxxx.supabase.co
  SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...   (service role, NOT anon key)
"""

import os, sys, uuid, json
from datetime import datetime, timedelta, timezone
from dotenv import load_dotenv

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '.env.seed'))

SUPABASE_URL = os.environ.get('SUPABASE_URL', '')
SUPABASE_KEY = os.environ.get('SUPABASE_SERVICE_ROLE_KEY', '')

if not SUPABASE_URL or not SUPABASE_KEY:
    print("ERROR: Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env.seed or environment.")
    sys.exit(1)

try:
    from supabase import create_client, Client
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
except ImportError:
    print("ERROR: Run: pip install supabase python-dotenv")
    sys.exit(1)

# ── Fixed demo UUIDs (so re-running is idempotent) ───────────────────────────
NUSRAT_ID   = "00000000-0000-0000-0000-000000000001"
DOCTOR_ID   = "00000000-0000-0000-0000-000000000002"
P3_ID       = "00000000-0000-0000-0000-000000000003"   # Rashida
P4_ID       = "00000000-0000-0000-0000-000000000004"   # Sumaiya
P5_ID       = "00000000-0000-0000-0000-000000000005"   # Fatima
P6_ID       = "00000000-0000-0000-0000-000000000006"   # Rohima
P7_ID       = "00000000-0000-0000-0000-000000000007"   # Nasrin
P8_ID       = "00000000-0000-0000-0000-000000000008"   # Marium
P9_ID       = "00000000-0000-0000-0000-000000000009"   # Taslima

NOW = datetime.now(timezone.utc)

def ts(days_ago=0, hour=9):
    """Return ISO timestamp N days ago at given hour."""
    d = NOW - timedelta(days=days_ago)
    return d.replace(hour=hour, minute=0, second=0, microsecond=0).isoformat()

def upsert(table, rows, conflict_col='id'):
    """Upsert rows — safe to run multiple times."""
    if not rows:
        return
    result = supabase.table(table).upsert(rows, on_conflict=conflict_col).execute()
    return result

# ──────────────────────────────────────────────────────────────────────────────
print("=== Maternify Demo Seed Script ===\n")

# ── 1. Patients ───────────────────────────────────────────────────────────────
print("[1/6] Seeding patients...")

patients = [
    {
        "id":              NUSRAT_ID,
        "name":            "Nusrat Jahan",
        "age":             26,
        "phone":           "+8801711234567",
        "gravida":         2,
        "parity":          1,
        "weeks_gestation": 28,
        "blood_type":      "B+",
        "provider_id":     DOCTOR_ID,
        "created_at":      ts(14),
    },
    {
        "id":              P3_ID,
        "name":            "Rashida Begum",
        "age":             30,
        "phone":           "+8801722345678",
        "gravida":         3,
        "parity":          2,
        "weeks_gestation": 32,
        "blood_type":      "O+",
        "provider_id":     DOCTOR_ID,
        "created_at":      ts(30),
    },
    {
        "id":              P4_ID,
        "name":            "Sumaiya Akter",
        "age":             24,
        "phone":           "+8801733456789",
        "gravida":         1,
        "parity":          0,
        "weeks_gestation": 36,
        "blood_type":      "A+",
        "provider_id":     DOCTOR_ID,
        "created_at":      ts(25),
    },
    {
        "id":              P5_ID,
        "name":            "Fatima Khatun",
        "age":             28,
        "phone":           "+8801744567890",
        "gravida":         2,
        "parity":          2,
        "weeks_gestation": 0,   # postpartum
        "blood_type":      "B-",
        "provider_id":     DOCTOR_ID,
        "created_at":      ts(60),
    },
    {
        "id":              P6_ID,
        "name":            "Rohima Begum",
        "age":             22,
        "phone":           "+8801755678901",
        "gravida":         1,
        "parity":          0,
        "weeks_gestation": 20,
        "blood_type":      "AB+",
        "provider_id":     DOCTOR_ID,
        "created_at":      ts(20),
    },
    {
        "id":              P7_ID,
        "name":            "Nasrin Sultana",
        "age":             32,
        "phone":           "+8801766789012",
        "gravida":         3,
        "parity":          2,
        "weeks_gestation": 32,
        "blood_type":      "O-",
        "provider_id":     DOCTOR_ID,
        "created_at":      ts(18),
    },
    {
        "id":              P8_ID,
        "name":            "Marium Begum",
        "age":             25,
        "phone":           "+8801777890123",
        "gravida":         1,
        "parity":          0,
        "weeks_gestation": 16,
        "blood_type":      "A-",
        "provider_id":     DOCTOR_ID,
        "created_at":      ts(10),
    },
    {
        "id":              P9_ID,
        "name":            "Taslima Akter",
        "age":             27,
        "phone":           "+8801788901234",
        "gravida":         2,
        "parity":          1,
        "weeks_gestation": 40,
        "blood_type":      "B+",
        "provider_id":     DOCTOR_ID,
        "created_at":      ts(7),
    },
]
upsert("patients", patients)
print(f"  ✓ {len(patients)} patients upserted")

# ── 2. Vitals for Nusrat (14 days, rising preeclampsia trajectory) ────────────
print("[2/6] Seeding Nusrat's 14-day vitals...")

# Day 1-7: BP 118/76 → gradually rising
# Day 8-11: BP 128/84 → weight gain spike
# Day 12-14: BP 138/89 → YELLOW alert territory

nusrat_vitals_plan = [
    # (days_ago, systolic, diastolic, weight_kg, glucose, kicks)
    (14, 118, 76, 68.0, 5.2, 18),
    (13, 120, 77, 68.1, 5.3, 18),
    (12, 121, 78, 68.2, 5.2, 17),
    (11, 122, 78, 68.3, 5.4, 17),
    (10, 124, 79, 68.4, 5.5, 16),
    (9,  125, 80, 68.5, 5.6, 16),
    (8,  126, 81, 68.5, 5.7, 16),
    # Week 2 — weight spike, BP rising
    (7,  128, 82, 68.8, 5.8, 15),
    (6,  129, 83, 69.0, 5.9, 15),
    (5,  130, 84, 69.2, 6.0, 14),
    (4,  131, 85, 69.5, 6.1, 14),
    # Week 3 — approaching danger threshold
    (3,  134, 86, 69.8, 6.4, 13),
    (2,  136, 88, 70.0, 6.6, 12),
    (1,  138, 89, 70.1, 6.8, 12),
]

nusrat_vitals = [
    {
        "id":          str(uuid.uuid4()),
        "patient_id":  NUSRAT_ID,
        "systolic_bp": v[1],
        "diastolic_bp": v[2],
        "weight_kg":   v[3],
        "blood_glucose": v[4],
        "kick_count":  v[5],
        "logged_at":   ts(v[0]),
    }
    for v in nusrat_vitals_plan
]
upsert("vitals_logs", nusrat_vitals)
print(f"  ✓ {len(nusrat_vitals)} vitals entries for Nusrat")

# ── 3. Vitals for other patients (brief, realistic) ──────────────────────────
print("[3/6] Seeding other patients' vitals...")

other_vitals = []

def add_vitals(pid, days, sys_bp, dia_bp, weight, glucose, kicks):
    for i, d in enumerate(range(days, 0, -1)):
        other_vitals.append({
            "id":           str(uuid.uuid4()),
            "patient_id":   pid,
            "systolic_bp":  sys_bp + i,
            "diastolic_bp": dia_bp + i // 2,
            "weight_kg":    round(weight + i * 0.05, 1),
            "blood_glucose": round(glucose + i * 0.02, 1),
            "kick_count":   kicks,
            "logged_at":    ts(d),
        })

# Rashida: GREEN, normal
add_vitals(P3_ID, 7, 114, 72, 72.0, 4.9, 20)
# Sumaiya: RED, BP 145/95
add_vitals(P4_ID, 7, 143, 93, 74.5, 6.0, 14)
# Rohima: GREEN, normal
add_vitals(P6_ID, 5, 112, 70, 58.0, 4.8, 22)
# Nasrin: YELLOW, glucose elevated
add_vitals(P7_ID, 7, 128, 80, 69.0, 7.2, 16)
# Marium: GREEN, normal
add_vitals(P8_ID, 5, 110, 68, 61.0, 4.7, 20)
# Taslima: RED, overdue + high BP
add_vitals(P9_ID, 7, 148, 96, 78.0, 6.5, 10)

upsert("vitals_logs", other_vitals)
print(f"  ✓ {len(other_vitals)} vitals entries for other patients")

# ── 4. Triage events ─────────────────────────────────────────────────────────
print("[4/6] Seeding triage events...")

triage_events = [
    # Nusrat Day 5 — GREEN
    {
        "id":                  str(uuid.uuid4()),
        "patient_id":          NUSRAT_ID,
        "input_text":          "মাথা একটু ব্যথা করছে",
        "input_lang":          "bn",
        "triage_tier":         "green",
        "advice_bangla":       "চিন্তার কিছু নেই। পর্যাপ্ত পানি পান করুন ও বিশ্রাম নিন। ব্যথা বাড়লে ডাক্তারকে জানান।",
        "advice_english":      "No immediate concern. Stay hydrated and rest. Notify your doctor if it worsens.",
        "escalation_required": False,
        "suggested_action":    "Rest and hydrate. Monitor.",
        "created_at":          ts(9),
    },
    # Nusrat Day 10 — YELLOW
    {
        "id":                  str(uuid.uuid4()),
        "patient_id":          NUSRAT_ID,
        "input_text":          "পা ফুলে গেছে আর মাথা ঘুরছে",
        "input_lang":          "bn",
        "triage_tier":         "yellow",
        "advice_bangla":       "পায়ের পানি ও মাথা ঘোরা উদ্বেগজনক হতে পারে। লবণ কম খান, পায়ের নিচে বালিশ দিন। আজই ডাক্তারের সাথে কথা বলুন।",
        "advice_english":      "Leg swelling with dizziness may indicate elevated BP. Reduce salt, elevate feet. Contact clinic today.",
        "escalation_required": True,
        "suggested_action":    "Contact clinic today.",
        "created_at":          ts(4),
    },
    # Nusrat Day 13 — RED
    {
        "id":                  str(uuid.uuid4()),
        "patient_id":          NUSRAT_ID,
        "input_text":          "চোখে ঝাপসা দেখছি, মাথা অনেক ব্যথা",
        "input_lang":          "bn",
        "triage_tier":         "red",
        "advice_bangla":       "এটি প্রি-এক্লাম্পসিয়ার গুরুতর লক্ষণ। এখনই হাসপাতালে যান। বাম পাশে শুয়ে থাকুন। পরিবারকে সাথে নিন।",
        "advice_english":      "Visual disturbances with severe headache are signs of severe preeclampsia. Go to hospital IMMEDIATELY. Lie on left side. Call your doctor.",
        "escalation_required": True,
        "suggested_action":    "Go to hospital immediately. Left-lateral positioning.",
        "created_at":          ts(1),
    },
    # Sumaiya — RED
    {
        "id":                  str(uuid.uuid4()),
        "patient_id":          P4_ID,
        "input_text":          "মাথা অনেক ব্যথা, বমি বমি লাগছে",
        "input_lang":          "bn",
        "triage_tier":         "red",
        "advice_bangla":       "এখনই হাসপাতালে যান। BP ১৪৫/৯৫ — প্রি-এক্লাম্পসিয়ার ঝুঁকি।",
        "advice_english":      "Immediate hospital visit required. BP 145/95 — severe preeclampsia risk.",
        "escalation_required": True,
        "suggested_action":    "Emergency hospital visit required.",
        "created_at":          ts(2),
    },
    # Taslima — RED
    {
        "id":                  str(uuid.uuid4()),
        "patient_id":          P9_ID,
        "input_text":          "প্রসব বেদনা শুরু হয়েছে, মাথা ঘুরছে",
        "input_lang":          "bn",
        "triage_tier":         "red",
        "advice_bangla":       "৪০ সপ্তাহ পূর্ণ হয়েছে। এখনই হাসপাতালে যান। দেরি করবেন না।",
        "advice_english":      "40 weeks gestation with labor onset and dizziness. Go to hospital now.",
        "escalation_required": True,
        "suggested_action":    "Emergency — overdue, labor onset, high BP.",
        "created_at":          ts(1),
    },
    # Nasrin — YELLOW
    {
        "id":                  str(uuid.uuid4()),
        "patient_id":          P7_ID,
        "input_text":          "বেশি তৃষ্ণা লাগছে, ঘন ঘন প্রস্রাব হচ্ছে",
        "input_lang":          "bn",
        "triage_tier":         "yellow",
        "advice_bangla":       "রক্তের সুগার একটু বেশি মনে হচ্ছে। মিষ্টি ও ভাত কম খান। ডাক্তারকে জানান।",
        "advice_english":      "Symptoms suggest elevated glucose. Reduce sugar and rice intake. Notify provider.",
        "escalation_required": True,
        "suggested_action":    "Schedule glucose tolerance test.",
        "created_at":          ts(3),
    },
]
upsert("triage_events", triage_events)
print(f"  ✓ {len(triage_events)} triage events upserted")

# ── 5. EPDS scores ────────────────────────────────────────────────────────────
print("[5/6] Seeding EPDS scores...")

epds_scores = [
    # Nusrat 6-week postpartum (borderline, below threshold)
    {
        "id":             str(uuid.uuid4()),
        "patient_id":     NUSRAT_ID,
        "score":          8,
        "flagged":        False,
        "administered_at": ts(42),
    },
    # Fatima — PPD risk (EPDS ≥ 12 → flagged)
    {
        "id":             str(uuid.uuid4()),
        "patient_id":     P5_ID,
        "score":          13,
        "flagged":        True,
        "administered_at": ts(7),
    },
]
upsert("epds_scores", epds_scores)
print(f"  ✓ {len(epds_scores)} EPDS scores upserted")

# ── 6. Messages ───────────────────────────────────────────────────────────────
print("[6/6] Seeding messages...")

messages = [
    {
        "id":         str(uuid.uuid4()),
        "sender_id":  NUSRAT_ID,
        "receiver_id": DOCTOR_ID,
        "content":    "Apa, paer pani asheche, ki korbo?",
        "sent_at":    ts(7, hour=10),
    },
    {
        "id":         str(uuid.uuid4()),
        "sender_id":  DOCTOR_ID,
        "receiver_id": NUSRAT_ID,
        "content":    "Chinta korben na. Laban kom khaben, pair niche balish deben. Kal ashen.",
        "sent_at":    ts(7, hour=11),
    },
    {
        "id":         str(uuid.uuid4()),
        "sender_id":  NUSRAT_ID,
        "receiver_id": DOCTOR_ID,
        "content":    "Apu chokhe jhapsa dekhchi",
        "sent_at":    ts(1, hour=8),
    },
    {
        "id":         str(uuid.uuid4()),
        "sender_id":  DOCTOR_ID,
        "receiver_id": NUSRAT_ID,
        "content":    "EKHUNI hospital ashen. Ami inform korchi.",
        "sent_at":    ts(1, hour=8),
    },
]
upsert("messages", messages)
print(f"  ✓ {len(messages)} messages upserted")

# ── 7. Alerts ─────────────────────────────────────────────────────────────────
alerts = [
    {
        "id":          str(uuid.uuid4()),
        "patient_id":  NUSRAT_ID,
        "provider_id": DOCTOR_ID,
        "alert_type":  "red_triage",
        "message":     "RED: Nusrat Jahan (28w) — চোখে ঝাপসা দেখছি, মাথা অনেক ব্যথা. Go to hospital immediately.",
        "read":        False,
        "created_at":  ts(1),
    },
    {
        "id":          str(uuid.uuid4()),
        "patient_id":  P4_ID,
        "provider_id": DOCTOR_ID,
        "alert_type":  "red_triage",
        "message":     "RED: Sumaiya Akter (36w) — BP 145/95. Immediate hospital visit required.",
        "read":        False,
        "created_at":  ts(2),
    },
    {
        "id":          str(uuid.uuid4()),
        "patient_id":  P9_ID,
        "provider_id": DOCTOR_ID,
        "alert_type":  "red_triage",
        "message":     "RED: Taslima Akter (40w OVERDUE) — labor onset + high BP. Emergency.",
        "read":        False,
        "created_at":  ts(1),
    },
    {
        "id":          str(uuid.uuid4()),
        "patient_id":  P5_ID,
        "provider_id": DOCTOR_ID,
        "alert_type":  "epds_flag",
        "message":     "EPDS ALERT: Fatima Khatun — score 13 (threshold ≥12). PPD risk. Schedule follow-up.",
        "read":        False,
        "created_at":  ts(7),
    },
]
upsert("alerts", alerts)
print(f"  ✓ {len(alerts)} alerts upserted")

# ── Summary ───────────────────────────────────────────────────────────────────
print("\n" + "="*50)
print("✅ SEED COMPLETE")
print("="*50)
print("\nDemo Credentials:")
print("  Patient login : demo.mother@maternify.app / Demo@1234")
print("  Doctor login  : demo.doctor@maternify.app / Demo@1234")
print("\nIMPORTANT: Firebase Auth accounts must be created separately.")
print("See scripts/create_firebase_accounts.md for instructions.")
print("\nNusrat's patient ID :", NUSRAT_ID)
print("Doctor's user ID    :", DOCTOR_ID)
print("\nVerify in Supabase dashboard:")
print(f"  {SUPABASE_URL}/project/default/editor")
