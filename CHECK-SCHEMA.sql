-- Run this to see what columns actually exist in your tables

-- Check study_materials table
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'study_materials'
ORDER BY ordinal_position;

-- Check assignments table  
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'assignments'
ORDER BY ordinal_position;

-- Check messages table
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'messages'
ORDER BY ordinal_position;
