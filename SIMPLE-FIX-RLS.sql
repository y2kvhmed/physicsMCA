-- ============================================
-- SIMPLE FIX - Only fix public schema tables
-- Run this in Supabase SQL Editor
-- ============================================

-- STEP 1: Disable RLS on your app tables (not storage)
ALTER TABLE IF EXISTS app_users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS schools DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS classes DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS assignments DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS submissions DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS lessons DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS study_materials DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS enrollments DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS calendar_events DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS assignment_comments DISABLE ROW LEVEL SECURITY;

-- STEP 2: Drop policies on app_users (the main problem)
DROP POLICY IF EXISTS "Users can view their own data" ON app_users;
DROP POLICY IF EXISTS "Users can update their own data" ON app_users;
DROP POLICY IF EXISTS "Admins can view all users" ON app_users;
DROP POLICY IF EXISTS "Admins can manage users" ON app_users;
DROP POLICY IF EXISTS "Teachers can view users in their school" ON app_users;
DROP POLICY IF EXISTS "Users can view own profile" ON app_users;
DROP POLICY IF EXISTS "Users can update own profile" ON app_users;
DROP POLICY IF EXISTS "Service role full access" ON app_users;
DROP POLICY IF EXISTS "Allow user creation" ON app_users;
DROP POLICY IF EXISTS "view_own_profile" ON app_users;
DROP POLICY IF EXISTS "update_own_profile" ON app_users;
DROP POLICY IF EXISTS "insert_users" ON app_users;

-- Success message
SELECT 'SUCCESS! RLS disabled on all app tables. Your app should work now.' as status;
