-- ============================================
-- COMPLETE FIX - RUN THIS ONE FILE
-- This combines all fixes into one script
-- ============================================

-- 1. DISABLE ALL RLS
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

-- 2. DROP ALL EXISTING RLS POLICIES
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

-- 3. CREATE/UPDATE STORAGE BUCKETS (allow all mime types)
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('videos', 'videos', true),
  ('recordings', 'recordings', true),
  ('lessons', 'lessons', true),
  ('submissions', 'submissions', true),
  ('materials', 'materials', true),
  ('chat-files', 'chat-files', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Remove mime type restrictions (NULL = all types allowed)
UPDATE storage.buckets 
SET allowed_mime_types = NULL
WHERE id IN ('videos', 'recordings', 'lessons', 'submissions', 'materials', 'chat-files');

-- 4. FIX STUDY_MATERIALS TABLE
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='study_materials' AND column_name='uploaded_by') THEN
        ALTER TABLE study_materials ADD COLUMN uploaded_by UUID REFERENCES app_users(id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='study_materials' AND column_name='created_by') THEN
        ALTER TABLE study_materials ADD COLUMN created_by UUID REFERENCES app_users(id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='study_materials' AND column_name='subject') THEN
        ALTER TABLE study_materials ADD COLUMN subject TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='study_materials' AND column_name='grade_level') THEN
        ALTER TABLE study_materials ADD COLUMN grade_level TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='study_materials' AND column_name='content_type') THEN
        ALTER TABLE study_materials ADD COLUMN content_type TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='study_materials' AND column_name='file_url') THEN
        ALTER TABLE study_materials ADD COLUMN file_url TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='study_materials' AND column_name='is_published') THEN
        ALTER TABLE study_materials ADD COLUMN is_published BOOLEAN DEFAULT true;
    END IF;
    
    -- Make columns nullable
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='study_materials' AND column_name='uploaded_by' AND is_nullable='NO') THEN
        ALTER TABLE study_materials ALTER COLUMN uploaded_by DROP NOT NULL;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='study_materials' AND column_name='class_id' AND is_nullable='NO') THEN
        ALTER TABLE study_materials ALTER COLUMN class_id DROP NOT NULL;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='study_materials' AND column_name='school_id' AND is_nullable='NO') THEN
        ALTER TABLE study_materials ALTER COLUMN school_id DROP NOT NULL;
    END IF;
END $$;

-- 5. FIX ASSIGNMENTS TABLE
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='assignments' AND column_name='subject') THEN
        ALTER TABLE assignments ADD COLUMN subject TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='assignments' AND column_name='grade_level') THEN
        ALTER TABLE assignments ADD COLUMN grade_level TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='assignments' AND column_name='created_by') THEN
        ALTER TABLE assignments ADD COLUMN created_by UUID REFERENCES app_users(id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='assignments' AND column_name='material_id') THEN
        ALTER TABLE assignments ADD COLUMN material_id UUID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='assignments' AND column_name='max_points') THEN
        ALTER TABLE assignments ADD COLUMN max_points INTEGER DEFAULT 100;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='assignments' AND column_name='file_path') THEN
        ALTER TABLE assignments ADD COLUMN file_path TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='assignments' AND column_name='file_name') THEN
        ALTER TABLE assignments ADD COLUMN file_name TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='assignments' AND column_name='file_size') THEN
        ALTER TABLE assignments ADD COLUMN file_size BIGINT;
    END IF;
    
    -- Make columns nullable
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='assignments' AND column_name='class_id' AND is_nullable='NO') THEN
        ALTER TABLE assignments ALTER COLUMN class_id DROP NOT NULL;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='assignments' AND column_name='due_date' AND is_nullable='NO') THEN
        ALTER TABLE assignments ALTER COLUMN due_date DROP NOT NULL;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='assignments' AND column_name='max_score' AND is_nullable='NO') THEN
        ALTER TABLE assignments ALTER COLUMN max_score DROP NOT NULL;
    END IF;
END $$;

-- 6. FIX LESSONS TABLE
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='lessons' AND column_name='video_path') THEN
        ALTER TABLE lessons ADD COLUMN video_path TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='lessons' AND column_name='lesson_type') THEN
        ALTER TABLE lessons ADD COLUMN lesson_type TEXT DEFAULT 'video';
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='lessons' AND column_name='class_id' AND is_nullable='NO') THEN
        ALTER TABLE lessons ALTER COLUMN class_id DROP NOT NULL;
    END IF;
END $$;

-- 7. FIX MESSAGES TABLE
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='messages' AND column_name='is_pinned') THEN
        ALTER TABLE messages ADD COLUMN is_pinned BOOLEAN DEFAULT false;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='messages' AND column_name='priority') THEN
        ALTER TABLE messages ADD COLUMN priority TEXT DEFAULT 'normal';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='messages' AND column_name='metadata') THEN
        ALTER TABLE messages ADD COLUMN metadata JSONB;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='messages' AND column_name='file_type') THEN
        ALTER TABLE messages ADD COLUMN file_type TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='messages' AND column_name='file_path') THEN
        ALTER TABLE messages ADD COLUMN file_path TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='messages' AND column_name='file_name') THEN
        ALTER TABLE messages ADD COLUMN file_name TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='messages' AND column_name='file_size') THEN
        ALTER TABLE messages ADD COLUMN file_size BIGINT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='messages' AND column_name='title') THEN
        ALTER TABLE messages ADD COLUMN title TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='messages' AND column_name='message_type') THEN
        ALTER TABLE messages ADD COLUMN message_type TEXT DEFAULT 'text';
    END IF;
    
    -- Make columns nullable
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='messages' AND column_name='class_id' AND is_nullable='NO') THEN
        ALTER TABLE messages ALTER COLUMN class_id DROP NOT NULL;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='messages' AND column_name='school_id' AND is_nullable='NO') THEN
        ALTER TABLE messages ALTER COLUMN school_id DROP NOT NULL;
    END IF;
END $$;

-- SUCCESS
SELECT '✅ ALL FIXES APPLIED SUCCESSFULLY!' as status,
       'RLS disabled, storage configured, all columns added' as details;
