-- ============================================
-- ADD CASCADE DELETE RULES
-- This allows deleting schools to automatically delete related data
-- Run this in Supabase SQL Editor
-- ============================================

-- Drop existing foreign keys and recreate with CASCADE
-- This ensures when a school is deleted, all related data is also deleted

-- 1. Classes table - delete classes when school is deleted
ALTER TABLE classes 
DROP CONSTRAINT IF EXISTS classes_school_id_fkey;

ALTER TABLE classes
ADD CONSTRAINT classes_school_id_fkey 
FOREIGN KEY (school_id) 
REFERENCES schools(id) 
ON DELETE CASCADE;

-- 2. App users table - set school_id to NULL when school is deleted (don't delete users)
ALTER TABLE app_users 
DROP CONSTRAINT IF EXISTS app_users_school_id_fkey;

ALTER TABLE app_users
ADD CONSTRAINT app_users_school_id_fkey 
FOREIGN KEY (school_id) 
REFERENCES schools(id) 
ON DELETE SET NULL;

-- 3. Assignments table - delete assignments when school is deleted
ALTER TABLE assignments 
DROP CONSTRAINT IF EXISTS assignments_school_id_fkey;

ALTER TABLE assignments
ADD CONSTRAINT assignments_school_id_fkey 
FOREIGN KEY (school_id) 
REFERENCES schools(id) 
ON DELETE CASCADE;

-- 4. Lessons table - delete lessons when school is deleted
ALTER TABLE lessons 
DROP CONSTRAINT IF EXISTS lessons_school_id_fkey;

ALTER TABLE lessons
ADD CONSTRAINT lessons_school_id_fkey 
FOREIGN KEY (school_id) 
REFERENCES schools(id) 
ON DELETE CASCADE;

-- 5. Study materials table - delete materials when school is deleted
ALTER TABLE study_materials 
DROP CONSTRAINT IF EXISTS study_materials_school_id_fkey;

ALTER TABLE study_materials
ADD CONSTRAINT study_materials_school_id_fkey 
FOREIGN KEY (school_id) 
REFERENCES schools(id) 
ON DELETE CASCADE;

-- 6. Messages table - delete messages when school is deleted
ALTER TABLE messages 
DROP CONSTRAINT IF EXISTS messages_school_id_fkey;

ALTER TABLE messages
ADD CONSTRAINT messages_school_id_fkey 
FOREIGN KEY (school_id) 
REFERENCES schools(id) 
ON DELETE CASCADE;

-- Success message
SELECT 'SUCCESS! CASCADE rules added. Deleting schools will now work properly.' as status;
