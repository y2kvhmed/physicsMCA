-- ============================================
-- ADD MISSING COLUMNS TO MESSAGES TABLE
-- Run this after the main fix
-- ============================================

DO $$ 
BEGIN
    -- Add is_pinned to messages if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='messages' AND column_name='is_pinned') THEN
        ALTER TABLE messages ADD COLUMN is_pinned BOOLEAN DEFAULT false;
        RAISE NOTICE 'Added is_pinned column to messages';
    END IF;
    
    -- Add priority to messages if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='messages' AND column_name='priority') THEN
        ALTER TABLE messages ADD COLUMN priority TEXT DEFAULT 'normal';
        RAISE NOTICE 'Added priority column to messages';
    END IF;
    
    -- Add metadata to messages if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='messages' AND column_name='metadata') THEN
        ALTER TABLE messages ADD COLUMN metadata JSONB;
        RAISE NOTICE 'Added metadata column to messages';
    END IF;
    
    -- Add file_type to messages if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='messages' AND column_name='file_type') THEN
        ALTER TABLE messages ADD COLUMN file_type TEXT;
        RAISE NOTICE 'Added file_type column to messages';
    END IF;
    
    -- Add file_path to messages if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='messages' AND column_name='file_path') THEN
        ALTER TABLE messages ADD COLUMN file_path TEXT;
        RAISE NOTICE 'Added file_path column to messages';
    END IF;
    
    -- Add file_name to messages if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='messages' AND column_name='file_name') THEN
        ALTER TABLE messages ADD COLUMN file_name TEXT;
        RAISE NOTICE 'Added file_name column to messages';
    END IF;
    
    -- Add file_size to messages if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='messages' AND column_name='file_size') THEN
        ALTER TABLE messages ADD COLUMN file_size BIGINT;
        RAISE NOTICE 'Added file_size column to messages';
    END IF;
    
    -- Add title to messages if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='messages' AND column_name='title') THEN
        ALTER TABLE messages ADD COLUMN title TEXT;
        RAISE NOTICE 'Added title column to messages';
    END IF;
    
    -- Add message_type to messages if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='messages' AND column_name='message_type') THEN
        ALTER TABLE messages ADD COLUMN message_type TEXT DEFAULT 'text';
        RAISE NOTICE 'Added message_type column to messages';
    END IF;
END $$;

-- Create chat-files bucket and allow all mime types
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('chat-files', 'chat-files', true, 52428800, ARRAY['image/*', 'video/*', 'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
ON CONFLICT (id) DO UPDATE SET 
  public = true,
  allowed_mime_types = ARRAY['image/*', 'video/*', 'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'];

-- Update existing buckets to allow all mime types
UPDATE storage.buckets 
SET allowed_mime_types = NULL  -- NULL means all mime types are allowed
WHERE id IN ('videos', 'recordings', 'lessons', 'submissions', 'materials', 'chat-files');

SELECT '✅ Messages table and storage buckets fixed!' as status;
