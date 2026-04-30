-- ============================================================
-- HOSTELHUB - Complete Supabase Database Schema
-- Run this in Supabase SQL Editor (supabase.com → SQL Editor)
-- ============================================================

-- ─── Enable UUID Extension ────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─── USERS TABLE ──────────────────────────────────────────────────────────────
-- Extends Supabase auth.users with app-specific profile data
CREATE TABLE IF NOT EXISTS public.users (
    id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name        TEXT NOT NULL,
    email       TEXT NOT NULL UNIQUE,
    role        TEXT NOT NULL DEFAULT 'student'
                    CHECK (role IN ('student', 'admin', 'warden')),
    usn         TEXT UNIQUE,                     -- University Serial Number
    phone       TEXT,
    profile_image_url TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast role-based queries
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_usn ON public.users(usn);

-- ─── ROOMS TABLE ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.rooms (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_number  TEXT NOT NULL UNIQUE,
    floor        TEXT NOT NULL,
    type         TEXT NOT NULL DEFAULT 'double'
                     CHECK (type IN ('single', 'double', 'triple')),
    capacity     INT NOT NULL CHECK (capacity BETWEEN 1 AND 10),
    occupancy    INT NOT NULL DEFAULT 0 CHECK (occupancy >= 0),
    status       TEXT NOT NULL DEFAULT 'available'
                     CHECK (status IN ('available', 'full', 'maintenance')),
    monthly_rent DECIMAL(10,2),
    amenities    JSONB,                           -- e.g. {"wifi": true, "ac": false}
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Ensure occupancy never exceeds capacity
    CONSTRAINT occupancy_within_capacity CHECK (occupancy <= capacity)
);

CREATE INDEX IF NOT EXISTS idx_rooms_status ON public.rooms(status);
CREATE INDEX IF NOT EXISTS idx_rooms_floor ON public.rooms(floor);

-- ─── ALLOCATIONS TABLE ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.allocations (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id   UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    room_id      UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
    allocated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    vacated_at   TIMESTAMPTZ,
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_allocations_student ON public.allocations(student_id);
CREATE INDEX IF NOT EXISTS idx_allocations_room    ON public.allocations(room_id);
CREATE INDEX IF NOT EXISTS idx_allocations_active  ON public.allocations(is_active);

-- Only one active allocation per student
CREATE UNIQUE INDEX IF NOT EXISTS idx_allocations_active_student
    ON public.allocations(student_id)
    WHERE is_active = TRUE;

-- ─── COMPLAINTS TABLE ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.complaints (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title       TEXT NOT NULL CHECK (length(title) BETWEEN 5 AND 200),
    description TEXT NOT NULL CHECK (length(description) >= 10),
    category    TEXT NOT NULL DEFAULT 'other'
                    CHECK (category IN (
                        'maintenance', 'food', 'cleanliness',
                        'security', 'electricity', 'water',
                        'internet', 'other'
                    )),
    status      TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'in_progress', 'resolved')),
    image_url   TEXT,
    admin_note  TEXT,
    resolved_by UUID REFERENCES public.users(id),
    resolved_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_complaints_student ON public.complaints(student_id);
CREATE INDEX IF NOT EXISTS idx_complaints_status  ON public.complaints(status);
CREATE INDEX IF NOT EXISTS idx_complaints_created ON public.complaints(created_at DESC);

-- ─── ATTENDANCE TABLE ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.attendance (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    check_in   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    check_out  TIMESTAMPTZ,
    notes      TEXT,
    -- check_out must be after check_in
    CONSTRAINT checkout_after_checkin
        CHECK (check_out IS NULL OR check_out > check_in)
);

CREATE INDEX IF NOT EXISTS idx_attendance_student ON public.attendance(student_id);
CREATE INDEX IF NOT EXISTS idx_attendance_checkin ON public.attendance(check_in DESC);

-- ─── FEES TABLE ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.fees (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    amount         DECIMAL(10,2) NOT NULL CHECK (amount > 0),
    status         TEXT NOT NULL DEFAULT 'pending'
                       CHECK (status IN ('paid', 'pending', 'overdue')),
    fee_type       TEXT NOT NULL DEFAULT 'hostel'
                       CHECK (fee_type IN (
                           'hostel', 'mess', 'security_deposit', 'laundry', 'other'
                       )),
    month          TEXT NOT NULL,                -- Format: '2024-01'
    due_date       TIMESTAMPTZ NOT NULL,
    paid_at        TIMESTAMPTZ,
    transaction_id TEXT,
    receipt_url    TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fees_student ON public.fees(student_id);
CREATE INDEX IF NOT EXISTS idx_fees_status  ON public.fees(status);
CREATE INDEX IF NOT EXISTS idx_fees_due     ON public.fees(due_date);

-- ─── NOTIFICATIONS TABLE ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.notifications (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id    UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title      TEXT NOT NULL,
    body       TEXT NOT NULL,
    type       TEXT NOT NULL DEFAULT 'general'
                   CHECK (type IN (
                       'complaint_update', 'fee_reminder',
                       'general', 'maintenance', 'announcement'
                   )),
    is_read    BOOLEAN NOT NULL DEFAULT FALSE,
    data       JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user   ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread
    ON public.notifications(user_id, is_read)
    WHERE is_read = FALSE;

-- ─── UPDATED_AT TRIGGER ───────────────────────────────────────────────────────
-- Auto-update updated_at column on any change
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_complaints_updated_at
    BEFORE UPDATE ON public.complaints
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- ─── AUTO-CREATE USER PROFILE TRIGGER ────────────────────────────────────────
-- When a user registers via Supabase Auth, automatically insert into public.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, name, email, role, usn, created_at)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'name', 'New User'),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'role', 'student'),
        NEW.raw_user_meta_data->>'usn',
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop if exists and recreate
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ─── AUTO-UPDATE ROOM OCCUPANCY TRIGGER ──────────────────────────────────────
-- Auto-updates room occupancy and status when allocations change
CREATE OR REPLACE FUNCTION update_room_occupancy()
RETURNS TRIGGER AS $$
DECLARE
    v_count INT;
    v_capacity INT;
BEGIN
    -- Get current active occupancy for the room
    IF TG_OP = 'DELETE' OR (TG_OP = 'UPDATE' AND OLD.is_active = TRUE AND NEW.is_active = FALSE) THEN
        SELECT COUNT(*) INTO v_count
        FROM public.allocations
        WHERE room_id = COALESCE(OLD.room_id, NEW.room_id)
          AND is_active = TRUE
          AND id != COALESCE(OLD.id, NEW.id);
    ELSE
        SELECT COUNT(*) INTO v_count
        FROM public.allocations
        WHERE room_id = COALESCE(NEW.room_id, OLD.room_id)
          AND is_active = TRUE;
    END IF;

    SELECT capacity INTO v_capacity
    FROM public.rooms
    WHERE id = COALESCE(NEW.room_id, OLD.room_id);

    UPDATE public.rooms
    SET
        occupancy = v_count,
        status = CASE
            WHEN v_count >= v_capacity THEN 'full'
            ELSE 'available'
        END
    WHERE id = COALESCE(NEW.room_id, OLD.room_id)
      AND status != 'maintenance';

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_allocation_change
    AFTER INSERT OR UPDATE OR DELETE ON public.allocations
    FOR EACH ROW EXECUTE PROCEDURE update_room_occupancy();

-- ─── AUTO-NOTIFICATION ON COMPLAINT STATUS UPDATE ─────────────────────────────
CREATE OR REPLACE FUNCTION notify_complaint_update()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO public.notifications (user_id, title, body, type, data)
        VALUES (
            NEW.student_id,
            'Complaint Update',
            'Your complaint "' || LEFT(NEW.title, 50) || '" is now ' ||
                REPLACE(NEW.status, '_', ' '),
            'complaint_update',
            jsonb_build_object('complaint_id', NEW.id, 'status', NEW.status)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_complaint_status_change
    AFTER UPDATE OF status ON public.complaints
    FOR EACH ROW EXECUTE PROCEDURE notify_complaint_update();

-- ─── ROW LEVEL SECURITY ───────────────────────────────────────────────────────
-- Enable RLS on all tables
ALTER TABLE public.users          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.allocations    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.complaints     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fees           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications  ENABLE ROW LEVEL SECURITY;

-- Helper function: check if current user is admin/warden
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid()
          AND role IN ('admin', 'warden')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── USERS RLS POLICIES ───────────────────────────────────────────────────────
-- Users can view their own profile; admins can view all
CREATE POLICY "Users can view own profile"
    ON public.users FOR SELECT
    USING (auth.uid() = id OR is_admin());

-- Users can update own profile
CREATE POLICY "Users can update own profile"
    ON public.users FOR UPDATE
    USING (auth.uid() = id);

-- Anyone can insert (triggered from auth signup)
CREATE POLICY "Allow profile creation"
    ON public.users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- ─── ROOMS RLS POLICIES ───────────────────────────────────────────────────────
-- All authenticated users can view rooms
CREATE POLICY "Authenticated users can view rooms"
    ON public.rooms FOR SELECT
    TO authenticated
    USING (TRUE);

-- Only admins can modify rooms
CREATE POLICY "Admins can manage rooms"
    ON public.rooms FOR ALL
    USING (is_admin())
    WITH CHECK (is_admin());

-- ─── ALLOCATIONS RLS POLICIES ─────────────────────────────────────────────────
-- Students see own allocation; admins see all
CREATE POLICY "View own allocation"
    ON public.allocations FOR SELECT
    USING (auth.uid() = student_id OR is_admin());

-- Only admins can create/modify allocations
CREATE POLICY "Admins manage allocations"
    ON public.allocations FOR INSERT
    WITH CHECK (is_admin());

CREATE POLICY "Admins update allocations"
    ON public.allocations FOR UPDATE
    USING (is_admin());

-- ─── COMPLAINTS RLS POLICIES ──────────────────────────────────────────────────
-- Students see own complaints; admins see all
CREATE POLICY "View complaints"
    ON public.complaints FOR SELECT
    USING (auth.uid() = student_id OR is_admin());

-- Students can create complaints
CREATE POLICY "Students create complaints"
    ON public.complaints FOR INSERT
    WITH CHECK (auth.uid() = student_id);

-- Admins can update any complaint; students cannot
CREATE POLICY "Admins update complaints"
    ON public.complaints FOR UPDATE
    USING (is_admin());

-- ─── ATTENDANCE RLS POLICIES ──────────────────────────────────────────────────
-- Students see own attendance; admins see all
CREATE POLICY "View own attendance"
    ON public.attendance FOR SELECT
    USING (auth.uid() = student_id OR is_admin());

-- Students can insert their own attendance
CREATE POLICY "Students insert attendance"
    ON public.attendance FOR INSERT
    WITH CHECK (auth.uid() = student_id);

-- Students can update own (for check-out); admins can update all
CREATE POLICY "Update attendance"
    ON public.attendance FOR UPDATE
    USING (auth.uid() = student_id OR is_admin());

-- ─── FEES RLS POLICIES ────────────────────────────────────────────────────────
-- Students see own fees; admins see all
CREATE POLICY "View own fees"
    ON public.fees FOR SELECT
    USING (auth.uid() = student_id OR is_admin());

-- Only admins create fees
CREATE POLICY "Admins create fees"
    ON public.fees FOR INSERT
    WITH CHECK (is_admin());

-- Students can mark own fees as paid; admins can update any
CREATE POLICY "Update fees"
    ON public.fees FOR UPDATE
    USING (auth.uid() = student_id OR is_admin());

-- ─── NOTIFICATIONS RLS POLICIES ───────────────────────────────────────────────
-- Users see only their own notifications
CREATE POLICY "View own notifications"
    ON public.notifications FOR SELECT
    USING (auth.uid() = user_id);

-- System/admin can insert notifications for any user
CREATE POLICY "Insert notifications"
    ON public.notifications FOR INSERT
    WITH CHECK (is_admin() OR auth.uid() = user_id);

-- Users can update own (mark as read)
CREATE POLICY "Update own notifications"
    ON public.notifications FOR UPDATE
    USING (auth.uid() = user_id);

-- ─── SUPABASE STORAGE BUCKETS ─────────────────────────────────────────────────
-- Run these manually in Storage section OR via SQL:

INSERT INTO storage.buckets (id, name, public)
VALUES ('complaint-images', 'complaint-images', TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-images', 'profile-images', TRUE)
ON CONFLICT DO NOTHING;

-- Storage policies for complaint images
CREATE POLICY "Authenticated users upload complaint images"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'complaint-images');

CREATE POLICY "Public read complaint images"
    ON storage.objects FOR SELECT
    TO public
    USING (bucket_id = 'complaint-images');

-- ─── SEED DATA ────────────────────────────────────────────────────────────────
-- Sample rooms (run after creating the tables)

INSERT INTO public.rooms (id, room_number, floor, type, capacity, occupancy, status, monthly_rent)
VALUES
    ('11111111-1111-1111-1111-111111111101', '101', 'Ground', 'double', 2, 0, 'available', 5000),
    ('11111111-1111-1111-1111-111111111102', '102', 'Ground', 'triple', 3, 0, 'available', 4500),
    ('11111111-1111-1111-1111-111111111103', '103', 'Ground', 'single', 1, 0, 'available', 6000),
    ('11111111-1111-1111-1111-111111111201', '201', 'First',  'double', 2, 0, 'available', 5200),
    ('11111111-1111-1111-1111-111111111202', '202', 'First',  'double', 2, 0, 'maintenance', 5200),
    ('11111111-1111-1111-1111-111111111203', '203', 'First',  'triple', 3, 0, 'available', 4700),
    ('11111111-1111-1111-1111-111111111301', '301', 'Second', 'single', 1, 0, 'available', 6500),
    ('11111111-1111-1111-1111-111111111302', '302', 'Second', 'double', 2, 0, 'available', 5500),
    ('11111111-1111-1111-1111-111111111303', '303', 'Second', 'triple', 3, 0, 'available', 4800)
ON CONFLICT DO NOTHING;

-- NOTE: Create admin user via Supabase Auth UI (Authentication → Users → Add User)
-- Then run this to set admin role (replace the UUID with actual admin user ID):
-- UPDATE public.users SET role = 'admin' WHERE email = 'admin@demo.com';

-- ─── GRANT PERMISSIONS ────────────────────────────────────────────────────────
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;
