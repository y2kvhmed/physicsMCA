-- EMERGENCY LOGIN FIX
-- This will create test users and fix authentication

-- First, ensure the app_users table exists with correct structure
CREATE TABLE IF NOT EXISTS app_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT,
    name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'teacher', 'student')),
    school_id UUID REFERENCES schools(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create a test school first
INSERT INTO schools (id, name, address, phone, email, is_active) 
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Test School',
    '123 Test Street',
    '555-0123',
    'test@school.com',
    true
) ON CONFLICT (id) DO NOTHING;

-- Create test users with simple passwords
INSERT INTO app_users (id, email, password_hash, name, role, school_id, is_active) VALUES
-- Admin user
('admin-test-id', 'admin@test.com', 'admin123', 'Test Administrator', 'admin', NULL, true),
-- Teacher user  
('teacher-test-id', 'teacher@test.com', 'teacher123', 'Test Teacher', 'teacher', '00000000-0000-0000-0000-000000000001', true),
-- Student user
('student-test-id', 'student@test.com', 'student123', 'Test Student', 'student', '00000000-0000-0000-0000-000000000001', true)
ON CONFLICT (id) DO UPDATE SET
    password_hash = EXCLUDED.password_hash,
    is_active = EXCLUDED.is_active;

-- Also create simple login credentials
INSERT INTO app_users (email, password_hash, name, role, school_id, is_active) VALUES
('admin', 'admin', 'Admin User', 'admin', NULL, true),
('teacher', 'teacher', 'Teacher User', 'teacher', '00000000-0000-0000-0000-000000000001', true),
('student', 'student', 'Student User', 'student', '00000000-0000-0000-0000-000000000001', true)
ON CONFLICT (email) DO UPDATE SET
    password_hash = EXCLUDED.password_hash,
    is_active = EXCLUDED.is_active;

-- Disable RLS temporarily for testing
ALTER TABLE app_users DISABLE ROW LEVEL SECURITY;
ALTER TABLE schools DISABLE ROW LEVEL SECURITY;

-- Grant public access for testing
GRANT ALL ON app_users TO anon;
GRANT ALL ON schools TO anon;
GRANT ALL ON assignments TO anon;
GRANT ALL ON study_materials TO anon;
GRANT ALL ON submissions TO anon;

-- Create simple view for login testing
CREATE OR REPLACE VIEW login_test AS
SELECT email, password_hash, name, role, school_id, is_active
FROM app_users 
WHERE is_active = true;

GRANT SELECT ON login_test TO anon;