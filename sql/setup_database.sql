-- ==============================================================================
-- WIZUP UNIVERSITY PORTAL - SAFE PRODUCTION SETUP
-- ==============================================================================

-- ==========================
-- 1. EXTENSIONS
-- ==========================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ==========================
-- 2. PROFILES TABLE (linked to auth.users)
-- ==========================
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  role TEXT CHECK (role IN ('student','faculty','hod','admin')),
  department TEXT,
  employee_code TEXT,
  roll_no TEXT,
  email TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================
-- 3. SUBJECTS
-- ==========================
CREATE TABLE IF NOT EXISTS public.subjects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_name TEXT NOT NULL,
  subject_code TEXT,
  faculty_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  department TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================
-- 4. TIMETABLE
-- ==========================
CREATE TABLE IF NOT EXISTS public.timetable (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
  day TEXT,
  start_time TEXT,
  end_time TEXT,
  room TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================
-- 5. ATTENDANCE
-- ==========================
CREATE TABLE IF NOT EXISTS public.attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  status TEXT CHECK (status IN ('present','absent','leave')),
  marked_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================
-- 6. INTERNAL MARKS
-- ==========================
CREATE TABLE IF NOT EXISTS public.internal_marks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
  assignment_marks INTEGER DEFAULT 0,
  mst_marks INTEGER DEFAULT 0,
  attendance_marks INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================
-- 7. STUDENT LEAVES
-- ==========================
CREATE TABLE IF NOT EXISTS public.leaves (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT CHECK (type IN ('medical','general','duty')),
  start_date DATE,
  end_date DATE,
  status TEXT CHECK (status IN ('pending','approved','rejected')) DEFAULT 'pending',
  hod_comment TEXT,
  reason TEXT,
  description TEXT,
  documents BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================
-- 8. FACULTY LEAVES
-- ==========================
CREATE TABLE IF NOT EXISTS public.faculty_leaves (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  faculty_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT,
  start_date DATE,
  end_date DATE,
  reason TEXT,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================
-- 9. ANNOUNCEMENTS
-- ==========================
CREATE TABLE IF NOT EXISTS public.announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  posted_by UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================
-- 10. ASSIGNMENTS
-- ==========================
CREATE TABLE IF NOT EXISTS public.assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  faculty_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  deadline TIMESTAMPTZ,
  max_marks INTEGER DEFAULT 10,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================
-- 11. VIEWS
-- ==========================

CREATE OR REPLACE VIEW attendance_summary AS
SELECT
  student_id,
  subject_id,
  COUNT(*) AS total_classes,
  SUM(CASE WHEN status IN ('present','leave') THEN 1 ELSE 0 END) AS attended,
  ROUND(
    SUM(CASE WHEN status IN ('present','leave') THEN 1 ELSE 0 END)::NUMERIC /
    NULLIF(COUNT(*),0) * 100, 2
  ) AS percentage
FROM public.attendance
GROUP BY student_id, subject_id;

CREATE OR REPLACE VIEW detention_list AS
SELECT student_id, ROUND(AVG(percentage),2) AS percentage
FROM attendance_summary
GROUP BY student_id
HAVING AVG(percentage) < 75;

-- ==========================
-- 12. ENABLE ROW LEVEL SECURITY
-- ==========================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.internal_marks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leaves ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.faculty_leaves ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;

-- ==========================
-- 13. POLICIES
-- ==========================

-- Profiles
CREATE POLICY "Users can view own profile"
ON public.profiles
FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
ON public.profiles
FOR UPDATE
USING (auth.uid() = id);

-- Subjects
CREATE POLICY "Authenticated users can read subjects"
ON public.subjects
FOR SELECT
TO authenticated
USING (true);

-- Attendance
CREATE POLICY "Students can view own attendance"
ON public.attendance
FOR SELECT
USING (auth.uid() = student_id);

-- Leaves
CREATE POLICY "Students manage own leaves"
ON public.leaves
FOR ALL
USING (auth.uid() = student_id);

-- Announcements
CREATE POLICY "Authenticated users can read announcements"
ON public.announcements
FOR SELECT
TO authenticated
USING (true);

-- ==========================
-- 14. AUTO CREATE PROFILE ON SIGNUP
-- ==========================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'student')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- END OF SETUP
-- ==============================================================================
