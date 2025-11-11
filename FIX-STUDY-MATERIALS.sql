-- ============================================
-- FIX STUDY_MATERIALS TABLE
-- This adds missing columns safely
-- ============================================

-- First, let's see what we have
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'study_materials'
ORDER BY ordinal_position;

-- Add missing columns if they don't exist
DO $$ 
BEGIN
    -- Add uploaded_by if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='study_materials' AND column_name='uploaded_by') THEN
        ALTER TABLE study_materials ADD COLUMN uploaded_by UUID REFERENCES app_users(id);
        RAISE NOTICE 'Added uploaded_by column';
    END IF;
    
    -- Add created_by if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='study_materials' AND column_name='created_by') THEN
        ALTER TABLE study_materials ADD COLUMN created_by UUID REFERENCES app_users(id);
        RAISE NOTICE 'Added created_by column';
    END IF;
    
    -- Add subject if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='study_materials' AND column_name='subject') THEN
        ALTER TABLE study_materials ADD COLUMN subject TEXT;
        RAISE NOTICE 'Added subject column';
    END IF;
    
    -- Add grade_level if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='study_materials' AND column_name='grade_level') THEN
        ALTER TABLE study_materials ADD COLUMN grade_level TEXT;
        RAISE NOTICE 'Added grade_level column';
    END IF;
    
    -- Add content_type if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='study_materials' AND column_name='content_type') THEN
        ALTER TABLE study_materials ADD COLUMN content_type TEXT;
        RAISE NOTICE 'Added content_type column';
    END IF;
    
    -- Add file_url if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='study_materials' AND column_name='file_url') THEN
        ALTER TABLE study_materials ADD COLUMN file_url TEXT;
        RAISE NOTICE 'Added file_url column';
    END IF;
    
    -- Make class_id and school_id nullable if they exist
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='study_materials' AND column_name='class_id' AND is_nullable='NO') THEN
        ALTER TABLE study_materials ALTER COLUMN class_id DROP NOT NULL;
        RAISE NOTICE 'Made class_id nullable';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name='study_materials' AND column_name='school_id' AND is_nullable='NO') THEN
        ALTER TABLE study_materials ALTER COLUMN school_id DROP NOT NULL;
        RAISE NOTICE 'Made school_id nullable';
    END IF;
END $$;

-- Disable RLS on study_materials
ALTER TABLE study_materials DISABLE ROW LEVEL SECURITY;

-- Show final structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'study_materials'
ORDER BY ordinal_position;

SELECT '✅ Study materials table fixed!' as status;
