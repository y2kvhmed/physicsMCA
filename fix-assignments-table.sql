-- ============================================
-- CHECK AND FIX ASSIGNMENTS TABLE
-- Run this in Supabase SQL Editor
-- ============================================

-- Check current assignments table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'assignments'
ORDER BY ordinal_position;

-- Make columns nullable that should be optional
ALTER TABLE assignments 
ALTER COLUMN class_id DROP NOT NULL;

ALTER TABLE assignments 
ALTER COLUMN due_date DROP NOT NULL;

ALTER TABLE assignments 
ALTER COLUMN instructions DROP NOT NULL;

ALTER TABLE assignments 
ALTER COLUMN max_score DROP NOT NULL;

-- Add missing columns if they don't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='assignments' AND column_name='assignment_type') THEN
        ALTER TABLE assignments ADD COLUMN assignment_type TEXT DEFAULT 'assignment';
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='assignments' AND column_name='file_path') THEN
        ALTER TABLE assignments ADD COLUMN file_path TEXT;
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='assignments' AND column_name='file_name') THEN
        ALTER TABLE assignments ADD COLUMN file_name TEXT;
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='assignments' AND column_name='file_size') THEN
        ALTER TABLE assignments ADD COLUMN file_size BIGINT;
    END IF;
END $$;

-- Success message
SELECT 'SUCCESS! Assignments table schema fixed.' as status;
