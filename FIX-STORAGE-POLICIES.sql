-- ============================================
-- FIX STORAGE POLICIES - Make buckets public
-- Run this in Supabase SQL Editor
-- ============================================

-- Make lessons bucket public
UPDATE storage.buckets 
SET public = true 
WHERE id = 'lessons';

-- Make submissions bucket public (if it exists)
UPDATE storage.buckets 
SET public = true 
WHERE id = 'submissions';

-- Success message
SELECT 'SUCCESS! Storage buckets are now public. Your uploads should work.' as status;
