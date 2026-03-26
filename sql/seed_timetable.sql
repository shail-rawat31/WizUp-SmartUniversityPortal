-- ==============================================================================
-- TT.jpg LIVE TIMETABLE SEEDER
-- Run this in Supabase SQL Editor to inject the real 23BCA-1 Timetable and auto-generate attendance
-- ==============================================================================

DO $$
DECLARE
  fac1 UUID := gen_random_uuid();
  fac2 UUID := gen_random_uuid();
  fac3 UUID := gen_random_uuid();
  fac4 UUID := gen_random_uuid();
  fac5 UUID := gen_random_uuid();
  fac6 UUID := gen_random_uuid();
  fac7 UUID := gen_random_uuid();
  fac8 UUID := gen_random_uuid();
  fac9 UUID := gen_random_uuid();
  fac10 UUID := gen_random_uuid();
  
  sub1 UUID := gen_random_uuid();
  sub2 UUID := gen_random_uuid();
  sub3 UUID := gen_random_uuid();
  sub4 UUID := gen_random_uuid();
  sub5 UUID := gen_random_uuid();
  sub6 UUID := gen_random_uuid();
  sub7 UUID := gen_random_uuid();
  sub8 UUID := gen_random_uuid();
  sub9 UUID := gen_random_uuid();
  sub10 UUID := gen_random_uuid();

  student_rec RECORD;
BEGIN

  -- 1. CLEANUP OLD SUBJECTS AND TIMETABLES (cascades attendance)
  DELETE FROM public.subjects;
  DELETE FROM public.profiles WHERE role = 'faculty';
  DELETE FROM auth.users WHERE email LIKE 'faculty%@wizup.edu';

  -- 2. INSERT REAL FACULTY INTO AUTO & PROFILES
  INSERT INTO public.profiles (id, full_name, role, department, employee_code) VALUES
    (fac1, 'Mr. Rahul Singh', 'faculty', 'Computer Science', 'E15602'),
    (fac2, 'Ms. Jasleen Kaur', 'faculty', 'Computer Science', 'E16528'),
    (fac3, 'Mr. Anup Kumar Singh', 'faculty', 'Computer Science', 'E13456'),
    (fac4, 'Ms. Jasmeet Kaur', 'faculty', 'Computer Science', 'E5466'),
    (fac5, 'Ms. Shivani Chadha', 'faculty', 'Computer Science', 'E16628'),
    (fac6, 'Er. Tarsem Singh', 'faculty', 'Automobile Engineering', 'E4148'),
    (fac7, 'Ms. Ambika', 'faculty', 'Computer Science', 'E16450'),
    (fac8, 'Ms. Bhawan Preet Kaur', 'faculty', 'Languages', 'E16432'),
    (fac9, 'Dr Kiran Shashwate', 'faculty', 'Management', 'E12368'),
    (fac10, 'Ms. Gurjit Kaur Parmar', 'faculty', 'Computer Science', 'E18408');

  -- 3. INSERT REAL SUBJECTS
  INSERT INTO public.subjects (id, subject_name, subject_code, faculty_id, department) VALUES
    (sub1, 'Aptitude_TPP', '23TDT-274', fac1, 'Computer Science'),
    (sub2, 'Multimedia and Animation software Lab', '23CAH-256', fac2, 'Computer Science'),
    (sub3, 'Database Management System Lab', '23CAP-252', fac3, 'Computer Science'),
    (sub4, 'Soft Skill_TPP', '23TDP-273', fac4, 'Computer Science'),
    (sub5, 'Artificial Intelligence', '23CAT-253', fac5, 'Computer Science'),
    (sub6, 'Automobile Engineering', 'MEO-361', fac6, 'Automobile Engineering'),
    (sub7, 'Gender Equality and Empowerment', '23UCT-297', fac7, 'Computer Science'),
    (sub8, 'Database Management System', '23CAT-251', fac3, 'Computer Science'),
    (sub9, 'French', 'LFO-441', fac8, 'Languages'),
    (sub10, 'Professional Tour and Planning', 'TTO-202', fac9, 'Management');

  -- 4. INSERT REAL TIMETABLE DATA from TT.jpg
  INSERT INTO public.timetable (subject_id, day, start_time, end_time, room) VALUES
    (sub1, 'Monday', '09:55', '11:25', 'Lecture Hall-414_E2Block'),
    (sub2, 'Monday', '11:25', '12:55', 'software Lab-307_E2Block'),
    (sub4, 'Monday', '14:25', '15:55', 'Soft Skill Lab-105_E2Block'),

    (sub5, 'Tuesday', '09:55', '11:25', 'Lecture Hall-404_E2Block'),
    (sub2, 'Tuesday', '11:25', '12:55', 'software Lab-209_E2Block'),
    (sub7, 'Tuesday', '13:40', '14:25', 'Lecture Hall-310_E2Block'),
    (sub8, 'Tuesday', '14:25', '15:55', 'Lecture Hall-310_E2Block'),

    (sub4, 'Wednesday', '09:55', '11:25', 'Soft Skill Lab-101_E2Block'),
    (sub9, 'Wednesday', '11:25', '12:10', 'Lecture Hall-312_E2Block'),
    (sub2, 'Wednesday', '12:55', '14:25', 'software Lab-304_E2Block'),
    (sub10, 'Wednesday', '14:25', '15:10', 'Lecture Hall-310_E2Block'),
    (sub6, 'Wednesday', '15:10', '15:55', 'Lecture Hall-228_E2Block'),

    (sub2, 'Thursday', '09:55', '10:40', 'Lecture Hall-227_E2Block'),
    (sub8, 'Thursday', '10:40', '11:25', 'Lecture Hall-504_E2Block'),
    (sub6, 'Thursday', '11:25', '12:10', 'Lecture Hall-228_E2Block'),
    (sub10, 'Thursday', '12:10', '12:55', 'Lecture Hall-408_E2Block'),
    (sub2, 'Thursday', '12:55', '14:25', 'Lecture Hall-116_E2Block'),
    (sub5, 'Thursday', '13:40', '14:25', 'Lecture Hall-309_E2Block'),
    (sub3, 'Thursday', '14:25', '15:55', 'software Lab-307_E2Block'),

    (sub8, 'Friday', '09:55', '11:25', 'Lecture Hall-311_E2Block'),
    (sub2, 'Friday', '10:40', '12:10', 'Lecture Hall-117_E2Block'),
    (sub10, 'Friday', '11:25', '12:55', 'Lecture Hall-310_E2Block'),
    (sub9, 'Friday', '12:10', '12:55', 'Lecture Hall-404_E2Block'),
    (sub4, 'Friday', '12:55', '14:25', 'Soft Skill Lab-101_E2Block');

  -- 5. GENERATE DYNAMIC ATTENDANCE FOR EXISTING STUDENTS BASED ON NEW SUBJECTS
  FOR student_rec IN SELECT id FROM public.profiles WHERE role = 'student' LOOP
    FOR i IN 1..10 LOOP
      FOR j IN 1..15 LOOP -- Simulate 15 past classes per subject
        INSERT INTO public.attendance (student_id, subject_id, date, status)
        VALUES (
          student_rec.id, 
          CASE i 
            WHEN 1 THEN sub1 WHEN 2 THEN sub2 WHEN 3 THEN sub3 WHEN 4 THEN sub4 WHEN 5 THEN sub5
            WHEN 6 THEN sub6 WHEN 7 THEN sub7 WHEN 8 THEN sub8 WHEN 9 THEN sub9 WHEN 10 THEN sub10
          END,
          CURRENT_DATE - j, 
          -- Random attendance (82% present)
          CASE WHEN random() > 0.18 THEN 'present' ELSE 'absent' END
        );
      END LOOP;
    END LOOP;
  END LOOP;

END $$;
