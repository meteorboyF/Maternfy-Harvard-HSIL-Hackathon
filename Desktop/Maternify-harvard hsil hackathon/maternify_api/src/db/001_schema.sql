-- ============================================================
-- Maternify — Supabase Schema Migration 001
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor → New Query)
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- TABLE: patients
-- ============================================================
CREATE TABLE IF NOT EXISTS patients (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name            TEXT NOT NULL,
  age             INTEGER NOT NULL CHECK (age BETWEEN 10 AND 60),
  phone           TEXT NOT NULL,
  gravida         INTEGER NOT NULL DEFAULT 1 CHECK (gravida >= 1),
  parity          INTEGER NOT NULL DEFAULT 0 CHECK (parity >= 0),
  weeks_gestation INTEGER NOT NULL CHECK (weeks_gestation BETWEEN 0 AND 42),
  blood_type      TEXT NOT NULL CHECK (blood_type IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
  provider_id     TEXT NOT NULL,   -- Firebase UID of the provider
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE: vitals_logs
-- ============================================================
CREATE TABLE IF NOT EXISTS vitals_logs (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id      UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  systolic_bp     INTEGER NOT NULL CHECK (systolic_bp BETWEEN 60 AND 250),
  diastolic_bp    INTEGER NOT NULL CHECK (diastolic_bp BETWEEN 40 AND 150),
  weight_kg       NUMERIC(5,2) NOT NULL CHECK (weight_kg > 0),
  blood_glucose   NUMERIC(5,2) NOT NULL CHECK (blood_glucose > 0),
  kick_count      INTEGER NOT NULL DEFAULT 0 CHECK (kick_count >= 0),
  logged_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vitals_patient_time
  ON vitals_logs(patient_id, logged_at DESC);

-- ============================================================
-- TABLE: triage_events
-- ============================================================
CREATE TABLE IF NOT EXISTS triage_events (
  id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id           UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  input_text           TEXT NOT NULL,
  input_lang           TEXT NOT NULL DEFAULT 'bn' CHECK (input_lang IN ('bn','en')),
  triage_tier          TEXT NOT NULL CHECK (triage_tier IN ('green','yellow','red')),
  advice_bangla        TEXT NOT NULL,
  advice_english       TEXT NOT NULL,
  escalation_required  BOOLEAN NOT NULL DEFAULT FALSE,
  suggested_action     TEXT,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_triage_patient_time
  ON triage_events(patient_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_triage_tier
  ON triage_events(triage_tier);

-- ============================================================
-- TABLE: epds_scores  (Edinburgh Postnatal Depression Scale)
-- ============================================================
CREATE TABLE IF NOT EXISTS epds_scores (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id       UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  score            INTEGER NOT NULL CHECK (score BETWEEN 0 AND 30),
  flagged          BOOLEAN NOT NULL DEFAULT FALSE,   -- TRUE if score >= 12
  answers          JSONB,                            -- raw 10-question answers
  administered_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_epds_patient
  ON epds_scores(patient_id, administered_at DESC);

-- ============================================================
-- TABLE: alerts
-- ============================================================
CREATE TABLE IF NOT EXISTS alerts (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id   UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  provider_id  TEXT NOT NULL,   -- Firebase UID
  alert_type   TEXT NOT NULL CHECK (alert_type IN ('red_triage','bp_critical','epds_flagged','kick_count_low','anomaly_detected')),
  message      TEXT NOT NULL,
  read         BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_alerts_provider_unread
  ON alerts(provider_id, read, created_at DESC);

-- ============================================================
-- TABLE: messages
-- ============================================================
CREATE TABLE IF NOT EXISTS messages (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_id    TEXT NOT NULL,    -- Firebase UID
  receiver_id  TEXT NOT NULL,    -- Firebase UID
  content      TEXT NOT NULL,
  sent_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation
  ON messages(sender_id, receiver_id, sent_at DESC);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE patients       ENABLE ROW LEVEL SECURITY;
ALTER TABLE vitals_logs    ENABLE ROW LEVEL SECURITY;
ALTER TABLE triage_events  ENABLE ROW LEVEL SECURITY;
ALTER TABLE epds_scores    ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts         ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages       ENABLE ROW LEVEL SECURITY;

-- Providers can read all patients they own
CREATE POLICY "providers_read_own_patients"
  ON patients FOR SELECT
  USING (provider_id = auth.uid()::TEXT);

-- Patients can read their own record
CREATE POLICY "patients_read_self"
  ON patients FOR SELECT
  USING (id::TEXT = auth.uid()::TEXT);

-- Providers can insert/update patients
CREATE POLICY "providers_write_patients"
  ON patients FOR ALL
  USING (provider_id = auth.uid()::TEXT);

-- Vitals: patient can insert own, provider can read all for their patients
CREATE POLICY "patient_insert_vitals"
  ON vitals_logs FOR INSERT
  WITH CHECK (
    patient_id IN (SELECT id FROM patients WHERE id::TEXT = auth.uid()::TEXT)
  );

CREATE POLICY "provider_read_vitals"
  ON vitals_logs FOR SELECT
  USING (
    patient_id IN (SELECT id FROM patients WHERE provider_id = auth.uid()::TEXT)
    OR
    patient_id::TEXT = auth.uid()::TEXT
  );

-- Triage: patient can insert, provider can read
CREATE POLICY "patient_insert_triage"
  ON triage_events FOR INSERT
  WITH CHECK (
    patient_id IN (SELECT id FROM patients WHERE id::TEXT = auth.uid()::TEXT)
  );

CREATE POLICY "provider_read_triage"
  ON triage_events FOR SELECT
  USING (
    patient_id IN (SELECT id FROM patients WHERE provider_id = auth.uid()::TEXT)
    OR
    patient_id::TEXT = auth.uid()::TEXT
  );

-- EPDS: provider can read and insert
CREATE POLICY "provider_manage_epds"
  ON epds_scores FOR ALL
  USING (
    patient_id IN (SELECT id FROM patients WHERE provider_id = auth.uid()::TEXT)
  );

-- Alerts: only provider who owns them can read/update
CREATE POLICY "provider_manage_alerts"
  ON alerts FOR ALL
  USING (provider_id = auth.uid()::TEXT);

-- Messages: sender or receiver can read
CREATE POLICY "message_participants"
  ON messages FOR SELECT
  USING (sender_id = auth.uid()::TEXT OR receiver_id = auth.uid()::TEXT);

CREATE POLICY "message_sender_insert"
  ON messages FOR INSERT
  WITH CHECK (sender_id = auth.uid()::TEXT);

-- Service role bypass (used by Node API with service_role key)
-- Service role automatically bypasses RLS — no policy needed.
