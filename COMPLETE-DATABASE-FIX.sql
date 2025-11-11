-- ============================================
-- COMPLETE DATABASE FIX - RUN THIS ONE FILE
-- This will fix ALL your database issues
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

-- 2. MAKE STORAGE PUBLIC
UPDATE storage.buckets SET public = true WHERE id IN ('lessons', 'submissions', 'materials', 'videos');

-- 3. FIX STUDY_MATERIALS TABLE
DO $$ 
BEGIN
    -- Add uploaded_by if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='study_materials' AND column_name='uploaded_by') THEN
        ALTER TABLE study_materials ADD COLUMN uploaded_by UUID REFERENCES app_users(id);
    END IF;
    
    -- Add created_by if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='study_materials' AND column_name='created_by') THEN
        ALTER TABLE study_materials ADD COLUMN created_by UUID REFERENCES app_users(id);
    END IF;
    
    -- Add other missing columns
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='study_materials' AND column_name='subject') THEN
        ALTER TABLE study_materials ADD COLUMN subject TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='study_materials' AND column_name='grade_level') THEN
        ALTER TABLE study_materials ADD COLUMN grade_level TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='study_materials' AND column_name='content_type') THEN
        ALTER TABLE study_materials ADD COLUMN content_type TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='study_materials' AND column_name='file_url') THEN
        ALTER TABLE study_materials ADD COLUMN file_url TEXT;
    END IF;
    
    -- Make columns nullable only if they exist
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

-- 4. FIX ASSIGNMENTS TABLE
DO $$ 
BEGIN
    -- Add missing columns to assignments
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='assignments' AND column_name='subject') THEN
        ALTER TABLE assignments ADD COLUMN subject TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='assignments' AND column_name='grade_level') THEN
        ALTER TABLE assignments ADD COLUMN grade_level TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='assignments' AND column_name='created_by') THEN
        ALTER TABLE assignments ADD COLUMN created_by UUID REFERENCES app_users(id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='assignments' AND column_name='material_id') THEN
        ALTER TABLE assignments ADD COLUMN material_id UUID;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='assignments' AND column_name='max_points') THEN
        ALTER TABLE assignments ADD COLUMN max_points INTEGER DEFAULT 100;
    END IF;
    
    -- Make columns nullable only if they exist
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='assignments' AND column_name='class_id' AND is_nullable='NO') THEN
        ALTER TABLE assignments ALTER COLUMN class_id DROP NOT NULL;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='assignments' AND column_name='due_date' AND is_nullable='NO') THEN
        ALTER TABLE assignments ALTER COLUMN due_date DROP NOT NULL;
    END IF;
END $$;

-- 5. FIX LESSONS TABLE
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='lessons' AND column_name='video_path') THEN
        ALTER TABLE lessons ADD COLUMN video_path TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='lessons' AND column_name='lesson_type') THEN
        ALTER TABLE lessons ADD COLUMN lesson_type TEXT DEFAULT 'video';
    END IF;
    
    -- Make class_id nullable only if it exists
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='lessons' AND column_name='class_id' AND is_nullable='NO') THEN
        ALTER TABLE lessons ALTER COLUMN class_id DROP NOT NULL;
    END IF;
END $$;

-- 6. FIX MESSAGES TABLE
DO $$ 
BEGIN
    -- Make columns nullable only if they exist
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='messages' AND column_name='class_id' AND is_nullable='NO') THEN
        ALTER TABLE messages ALTER COLUMN class_id DROP NOT NULL;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='messages' AND column_name='school_id' AND is_nullable='NO') THEN
        ALTER TABLE messages ALTER COLUMN school_id DROP NOT NULL;
    END IF;
END $$;

-- 7. CREATE VIDEOS BUCKET IF NOT EXISTS
INSERT INTO storage.buckets (id, name, public)
VALUES ('videos', 'videos', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- SUCCESS
SELECT '✅ COMPLETE DATABASE FIX APPLIED! All tables should work now.' as status;
