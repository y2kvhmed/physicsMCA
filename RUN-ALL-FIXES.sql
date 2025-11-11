-- ============================================
-- RUN ALL DATABASE FIXES
-- Copy and paste this ENTIRE file into Supabase SQL Editor and run it
-- ============================================

-- 1. DISABLE RLS ON ALL TABLES
ALTER TABLE IF EXISTS app_users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS schools DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS classes DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS assignments DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS submissions DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS lessons DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS study_materials DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS enrollments DISABLE ROW LEVEL SECURITY;

-- 2. MAKE STORAGE BUCKETS PUBLIC
UPDATE storage.buckets SET public = true WHERE id = 'lessons';
UPDATE storage.buckets SET public = true WHERE id = 'submissions';
UPDATE storage.buckets SET public = true WHERE id = 'materials';

-- 3. FIX ASSIGNMENTS TABLE
ALTER TABLE assignments ALTER COLUMN class_id DROP NOT NULL;
ALTER TABLE assignments ALTER COLUMN due_date DROP NOT NULL;
ALTER TABLE assignments ALTER COLUMN instructions DROP NOT NULL;
ALTER TABLE assignments ALTER COLUMN max_score DROP NOT NULL;

-- 4. FIX LESSONS TABLE
ALTER TABLE lessons ALTER COLUMN class_id DROP NOT NULL;
ALTER TABLE lessons ALTER COLUMN scheduled_at DROP NOT NULL;
ALTER TABLE lessons ALTER COLUMN duration_minutes DROP NOT NULL;

-- Add missing columns to lessons
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='lessons' AND column_name='video_path') THEN
        ALTER TABLE lessons ADD COLUMN video_path TEXT;
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='lessons' AND column_name='lesson_type') THEN
        ALTER TABLE lessons ADD COLUMN lesson_type TEXT DEFAULT 'video';
    END IF;
END $$;

-- 5. ADD CASCADE DELETE RULES
ALTER TABLE classes DROP CONSTRAINT IF EXISTS classes_school_id_fkey;
ALTER TABLE classes ADD CONSTRAINT classes_school_id_fkey 
FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE;

ALTER TABLE app_users DROP CONSTRAINT IF EXISTS app_users_school_id_fkey;
ALTER TABLE app_users ADD CONSTRAINT app_users_school_id_fkey 
FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE SET NULL;

ALTER TABLE assignments DROP CONSTRAINT IF EXISTS assignments_school_id_fkey;
ALTER TABLE assignments ADD CONSTRAINT assignments_school_id_fkey 
FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE;

ALTER TABLE lessons DROP CONSTRAINT IF EXISTS lessons_school_id_fkey;
ALTER TABLE lessons ADD CONSTRAINT lessons_school_id_fkey 
FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE;

ALTER TABLE study_materials DROP CONSTRAINT IF EXISTS study_materials_school_id_fkey;
ALTER TABLE study_materials ADD CONSTRAINT study_materials_school_id_fkey 
FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE;

ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_school_id_fkey;
ALTER TABLE messages ADD CONSTRAINT messages_school_id_fkey 
FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE;

-- SUCCESS MESSAGE
SELECT '✅ ALL FIXES APPLIED SUCCESSFULLY! Your app should work now.' as status;
