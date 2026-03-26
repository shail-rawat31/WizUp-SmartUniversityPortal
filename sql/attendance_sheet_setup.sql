-- ==============================================================================
-- WIZUP - GOOGLE SHEETS → SUPABASE ATTENDANCE SYNC SETUP
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor → New Query)
-- ==============================================================================

-- ── 1. Add a unique constraint so we can UPSERT (no duplicate rows per student/subject/date) ──
ALTER TABLE public.attendance
  DROP CONSTRAINT IF EXISTS attendance_student_subject_date_unique;

ALTER TABLE public.attendance
  ADD CONSTRAINT attendance_student_subject_date_unique
  UNIQUE (student_id, subject_id, date);

-- ── 2. Create a helper lookup function: get profile ID from roll_no ──
CREATE OR REPLACE FUNCTION public.get_student_id_by_roll(p_roll TEXT)
RETURNS UUID
LANGUAGE sql SECURITY DEFINER
AS $$
  SELECT id FROM public.profiles WHERE roll_no = p_roll AND role = 'student' LIMIT 1;
$$;

-- ── 3. Create a helper lookup function: get subject ID by subject_code ──
CREATE OR REPLACE FUNCTION public.get_subject_id_by_code(p_code TEXT)
RETURNS UUID
LANGUAGE sql SECURITY DEFINER
AS $$
  SELECT id FROM public.subjects WHERE subject_code = p_code LIMIT 1;
$$;

-- ── 4. The main upsert function called by Google Apps Script ──
--    Called via Supabase REST: POST /rest/v1/rpc/upsert_attendance_from_sheet
CREATE OR REPLACE FUNCTION public.upsert_attendance_from_sheet(
  p_roll        TEXT,
  p_subject_code TEXT,
  p_date        DATE,
  p_status      TEXT   -- 'present' | 'absent' | 'leave'
)
RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  v_student_id  UUID;
  v_subject_id  UUID;
BEGIN
  -- Validate status value
  IF p_status NOT IN ('present', 'absent', 'leave') THEN
    RETURN json_build_object('error', 'Invalid status: ' || p_status);
  END IF;

  -- Resolve student
  SELECT id INTO v_student_id
  FROM public.profiles
  WHERE roll_no = p_roll AND role = 'student'
  LIMIT 1;

  IF v_student_id IS NULL THEN
    RETURN json_build_object('error', 'Student not found for roll: ' || p_roll);
  END IF;

  -- Resolve subject
  SELECT id INTO v_subject_id
  FROM public.subjects
  WHERE subject_code = p_subject_code
  LIMIT 1;

  IF v_subject_id IS NULL THEN
    RETURN json_build_object('error', 'Subject not found for code: ' || p_subject_code);
  END IF;

  -- Upsert attendance row
  INSERT INTO public.attendance (student_id, subject_id, date, status)
  VALUES (v_student_id, v_subject_id, p_date, p_status)
  ON CONFLICT (student_id, subject_id, date)
  DO UPDATE SET status = EXCLUDED.status;

  RETURN json_build_object(
    'success', true,
    'student_id', v_student_id,
    'subject_id', v_subject_id,
    'date', p_date,
    'status', p_status
  );
END;
$$;

-- ── 5. Grant execute to service_role (for Apps Script) and anon (optional) ──
GRANT EXECUTE ON FUNCTION public.upsert_attendance_from_sheet(TEXT, TEXT, DATE, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.upsert_attendance_from_sheet(TEXT, TEXT, DATE, TEXT) TO anon;

-- ── 6. Allow anon/service_role to read profiles and subjects for lookups ──
CREATE POLICY IF NOT EXISTS "Service role can insert attendance"
  ON public.attendance
  FOR INSERT
  TO service_role
  WITH CHECK (true);

CREATE POLICY IF NOT EXISTS "Service role can update attendance"
  ON public.attendance
  FOR UPDATE
  TO service_role
  USING (true);

-- ── 7. Enable Realtime on attendance table (for dashboard live updates) ──
-- Run in Supabase Dashboard → Database → Replication → enable 'attendance' table
-- OR run:
ALTER TABLE public.attendance REPLICA IDENTITY FULL;

-- ── 8. Refresh attendance_summary view (already exists, no changes needed) ──
-- The view automatically reflects upserted rows in real-time.

-- ==============================================================================
-- DONE. Note down your Supabase Service Role key from:
-- Dashboard → Project Settings → API → service_role (secret)
-- You will paste it into the Google Apps Script below.
-- ==============================================================================
