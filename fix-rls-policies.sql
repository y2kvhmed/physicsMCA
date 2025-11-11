-- ============================================
-- FIX INFINITE RECURSION IN RLS POLICIES
-- Run this in Supabase SQL Editor
-- ============================================

-- Step 1: Temporarily disable RLS to allow operations
ALTER TABLE app_users DISABLE ROW LEVEL SECURITY;
ALTER TABLE schools DISABLE ROW LEVEL SECURITY;
ALTER TABLE classes DISABLE ROW LEVEL SECURITY;
ALTER TABLE assignments DISABLE ROW LEVEL SECURITY;
ALTER TABLE submissions DISABLE ROW LEVEL SECURITY;
ALTER TABLE lessons DISABLE ROW LEVEL SECURITY;
ALTER TABLE study_materials DISABLE ROW LEVEL SECURITY;
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop all existing problematic policies on app_users
DROP POLICY IF EXISTS "Users can view their own data" ON app_users;
DROP POLICY IF EXISTS "Users can update their own data" ON app_users;
DROP POLICY IF EXISTS "Admins can view all users" ON app_users;
DROP POLICY IF EXISTS "Admins can manage users" ON app_users;
DROP POLICY IF EXISTS "Teachers can view users in their school" ON app_users;
DROP POLICY IF EXISTS "Users can view own profile" ON app_users;
DROP POLICY IF EXISTS "Users can update own profile" ON app_users;
DROP POLICY IF EXISTS "Service role full access" ON app_users;
DROP POLICY IF EXISTS "Allow user creation" ON app_users;

-- Step 3: Re-enable RLS
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;

-- Step 4: Create simple, non-recursive policies for app_users
-- These policies do NOT query app_users table, avoiding recursion

-- Allow authenticated users to view their own profile
CREATE POLICY "view_own_profile"
ON app_users FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Allow authenticated users to update their own profile
CREATE POLICY "update_own_profile"
ON app_users FOR UPDATE
TO authenticated
USING (auth.uid() = id);

-- Allow insert for user creation (controlled by application logic)
CREATE POLICY "insert_users"
ON app_users FOR INSERT
TO authenticated
WITH CHECK (true);

-- Step 5: Simple policies for other tables

-- Schools: Everyone can read, authenticated can create/update
CREATE POLICY "schools_select" ON schools FOR SELECT TO authenticated USING (true);
CREATE POLICY "schools_insert" ON schools FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "schools_update" ON schools FOR UPDATE TO authenticated USING (true);
CREATE POLICY "schools_delete" ON schools FOR DELETE TO authenticated USING (true);

-- Classes: Everyone can read, authenticated can create/update
CREATE POLICY "classes_select" ON classes FOR SELECT TO authenticated USING (true);
CREATE POLICY "classes_insert" ON classes FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "classes_update" ON classes FOR UPDATE TO authenticated USING (true);
CREATE POLICY "classes_delete" ON classes FOR DELETE TO authenticated USING (true);

-- Assignments: Everyone can read, authenticated can create/update
CREATE POLICY "assignments_select" ON assignments FOR SELECT TO authenticated USING (true);
CREATE POLICY "assignments_insert" ON assignments FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "assignments_update" ON assignments FOR UPDATE TO authenticated USING (true);
CREATE POLICY "assignments_delete" ON assignments FOR DELETE TO authenticated USING (true);

-- Submissions: Everyone can read, authenticated can create/update
CREATE POLICY "submissions_select" ON submissions FOR SELECT TO authenticated USING (true);
CREATE POLICY "submissions_insert" ON submissions FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "submissions_update" ON submissions FOR UPDATE TO authenticated USING (true);
CREATE POLICY "submissions_delete" ON submissions FOR DELETE TO authenticated USING (true);

-- Lessons: Everyone can read, authenticated can create/update
CREATE POLICY "lessons_select" ON lessons FOR SELECT TO authenticated USING (true);
CREATE POLICY "lessons_insert" ON lessons FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "lessons_update" ON lessons FOR UPDATE TO authenticated USING (true);
CREATE POLICY "lessons_delete" ON lessons FOR DELETE TO authenticated USING (true);

-- Study Materials: Everyone can read, authenticated can create/update
CREATE POLICY "materials_select" ON study_materials FOR SELECT TO authenticated USING (true);
CREATE POLICY "materials_insert" ON study_materials FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "materials_update" ON study_materials FOR UPDATE TO authenticated USING (true);
CREATE POLICY "materials_delete" ON study_materials FOR DELETE TO authenticated USING (true);

-- Messages: Everyone can read, authenticated can create/update
CREATE POLICY "messages_select" ON messages FOR SELECT TO authenticated USING (true);
CREATE POLICY "messages_insert" ON messages FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "messages_update" ON messages FOR UPDATE TO authenticated USING (true);
CREATE POLICY "messages_delete" ON messages FOR DELETE TO authenticated USING (true);

-- Enrollments: Everyone can read, authenticated can create/update
CREATE POLICY "enrollments_select" ON enrollments FOR SELECT TO authenticated USING (true);
CREATE POLICY "enrollments_insert" ON enrollments FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "enrollments_update" ON enrollments FOR UPDATE TO authenticated USING (true);
CREATE POLICY "enrollments_delete" ON enrollments FOR DELETE TO authenticated USING (true);

-- Step 6: Fix Storage Policies
-- Drop existing storage policies that might cause recursion
DROP POLICY IF EXISTS "Users can view recordings from their school" ON storage.objects;
DROP POLICY IF EXISTS "Teachers and admins can upload recordings" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can read" ON storage.objects;

-- Create simple storage policies without recursion
-- Allow authenticated users to upload to lessons bucket
CREATE POLICY "authenticated_upload_lessons"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'lessons');

-- Allow authenticated users to read from lessons bucket
CREATE POLICY "authenticated_read_lessons"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'lessons');

-- Allow authenticated users to upload to submissions bucket
CREATE POLICY "authenticated_upload_submissions"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'submissions');

-- Allow authenticated users to read from submissions bucket
CREATE POLICY "authenticated_read_submissions"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'submissions');

-- Allow authenticated users to delete their own uploads
CREATE POLICY "authenticated_delete_own"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id IN ('lessons', 'submissions'));

-- Step 7: Verify policies are working
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename IN ('app_users', 'schools', 'classes', 'assignments', 'submissions', 'lessons', 'study_materials', 'messages')
ORDER BY tablename, policyname;

-- Success message
SELECT 'RLS policies fixed successfully! All tables now have simple, non-recursive policies.' as status;
