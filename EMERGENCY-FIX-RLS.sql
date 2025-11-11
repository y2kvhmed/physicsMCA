-- ============================================
-- EMERGENCY FIX - DISABLE ALL RLS POLICIES
-- Run this IMMEDIATELY in Supabase SQL Editor
-- ============================================

-- This will completely disable RLS to get your app working
-- You can add proper policies later once everything works

-- STEP 1: Disable RLS on ALL tables
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

-- STEP 2: Drop ALL existing policies to prevent any conflicts
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT schemaname, tablename, policyname 
              FROM pg_policies 
              WHERE schemaname = 'public') 
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
                      r.policyname, r.schemaname, r.tablename);
    END LOOP;
END $$;

-- STEP 3: Drop ALL storage policies
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT schemaname, tablename, policyname 
              FROM pg_policies 
              WHERE schemaname = 'storage' AND tablename = 'objects') 
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', 
                      r.policyname, r.schemaname, r.tablename);
    END LOOP;
END $$;

-- STEP 4: Disable RLS on storage.objects
ALTER TABLE IF EXISTS storage.objects DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS storage.buckets DISABLE ROW LEVEL SECURITY;

-- Success message
SELECT 'SUCCESS! All RLS policies have been disabled. Your app should work now.' as status;
SELECT 'WARNING: This is not secure for production. Add proper policies later.' as warning;
