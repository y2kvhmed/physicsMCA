-- FIXED DATABASE SETUP - Corrected Order and Dependencies
-- Run this in Supabase SQL Editor

-- Step 1: Disable RLS temporarily
ALTER TABLE IF EXISTS schools DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS app_users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS assignments DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS study_materials DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS submissions DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS enrollments DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS classes DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing tables if they have constraint issues
DROP TABLE IF EXISTS submissions CASCADE;
DROP TABLE IF EXISTS enrollments CASCADE;
DROP TABLE IF EXISTS assignments CASCADE;
DROP TABLE IF EXISTS study_materials CASCADE;
DROP TABLE IF EXISTS classes CASCADE;
DROP TABLE IF EXISTS app_users CASCADE;
DROP TABLE IF EXISTS schools CASCADE;

-- Step 3: Create tables in correct order (no foreign keys first)
CREATE TABLE schools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    address TEXT,
    phone TEXT,
    email TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE app_users (
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

CREATE TABLE classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    school_id UUID REFERENCES schools(id),
    teacher_id UUID REFERENCES app_users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES app_users(id),
    class_id UUID REFERENCES classes(id),
    enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(student_id, class_id)
);

CREATE TABLE assignments (
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

CREATE TABLE study_materials (
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

CREATE TABLE submissions (
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

-- Step 4: Insert data in correct order
-- First: School
INSERT INTO schools (id, name, address, phone, email) VALUES 
('550e8400-e29b-41d4-a716-446655440000', 'Test High School', '123 Education Street', '+1-555-0123', 'admin@testschool.edu');

-- Second: Users (referencing school)
INSERT INTO app_users (id, name, email, password_hash, role, school_id, is_active) VALUES 
('550e8400-e29b-41d4-a716-446655440001', 'System Administrator', 'admin@testschool.edu', 'admin123', 'admin', '550e8400-e29b-41d4-a716-446655440000', true),
('550e8400-e29b-41d4-a716-446655440002', 'John Teacher', 'teacher@testschool.edu', 'teacher123', 'teacher', '550e8400-e29b-41d4-a716-446655440000', true),
('550e8400-e29b-41d4-a716-446655440003', 'Jane Student', 'student@testschool.edu', 'student123', 'student', '550e8400-e29b-41d4-a716-446655440000', true);

-- Third: Classes (referencing school and teacher)
INSERT INTO classes (id, name, description, school_id, teacher_id) VALUES 
('550e8400-e29b-41d4-a716-446655440004', 'Physics 101', 'Introduction to Physics', '550e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440002');

-- Fourth: Enrollments (referencing student and class)
INSERT INTO enrollments (student_id, class_id) VALUES 
('550e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440004');

-- Fifth: Sample Assignment
INSERT INTO assignments (id, title, description, school_id, teacher_id, class_id, due_date) VALUES 
('550e8400-e29b-41d4-a716-446655440005', 'Newton Laws Assignment', 'Complete exercises on Newton three laws of motion', '550e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440004', NOW() + INTERVAL '7 days');

-- Sixth: Sample Study Material
INSERT INTO study_materials (id, title, description, school_id, teacher_id, class_id) VALUES 
('550e8400-e29b-41d4-a716-446655440006', 'Physics Formulas Sheet', 'Essential physics formulas for the course', '550e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440004');

-- Step 5: Create storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES 
('study-materials', 'study-materials', true),
('submissions', 'submissions', false),
('videos', 'videos', true)
ON CONFLICT (id) DO NOTHING;

-- Step 6: Create permissive RLS policies
CREATE POLICY "Allow all access" ON schools FOR ALL USING (true);
CREATE POLICY "Allow all access" ON app_users FOR ALL USING (true);
CREATE POLICY "Allow all access" ON assignments FOR ALL USING (true);
CREATE POLICY "Allow all access" ON study_materials FOR ALL USING (true);
CREATE POLICY "Allow all access" ON submissions FOR ALL USING (true);
CREATE POLICY "Allow all access" ON enrollments FOR ALL USING (true);
CREATE POLICY "Allow all access" ON classes FOR ALL USING (true);

-- Step 7: Create storage policy
CREATE POLICY "Allow all storage access" ON storage.objects FOR ALL USING (true);

-- Step 8: Enable RLS
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;

-- Step 9: Verification
SELECT 'SETUP COMPLETE - VERIFICATION:' as status;

SELECT 
    'schools' as table_name, 
    count(*) as records,
    (SELECT name FROM schools LIMIT 1) as sample
FROM schools
UNION ALL
SELECT 
    'app_users' as table_name, 
    count(*) as records,
    (SELECT name FROM app_users LIMIT 1) as sample
FROM app_users
UNION ALL
SELECT 
    'classes' as table_name, 
    count(*) as records,
    (SELECT name FROM classes LIMIT 1) as sample
FROM classes
UNION ALL
SELECT 
    'enrollments' as table_name, 
    count(*) as records,
    'N/A' as sample
FROM enrollments
UNION ALL
SELECT 
    'assignments' as table_name, 
    count(*) as records,
    (SELECT title FROM assignments LIMIT 1) as sample
FROM assignments
UNION ALL
SELECT 
    'study_materials' as table_name, 
    count(*) as records,
    (SELECT title FROM study_materials LIMIT 1) as sample
FROM study_materials;

-- Show login accounts
SELECT 'LOGIN ACCOUNTS:' as info, '' as email, '' as password, '' as role
UNION ALL
SELECT 'Account', email, password_hash, role FROM app_users ORDER BY role;

SELECT 'SUCCESS: Database setup complete!' as final_status;