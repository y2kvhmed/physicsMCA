-- EMERGENCY DATABASE FIX
-- Run this in Supabase SQL Editor to fix all database issues

-- Step 1: Disable RLS temporarily to check what's happening
ALTER TABLE IF EXISTS schools DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS app_users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS assignments DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS study_materials DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS submissions DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS enrollments DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS classes DISABLE ROW LEVEL SECURITY;

-- Step 2: Check if tables exist and have data
SELECT 
    schemaname,
    tablename,
    hasindexes,
    hasrules,
    hastriggers
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('schools', 'app_users', 'assignments', 'study_materials', 'submissions', 'enrollments', 'classes');

-- Step 3: Count records in each table
DO $$
DECLARE
    table_name text;
    record_count integer;
BEGIN
    FOR table_name IN 
        SELECT t.table_name 
        FROM information_schema.tables t 
        WHERE t.table_schema = 'public' 
        AND t.table_name IN ('schools', 'app_users', 'assignments', 'study_materials', 'submissions', 'enrollments', 'classes')
    LOOP
        EXECUTE format('SELECT count(*) FROM %I', table_name) INTO record_count;
        RAISE NOTICE 'Table %: % records', table_name, record_count;
    END LOOP;
END $$;

-- Step 4: Create tables if they don't exist
CREATE TABLE IF NOT EXISTS schools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    email TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT,
    role TEXT NOT NULL CHECK (role IN ('admin', 'teacher', 'student')),
    school_id UUID REFERENCES schools(id),
    phone TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    school_id UUID REFERENCES schools(id),
    teacher_id UUID REFERENCES app_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES app_users(id),
    class_id UUID REFERENCES classes(id),
    enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(student_id, class_id)
);

CREATE TABLE IF NOT EXISTS assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    instructions TEXT,
    due_date TIMESTAMP WITH TIME ZONE,
    max_score INTEGER DEFAULT 100,
    assignment_type TEXT DEFAULT 'assignment',
    school_id UUID REFERENCES schools(id),
    teacher_id UUID REFERENCES app_users(id),
    class_id UUID REFERENCES classes(id),
    file_path TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS study_materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    file_path TEXT,
    file_type TEXT,
    file_size INTEGER,
    school_id UUID REFERENCES schools(id),
    teacher_id UUID REFERENCES app_users(id),
    class_id UUID REFERENCES classes(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id UUID REFERENCES assignments(id),
    student_id UUID REFERENCES app_users(id),
    file_path TEXT,
    file_name TEXT,
    file_size INTEGER,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    grade INTEGER,
    percentage DECIMAL(5,2),
    feedback TEXT,
    status TEXT DEFAULT 'submitted',
    graded_at TIMESTAMP WITH TIME ZONE,
    graded_by UUID REFERENCES app_users(id),
    UNIQUE(assignment_id, student_id)
);

-- Step 5: Insert sample data if tables are empty
INSERT INTO schools (id, name, address, phone, email) 
SELECT 
    '550e8400-e29b-41d4-a716-446655440000'::uuid,
    'Test High School',
    '123 Education Street, Learning City, LC 12345',
    '+1-555-0123',
    'admin@testschool.edu'
WHERE NOT EXISTS (SELECT 1 FROM schools LIMIT 1);

INSERT INTO app_users (id, name, email, password_hash, role, school_id, is_active)
SELECT 
    '550e8400-e29b-41d4-a716-446655440001'::uuid,
    'System Administrator',
    'admin@testschool.edu',
    'admin123',
    'admin',
    '550e8400-e29b-41d4-a716-446655440000'::uuid,
    true
WHERE NOT EXISTS (SELECT 1 FROM app_users WHERE role = 'admin' LIMIT 1);

INSERT INTO app_users (id, name, email, password_hash, role, school_id, is_active)
SELECT 
    '550e8400-e29b-41d4-a716-446655440002'::uuid,
    'John Teacher',
    'teacher@testschool.edu',
    'teacher123',
    'teacher',
    '550e8400-e29b-41d4-a716-446655440000'::uuid,
    true
WHERE NOT EXISTS (SELECT 1 FROM app_users WHERE role = 'teacher' LIMIT 1);

INSERT INTO app_users (id, name, email, password_hash, role, school_id, is_active)
SELECT 
    '550e8400-e29b-41d4-a716-446655440003'::uuid,
    'Jane Student',
    'student@testschool.edu',
    'student123',
    'student',
    '550e8400-e29b-41d4-a716-446655440000'::uuid,
    true
WHERE NOT EXISTS (SELECT 1 FROM app_users WHERE role = 'student' LIMIT 1);

INSERT INTO classes (id, name, description, school_id, teacher_id)
SELECT 
    '550e8400-e29b-41d4-a716-446655440004'::uuid,
    'Physics 101',
    'Introduction to Physics',
    '550e8400-e29b-41d4-a716-446655440000'::uuid,
    '550e8400-e29b-41d4-a716-446655440002'::uuid
WHERE NOT EXISTS (SELECT 1 FROM classes LIMIT 1);

INSERT INTO enrollments (student_id, class_id)
SELECT 
    '550e8400-e29b-41d4-a716-446655440003'::uuid,
    '550e8400-e29b-41d4-a716-446655440004'::uuid
WHERE NOT EXISTS (SELECT 1 FROM enrollments LIMIT 1);

-- Step 6: Create permissive RLS policies for testing
DROP POLICY IF EXISTS "Allow all access for testing" ON schools;
DROP POLICY IF EXISTS "Allow all access for testing" ON app_users;
DROP POLICY IF EXISTS "Allow all access for testing" ON assignments;
DROP POLICY IF EXISTS "Allow all access for testing" ON study_materials;
DROP POLICY IF EXISTS "Allow all access for testing" ON submissions;
DROP POLICY IF EXISTS "Allow all access for testing" ON enrollments;
DROP POLICY IF EXISTS "Allow all access for testing" ON classes;

CREATE POLICY "Allow all access for testing" ON schools FOR ALL USING (true);
CREATE POLICY "Allow all access for testing" ON app_users FOR ALL USING (true);
CREATE POLICY "Allow all access for testing" ON assignments FOR ALL USING (true);
CREATE POLICY "Allow all access for testing" ON study_materials FOR ALL USING (true);
CREATE POLICY "Allow all access for testing" ON submissions FOR ALL USING (true);
CREATE POLICY "Allow all access for testing" ON enrollments FOR ALL USING (true);
CREATE POLICY "Allow all access for testing" ON classes FOR ALL USING (true);

-- Step 7: Re-enable RLS
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;

-- Step 8: Create storage buckets if they don't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('study-materials', 'study-materials', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('submissions', 'submissions', false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('videos', 'videos', true)
ON CONFLICT (id) DO NOTHING;

-- Step 9: Create storage policies
DROP POLICY IF EXISTS "Allow all access for testing" ON storage.objects;
CREATE POLICY "Allow all access for testing" ON storage.objects FOR ALL USING (true);

-- Step 10: Final verification
SELECT 'VERIFICATION RESULTS:' as status;

SELECT 
    'schools' as table_name, 
    count(*) as record_count,
    (SELECT name FROM schools LIMIT 1) as sample_name
FROM schools
UNION ALL
SELECT 
    'app_users' as table_name, 
    count(*) as record_count,
    (SELECT name FROM app_users LIMIT 1) as sample_name
FROM app_users
UNION ALL
SELECT 
    'classes' as table_name, 
    count(*) as record_count,
    (SELECT name FROM classes LIMIT 1) as sample_name
FROM classes
UNION ALL
SELECT 
    'enrollments' as table_name, 
    count(*) as record_count,
    'N/A' as sample_name
FROM enrollments;

-- Show sample users for login testing
SELECT 
    'LOGIN TEST ACCOUNTS:' as info,
    '' as email,
    '' as password,
    '' as role;

SELECT 
    'Account' as info,
    email,
    password_hash as password,
    role
FROM app_users 
WHERE is_active = true
ORDER BY role;

SELECT 'DATABASE FIX COMPLETE!' as status;