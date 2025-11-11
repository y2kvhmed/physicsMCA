-- ============================================
-- FIX LESSONS TABLE SCHEMA
-- Run this in Supabase SQL Editor
-- ============================================

-- Check current lessons table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'lessons'
ORDER BY ordinal_position;

-- Make sure all required columns exist and are nullable
ALTER TABLE lessons 
ALTER COLUMN class_id DROP NOT NULL;

ALTER TABLE lessons 
ALTER COLUMN scheduled_at DROP NOT NULL;

ALTER TABLE lessons 
ALTER COLUMN duration_minutes DROP NOT NULL;

-- Add video_path column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='lessons' AND column_name='video_path') THEN
        ALTER TABLE lessons ADD COLUMN video_path TEXT;
    END IF;
END $$;

-- Add lesson_type column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='lessons' AND column_name='lesson_type') THEN
        ALTER TABLE lessons ADD COLUMN lesson_type TEXT DEFAULT 'video';
    END IF;
END $$;

-- Success message
SELECT 'SUCCESS! Lessons table schema fixed.' as status;
