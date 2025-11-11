-- EMERGENCY SUPABASE FIXES
-- Run these in your Supabase SQL Editor

-- 1. Fix RLS policies to allow proper access
-- Disable RLS temporarily for testing
ALTER TABLE schools DISABLE ROW LEVEL SECURITY;
ALTER TABLE app_users DISABLE ROW LEVEL SECURITY;
ALTER TABLE assignments DISABLE ROW LEVEL SECURITY;
ALTER TABLE study_materials DISABLE ROW LEVEL SECURITY;
ALTER TABLE submissions DISABLE ROW LEVEL SECURITY;
ALTER TABLE classes DISABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments DISABLE ROW LEVEL SECURITY;

-- 2. Create storage buckets if they don't exist
INSERT INTO storage.buckets (id, name, public) 
VALUES 
  ('study-materials', 'study-materials', true),
  ('submissions', 'submissions', false),
  ('videos', 'videos', true)
ON CONFLICT (id) DO NOTHING;

-- 3. Set up storage policies for public access
CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id = 'study-materials');
CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id = 'videos');
CREATE POLICY "Authenticated Access" ON storage.objects FOR ALL USING (bucket_id = 'submissions');

-- 4. Enable storage bucket policies
UPDATE storage.buckets SET public = true WHERE id IN ('study-materials', 'videos');
UPDATE storage.buckets SET public = false WHERE id = 'submissions';

-- 5. Create test admin user if not exists
INSERT INTO app_users (
  id, 
  email, 
  name, 
  role, 
  is_active, 
  password_hash,
  created_at
) VALUES (
  'test-admin-123',
  'admin@test.com',
  'Test Administrator',
  'admin',
  true,
  'Adm1n1strat0r',
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  is_active = true,
  password_hash = 'Adm1n1strat0r';

-- 6. Create test school if not exists
INSERT INTO schools (
  id,
  name,
  address,
  phone,
  email,
  is_active,
  created_at
) VALUES (
  'test-school-123',
  'Test School',
  '123 Test Street',
  '+1234567890',
  'school@test.com',
  true,
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  is_active = true;

-- 7. Create test teacher
INSERT INTO app_users (
  id,
  email,
  name,
  role,
  school_id,
  is_active,
  password_hash,
  created_at
) VALUES (
  'test-teacher-123',
  'teacher@test.com',
  'Test Teacher',
  'teacher',
  'test-school-123',
  true,
  'teacher123',
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  is_active = true,
  password_hash = 'teacher123';

-- 8. Create test student
INSERT INTO app_users (
  id,
  email,
  name,
  role,
  school_id,
  is_active,
  password_hash,
  created_at
) VALUES (
  'test-student-123',
  'student@test.com',
  'Test Student',
  'student',
  'test-school-123',
  true,
  'student123',
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  is_active = true,
  password_hash = 'student123';

-- 9. Create test class
INSERT INTO classes (
  id,
  name,
  description,
  school_id,
  teacher_id,
  is_active,
  created_at
) VALUES (
  'test-class-123',
  'Test Class',
  'A test class for demonstration',
  'test-school-123',
  'test-teacher-123',
  true,
  NOW()
) ON CONFLICT (id) DO UPDATE SET
  is_active = true;

-- 10. Enroll test student in test class
INSERT INTO enrollments (
  id,
  student_id,
  class_id,
  enrolled_at
) VALUES (
  'test-enrollment-123',
  'test-student-123',
  'test-class-123',
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- 11. Create test assignment
INSERT INTO assignments (
  id,
  title,
  description,
  instructions,
  due_date,
  max_score,
  assignment_type,
  school_id,
  teacher_id,
  class_id,
  created_at
) VALUES (
  'test-assignment-123',
  'Test Assignment',
  'This is a test assignment',
  'Complete this test assignment',
  NOW() + INTERVAL '7 days',
  100,
  'assignment',
  'test-school-123',
  'test-teacher-123',
  'test-class-123',
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- 12. Create test study material
INSERT INTO study_materials (
  id,
  title,
  description,
  file_path,
  file_size,
  file_type,
  school_id,
  teacher_id,
  class_id,
  created_at
) VALUES (
  'test-material-123',
  'Test Study Material',
  'This is a test study material',
  'test-material.pdf',
  1024,
  'application/pdf',
  'test-school-123',
  'test-teacher-123',
  'test-class-123',
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- 13. Grant necessary permissions
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- 14. Enable realtime for key tables
ALTER PUBLICATION supabase_realtime ADD TABLE app_users;
ALTER PUBLICATION supabase_realtime ADD TABLE assignments;
ALTER PUBLICATION supabase_realtime ADD TABLE submissions;
ALTER PUBLICATION supabase_realtime ADD TABLE study_materials;

COMMIT;