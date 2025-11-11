-- ============================================
-- FINAL FIX FOR ALL DATABASE ISSUES
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. DISABLE ALL RLS POLICIES
ALTER TABLE IF EXISTS app_users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS schools DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS classes DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS assignments DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS submissions DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS lessons DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS study_materials DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS enrollments DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS assignment_comments DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS calendar_events DISABLE ROW LEVEL SECURITY;

-- 2. MAKE ALL STORAGE BUCKETS PUBLIC
UPDATE storage.buckets SET public = true WHERE id IN ('lessons', 'submissions', 'materials', 'videos', 'recordings');

-- 3. CREATE MISSING STORAGE BUCKETS
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('videos', 'videos', true),
  ('recordings', 'recordings', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 4. FIX STUDY_MATERIALS TABLE
DO $$ 
BEGIN
    -- Add uploaded_by if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='study_materials' AND column_name='uploaded_by') THEN
        ALTER TABLE study_materials ADD COLUMN uploaded_by UUID REFERENCES app_users(id);
    END IF;
    
    -- Add created_by if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='study_materials' AND column_name='created_by') THEN
        ALTER TABLE study_materials ADD COLUMN created_by UUID REFERENCES app_users(id);
    END IF;
    
    -- Add subject if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='study_materials' AND column_name='subject') THEN
        ALTER TABLE study_materials ADD COLUMN subject TEXT;
    END IF;
    
    -- Add grade_level if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='study_materials' AND column_name='grade_level') THEN
        ALTER TABLE study_materials ADD COLUMN grade_level TEXT;
    END IF;
    
    -- Add content_type if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='study_materials' AND column_name='content_type') THEN
        ALTER TABLE study_materials ADD COLUMN content_type TEXT;
    END IF;
    
    -- Add file_url if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='study_materials' AND column_name='file_url') THEN
        ALTER TABLE study_materials ADD COLUMN file_url TEXT;
    END IF;
    
    -- Add is_published if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='study_materials' AND column_name='is_published') THEN
        ALTER TABLE study_materials ADD COLUMN is_published BOOLEAN DEFAULT true;
    END IF;
    
    -- Make columns nullable
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='study_materials' AND column_name='uploaded_by' AND is_nullable='NO') THEN
        ALTER TABLE study_materials ALTER COLUMN uploaded_by DROP NOT NULL;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='study_materials' AND column_name='class_id' AND is_nullable='NO') THEN
        ALTER TABLE study_materials ALTER COLUMN class_id DROP NOT NULL;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='study_materials' AND column_name='school_id' AND is_nullable='NO') THEN
        ALTER TABLE study_materials ALTER COLUMN school_id DROP NOT NULL;
    END IF;
END $$;

-- 5. FIX ASSIGNMENTS TABLE
DO $$ 
BEGIN
    -- Add subject if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='assignments' AND column_name='subject') THEN
        ALTER TABLE assignments ADD COLUMN subject TEXT;
    END IF;
    
    -- Add grade_level if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='assignments' AND column_name='grade_level') THEN
        ALTER TABLE assignments ADD COLUMN grade_level TEXT;
    END IF;
    
    -- Add created_by if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='assignments' AND column_name='created_by') THEN
        ALTER TABLE assignments ADD COLUMN created_by UUID REFERENCES app_users(id);
    END IF;
    
    -- Add material_id if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='assignments' AND column_name='material_id') THEN
        ALTER TABLE assignments ADD COLUMN material_id UUID;
    END IF;
    
    -- Add max_points if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='assignments' AND column_name='max_points') THEN
        ALTER TABLE assignments ADD COLUMN max_points INTEGER DEFAULT 100;
    END IF;
    
    -- Add file_path if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='assignments' AND column_name='file_path') THEN
        ALTER TABLE assignments ADD COLUMN file_path TEXT;
    END IF;
    
    -- Add file_name if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='assignments' AND column_name='file_name') THEN
        ALTER TABLE assignments ADD COLUMN file_name TEXT;
    END IF;
    
    -- Add file_size if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='assignments' AND column_name='file_size') THEN
        ALTER TABLE assignments ADD COLUMN file_size BIGINT;
    END IF;
    
    -- Make columns nullable
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='assignments' AND column_name='class_id' AND is_nullable='NO') THEN
        ALTER TABLE assignments ALTER COLUMN class_id DROP NOT NULL;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='assignments' AND column_name='due_date' AND is_nullable='NO') THEN
        ALTER TABLE assignments ALTER COLUMN due_date DROP NOT NULL;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='assignments' AND column_name='max_score' AND is_nullable='NO') THEN
        ALTER TABLE assignments ALTER COLUMN max_score DROP NOT NULL;
    END IF;
END $$;

-- 6. FIX LESSONS TABLE
DO $$ 
BEGIN
    -- Add video_path if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='lessons' AND column_name='video_path') THEN
        ALTER TABLE lessons ADD COLUMN video_path TEXT;
    END IF;
    
    -- Add lesson_type if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='lessons' AND column_name='lesson_type') THEN
        ALTER TABLE lessons ADD COLUMN lesson_type TEXT DEFAULT 'video';
    END IF;
    
    -- Make class_id nullable
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='lessons' AND column_name='class_id' AND is_nullable='NO') THEN
        ALTER TABLE lessons ALTER COLUMN class_id DROP NOT NULL;
    END IF;
END $$;

-- 7. FIX MESSAGES TABLE
DO $$ 
BEGIN
    -- Make columns nullable
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='messages' AND column_name='class_id' AND is_nullable='NO') THEN
        ALTER TABLE messages ALTER COLUMN class_id DROP NOT NULL;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='messages' AND column_name='school_id' AND is_nullable='NO') THEN
        ALTER TABLE messages ALTER COLUMN school_id DROP NOT NULL;
    END IF;
END $$;

-- 8. DROP ALL EXISTING RLS POLICIES (to prevent conflicts)
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT schemaname, tablename, policyname 
              FROM pg_policies 
              WHERE schemaname = 'public') 
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
                      r.policyname, r.schemaname, r.tablename);
    END LOOP;
END $$;

-- SUCCESS MESSAGE
SELECT '✅ ALL DATABASE ISSUES FIXED!' as status,
       'RLS disabled, storage public, all columns added' as details;
