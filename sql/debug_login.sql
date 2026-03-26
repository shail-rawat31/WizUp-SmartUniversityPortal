-- ============================================================
-- WIZUP LOGIN DEBUGGER
-- Run each section in Supabase SQL Editor to diagnose login
-- ============================================================

-- STEP 1: Check if users exist in auth.users (Supabase auth table)
-- If this returns 0 rows, no accounts have been created at all.
SELECT id, email, created_at, email_confirmed_at
FROM auth.users
ORDER BY created_at DESC;

-- STEP 2: Check if profiles exist and have correct roles
-- If rows are missing, or role is NULL, login will be denied.
SELECT id, full_name, email, role, department, roll_no
FROM public.profiles
ORDER BY role;

-- STEP 3: Check for users in auth.users that LACK a profile
-- These users can authenticate but get "Access denied" because role check fails.
SELECT u.id, u.email
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE p.id IS NULL;

-- STEP 4: Fix missing profiles - insert manually for any user from Step 3
-- Replace the values below with the actual user's info from Step 3.
-- Uncomment and run ONLY for missing entries.
/*
INSERT INTO public.profiles (id, full_name, email, role, department, roll_no)
VALUES
  ('PASTE-USER-UUID-HERE', 'Student One', 'student1@wizup.edu', 'student', 'CSE', 'CSE2023001'),
  ('PASTE-USER-UUID-HERE', 'Faculty One', 'faculty1@wizup.edu', 'faculty', 'CSE', NULL),
  ('PASTE-USER-UUID-HERE', 'HOD Name',   'hod@wizup.edu',      'hod',     'CSE', NULL);
*/

-- STEP 5: Fix wrong roles - update if a user has an incorrect role
-- Example: update a user to 'student'
/*
UPDATE public.profiles
SET role = 'student'
WHERE email = 'student1@wizup.edu';
*/

-- STEP 6: Check email confirmation status
-- Supabase requires confirmed emails by default.
-- If email_confirmed_at is NULL, the user cannot log in.
SELECT email, email_confirmed_at,
  CASE WHEN email_confirmed_at IS NULL THEN 'NOT CONFIRMED ❌' ELSE 'CONFIRMED ✅' END AS status
FROM auth.users;

-- STEP 7: Bypass email confirmation for dev/testing (run if needed)
-- This confirms all unconfirmed users so they can log in immediately.
/*
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email_confirmed_at IS NULL;
*/
