-- Run this in Supabase SQL Editor to update attendance table
-- This replaces the old check_in/check_out model with admin-controlled present/absent

-- Drop old attendance table if exists
DROP TABLE IF EXISTS public.attendance CASCADE;

-- Create new attendance table (admin marks present/absent per student per day)
CREATE TABLE IF NOT EXISTS public.attendance (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    date        DATE NOT NULL DEFAULT CURRENT_DATE,
    status      TEXT NOT NULL CHECK (status IN ('present', 'absent')),
    marked_by   UUID REFERENCES public.users(id),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Only one record per student per day
    UNIQUE(student_id, date)
);

CREATE INDEX IF NOT EXISTS idx_attendance_student ON public.attendance(student_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date    ON public.attendance(date DESC);

-- Enable RLS
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

-- Students can view their own attendance
CREATE POLICY "Students view own attendance"
    ON public.attendance FOR SELECT
    USING (auth.uid() = student_id OR is_admin());

-- Only admin/warden can insert/update attendance
CREATE POLICY "Admin marks attendance"
    ON public.attendance FOR INSERT
    WITH CHECK (is_admin());

CREATE POLICY "Admin updates attendance"
    ON public.attendance FOR UPDATE
    USING (is_admin());

-- Sample attendance data for demo student
-- Replace 'student@demo.com' student ID below after running schema.sql
INSERT INTO public.attendance (student_id, date, status, marked_by)
SELECT 
    u.id,
    CURRENT_DATE,
    'present',
    a.id
FROM public.users u, public.users a
WHERE u.email = 'student@demo.com' AND a.email = 'admin@demo.com'
ON CONFLICT (student_id, date) DO NOTHING;

INSERT INTO public.attendance (student_id, date, status, marked_by)
SELECT 
    u.id,
    CURRENT_DATE - 1,
    'absent',
    a.id
FROM public.users u, public.users a
WHERE u.email = 'student@demo.com' AND a.email = 'admin@demo.com'
ON CONFLICT (student_id, date) DO NOTHING;

INSERT INTO public.attendance (student_id, date, status, marked_by)
SELECT 
    u.id,
    CURRENT_DATE - 2,
    'present',
    a.id
FROM public.users u, public.users a
WHERE u.email = 'student@demo.com' AND a.email = 'admin@demo.com'
ON CONFLICT (student_id, date) DO NOTHING;
