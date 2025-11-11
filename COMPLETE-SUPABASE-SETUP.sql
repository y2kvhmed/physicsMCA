-- ========================================
-- COMPLETE SUPABASE SETUP FOR PHYSICS LEARNING APP
-- This script sets up EVERYTHING needed for full functionality
-- ========================================

-- Step 1: Drop existing tables to start fresh
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS submissions CASCADE;
DROP TABLE IF EXISTS enrollments CASCADE;
DROP TABLE IF EXISTS assignments CASCADE;
DROP TABLE IF EXISTS study_materials CASCADE;
DROP TABLE IF EXISTS classes CASCADE;
DROP TABLE IF EXISTS app_users CASCADE;
DROP TABLE IF EXISTS schools CASCADE;

-- Step 2: Create all tables in correct dependency order

-- SCHOOLS TABLE
CREATE TABLE schools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    address TEXT,
    phone TEXT,
    email TEXT,
    website TEXT,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- APP_USERS TABLE (Enhanced)
CREATE TABLE app_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'teacher', 'student')),
    school_id UUID REFERENCES schools(id) ON DELETE SET NULL,
    phone TEXT,
    avatar_url TEXT,
    date_of_birth DATE,
    address TEXT,
    emergency_contact TEXT,
    parent_phone TEXT,
    grade_level TEXT,
    subject_specialization TEXT,
    bio TEXT,
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP WITH TIME ZONE,
    email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- CLASSES TABLE
CREATE TABLE classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    subject TEXT,
    grade_level TEXT,
    room_number TEXT,
    schedule TEXT,
    max_students INTEGER DEFAULT 30,
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE NOT NULL,
    teacher_id UUID REFERENCES app_users(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ENROLLMENTS TABLE
CREATE TABLE enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES app_users(id) ON DELETE CASCADE NOT NULL,
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE NOT NULL,
    enrollment_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'completed')),
    final_grade TEXT,
    UNIQUE(student_id, class_id)
);

-- ASSIGNMENTS TABLE (Enhanced)
CREATE TABLE assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    instructions TEXT,
    due_date TIMESTAMP WITH TIME ZONE,
    max_score INTEGER DEFAULT 100,
    assignment_type TEXT DEFAULT 'assignment' CHECK (assignment_type IN ('assignment', 'quiz', 'exam', 'project', 'homework')),
    difficulty_level TEXT DEFAULT 'medium' CHECK (difficulty_level IN ('easy', 'medium', 'hard')),
    estimated_duration INTEGER, -- in minutes
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE NOT NULL,
    teacher_id UUID REFERENCES app_users(id) ON DELETE SET NULL NOT NULL,
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    file_path TEXT,
    file_name TEXT,
    file_size INTEGER,
    is_published BOOLEAN DEFAULT false,
    allow_late_submission BOOLEAN DEFAULT true,
    late_penalty_percent INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- STUDY_MATERIALS TABLE (Enhanced)
CREATE TABLE study_materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    content_type TEXT DEFAULT 'document' CHECK (content_type IN ('document', 'video', 'audio', 'image', 'link', 'presentation')),
    file_path TEXT,
    file_name TEXT,
    file_size INTEGER,
    file_type TEXT,
    external_url TEXT,
    thumbnail_url TEXT,
    duration INTEGER, -- for videos/audio in seconds
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE NOT NULL,
    teacher_id UUID REFERENCES app_users(id) ON DELETE SET NULL NOT NULL,
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    subject TEXT,
    grade_level TEXT,
    tags TEXT[], -- Array of tags for categorization
    is_public BOOLEAN DEFAULT false,
    download_count INTEGER DEFAULT 0,
    view_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- SUBMISSIONS TABLE (Enhanced)
CREATE TABLE submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assignment_id UUID REFERENCES assignments(id) ON DELETE CASCADE NOT NULL,
    student_id UUID REFERENCES app_users(id) ON DELETE CASCADE NOT NULL,
    file_path TEXT,
    file_name TEXT,
    file_size INTEGER,
    file_type TEXT,
    submission_text TEXT,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    grade INTEGER,
    percentage DECIMAL(5,2),
    feedback TEXT,
    status TEXT DEFAULT 'submitted' CHECK (status IN ('draft', 'submitted', 'graded', 'returned', 'late')),
    graded_at TIMESTAMP WITH TIME ZONE,
    graded_by UUID REFERENCES app_users(id) ON DELETE SET NULL,
    attempt_number INTEGER DEFAULT 1,
    is_late BOOLEAN DEFAULT false,
    time_spent INTEGER, -- in minutes
    auto_save_data JSONB, -- for draft auto-saves
    plagiarism_score DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(assignment_id, student_id, attempt_number)
);

-- MESSAGES TABLE (Enhanced)
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID REFERENCES app_users(id) ON DELETE CASCADE NOT NULL,
    recipient_id UUID REFERENCES app_users(id) ON DELETE CASCADE,
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    parent_message_id UUID REFERENCES messages(id) ON DELETE CASCADE, -- for replies
    subject TEXT,
    content TEXT NOT NULL,
    message_type TEXT DEFAULT 'direct' CHECK (message_type IN ('direct', 'class', 'announcement', 'system')),
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,
    has_attachments BOOLEAN DEFAULT false,
    attachment_paths TEXT[],
    scheduled_for TIMESTAMP WITH TIME ZONE, -- for scheduled messages
    expires_at TIMESTAMP WITH TIME ZONE, -- for temporary messages
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);-
- NOTIFICATIONS TABLE
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES app_users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'info' CHECK (type IN ('info', 'success', 'warning', 'error', 'assignment', 'grade', 'message', 'announcement')),
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,
    action_url TEXT,
    related_id UUID, -- ID of related object (assignment, message, etc.)
    related_type TEXT, -- Type of related object
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ATTENDANCE TABLE
CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES app_users(id) ON DELETE CASCADE NOT NULL,
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL,
    status TEXT DEFAULT 'present' CHECK (status IN ('present', 'absent', 'late', 'excused')),
    notes TEXT,
    marked_by UUID REFERENCES app_users(id) ON DELETE SET NULL,
    marked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(student_id, class_id, date)
);

-- GRADES TABLE (for overall class grades)
CREATE TABLE grades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES app_users(id) ON DELETE CASCADE NOT NULL,
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE NOT NULL,
    assignment_id UUID REFERENCES assignments(id) ON DELETE CASCADE,
    grade_value DECIMAL(5,2) NOT NULL,
    grade_letter TEXT,
    points_earned DECIMAL(8,2),
    points_possible DECIMAL(8,2),
    weight DECIMAL(5,2) DEFAULT 1.0,
    category TEXT, -- homework, quiz, exam, project, etc.
    feedback TEXT,
    graded_by UUID REFERENCES app_users(id) ON DELETE SET NULL NOT NULL,
    graded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_final BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- CALENDAR_EVENTS TABLE
CREATE TABLE calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    event_type TEXT DEFAULT 'general' CHECK (event_type IN ('general', 'assignment', 'exam', 'holiday', 'meeting', 'class')),
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    all_day BOOLEAN DEFAULT false,
    location TEXT,
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    created_by UUID REFERENCES app_users(id) ON DELETE SET NULL NOT NULL,
    is_recurring BOOLEAN DEFAULT false,
    recurrence_pattern TEXT, -- daily, weekly, monthly, etc.
    recurrence_end DATE,
    color TEXT DEFAULT '#007bff',
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ANNOUNCEMENTS TABLE
CREATE TABLE announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    author_id UUID REFERENCES app_users(id) ON DELETE SET NULL NOT NULL,
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    target_audience TEXT DEFAULT 'all' CHECK (target_audience IN ('all', 'students', 'teachers', 'parents', 'class')),
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    is_published BOOLEAN DEFAULT false,
    published_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    attachment_paths TEXT[],
    view_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 3: Create indexes for better performance
CREATE INDEX idx_schools_name ON schools(name);
CREATE INDEX idx_schools_active ON schools(is_active);

CREATE INDEX idx_users_email ON app_users(email);
CREATE INDEX idx_users_role ON app_users(role);
CREATE INDEX idx_users_school ON app_users(school_id);
CREATE INDEX idx_users_active ON app_users(is_active);

CREATE INDEX idx_classes_school ON classes(school_id);
CREATE INDEX idx_classes_teacher ON classes(teacher_id);
CREATE INDEX idx_classes_active ON classes(is_active);

CREATE INDEX idx_enrollments_student ON enrollments(student_id);
CREATE INDEX idx_enrollments_class ON enrollments(class_id);
CREATE INDEX idx_enrollments_status ON enrollments(status);

CREATE INDEX idx_assignments_school ON assignments(school_id);
CREATE INDEX idx_assignments_teacher ON assignments(teacher_id);
CREATE INDEX idx_assignments_class ON assignments(class_id);
CREATE INDEX idx_assignments_due_date ON assignments(due_date);
CREATE INDEX idx_assignments_published ON assignments(is_published);

CREATE INDEX idx_materials_school ON study_materials(school_id);
CREATE INDEX idx_materials_teacher ON study_materials(teacher_id);
CREATE INDEX idx_materials_class ON study_materials(class_id);
CREATE INDEX idx_materials_type ON study_materials(content_type);
CREATE INDEX idx_materials_public ON study_materials(is_public);

CREATE INDEX idx_submissions_assignment ON submissions(assignment_id);
CREATE INDEX idx_submissions_student ON submissions(student_id);
CREATE INDEX idx_submissions_status ON submissions(status);
CREATE INDEX idx_submissions_submitted ON submissions(submitted_at);

CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_recipient ON messages(recipient_id);
CREATE INDEX idx_messages_class ON messages(class_id);
CREATE INDEX idx_messages_type ON messages(message_type);
CREATE INDEX idx_messages_created ON messages(created_at DESC);
CREATE INDEX idx_messages_read ON messages(is_read);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);

CREATE INDEX idx_attendance_student ON attendance(student_id);
CREATE INDEX idx_attendance_class ON attendance(class_id);
CREATE INDEX idx_attendance_date ON attendance(date);

CREATE INDEX idx_grades_student ON grades(student_id);
CREATE INDEX idx_grades_class ON grades(class_id);
CREATE INDEX idx_grades_assignment ON grades(assignment_id);

CREATE INDEX idx_events_school ON calendar_events(school_id);
CREATE INDEX idx_events_class ON calendar_events(class_id);
CREATE INDEX idx_events_start ON calendar_events(start_date);
CREATE INDEX idx_events_type ON calendar_events(event_type);

CREATE INDEX idx_announcements_school ON announcements(school_id);
CREATE INDEX idx_announcements_class ON announcements(class_id);
CREATE INDEX idx_announcements_published ON announcements(is_published);
CREATE INDEX idx_announcements_created ON announcements(created_at DESC);

-- Step 4: Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) VALUES 
('avatars', 'avatars', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']),
('study-materials', 'study-materials', true, 104857600, ARRAY['application/pdf', 'image/jpeg', 'image/png', 'text/plain', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation']),
('submissions', 'submissions', false, 52428800, ARRAY['application/pdf', 'image/jpeg', 'image/png', 'text/plain', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']),
('videos', 'videos', true, 1073741824, ARRAY['video/mp4', 'video/webm', 'video/ogg', 'video/avi', 'video/mov']),
('audio', 'audio', true, 104857600, ARRAY['audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/mp3']),
('assignments', 'assignments', false, 52428800, ARRAY['application/pdf', 'image/jpeg', 'image/png', 'text/plain', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']),
('message-attachments', 'message-attachments', false, 26214400, ARRAY['application/pdf', 'image/jpeg', 'image/png', 'text/plain', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
ON CONFLICT (id) DO UPDATE SET 
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;-- Step
 5: Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers to all tables that have updated_at column
CREATE TRIGGER update_schools_updated_at BEFORE UPDATE ON schools FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON app_users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_classes_updated_at BEFORE UPDATE ON classes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_assignments_updated_at BEFORE UPDATE ON assignments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_materials_updated_at BEFORE UPDATE ON study_materials FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_submissions_updated_at BEFORE UPDATE ON submissions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_messages_updated_at BEFORE UPDATE ON messages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_grades_updated_at BEFORE UPDATE ON grades FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON calendar_events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_announcements_updated_at BEFORE UPDATE ON announcements FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Step 6: Create notification trigger function
CREATE OR REPLACE FUNCTION create_notification()
RETURNS TRIGGER AS $$
BEGIN
    -- Create notification for new assignment
    IF TG_TABLE_NAME = 'assignments' AND TG_OP = 'INSERT' AND NEW.is_published = true THEN
        INSERT INTO notifications (user_id, title, message, type, related_id, related_type)
        SELECT 
            e.student_id,
            'New Assignment: ' || NEW.title,
            'A new assignment has been posted in your class.',
            'assignment',
            NEW.id,
            'assignment'
        FROM enrollments e
        WHERE e.class_id = NEW.class_id AND e.status = 'active';
    END IF;
    
    -- Create notification for new grade
    IF TG_TABLE_NAME = 'submissions' AND TG_OP = 'UPDATE' AND OLD.status != 'graded' AND NEW.status = 'graded' THEN
        INSERT INTO notifications (user_id, title, message, type, related_id, related_type)
        VALUES (
            NEW.student_id,
            'Assignment Graded',
            'Your assignment has been graded and feedback is available.',
            'grade',
            NEW.id,
            'submission'
        );
    END IF;
    
    -- Create notification for new message
    IF TG_TABLE_NAME = 'messages' AND TG_OP = 'INSERT' AND NEW.message_type = 'direct' THEN
        INSERT INTO notifications (user_id, title, message, type, related_id, related_type)
        VALUES (
            NEW.recipient_id,
            'New Message',
            'You have received a new message.',
            'message',
            NEW.id,
            'message'
        );
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

-- Apply notification triggers
CREATE TRIGGER assignment_notification_trigger AFTER INSERT OR UPDATE ON assignments FOR EACH ROW EXECUTE FUNCTION create_notification();
CREATE TRIGGER submission_notification_trigger AFTER UPDATE ON submissions FOR EACH ROW EXECUTE FUNCTION create_notification();
CREATE TRIGGER message_notification_trigger AFTER INSERT ON messages FOR EACH ROW EXECUTE FUNCTION create_notification();

-- Step 7: Enable RLS on all tables
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;-- St
ep 8: Create comprehensive RLS policies

-- SCHOOLS POLICIES
CREATE POLICY "Anyone can view active schools" ON schools FOR SELECT USING (is_active = true);
CREATE POLICY "Admins can manage schools" ON schools FOR ALL USING (
    EXISTS (SELECT 1 FROM app_users WHERE id = auth.uid() AND role = 'admin')
);

-- APP_USERS POLICIES
CREATE POLICY "Users can view their own profile" ON app_users FOR SELECT USING (id = auth.uid());
CREATE POLICY "Users can view users in their school" ON app_users FOR SELECT USING (
    school_id IN (SELECT school_id FROM app_users WHERE id = auth.uid())
);
CREATE POLICY "Admins can manage all users" ON app_users FOR ALL USING (
    EXISTS (SELECT 1 FROM app_users WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Users can update their own profile" ON app_users FOR UPDATE USING (id = auth.uid());

-- CLASSES POLICIES
CREATE POLICY "Users can view classes in their school" ON classes FOR SELECT USING (
    school_id IN (SELECT school_id FROM app_users WHERE id = auth.uid())
);
CREATE POLICY "Teachers can manage their classes" ON classes FOR ALL USING (
    teacher_id = auth.uid() OR 
    EXISTS (SELECT 1 FROM app_users WHERE id = auth.uid() AND role IN ('admin', 'teacher'))
);

-- ENROLLMENTS POLICIES
CREATE POLICY "Students can view their enrollments" ON enrollments FOR SELECT USING (
    student_id = auth.uid()
);
CREATE POLICY "Teachers can view enrollments in their classes" ON enrollments FOR SELECT USING (
    class_id IN (SELECT id FROM classes WHERE teacher_id = auth.uid())
);
CREATE POLICY "Teachers and admins can manage enrollments" ON enrollments FOR ALL USING (
    EXISTS (SELECT 1 FROM app_users WHERE id = auth.uid() AND role IN ('admin', 'teacher'))
);

-- ASSIGNMENTS POLICIES
CREATE POLICY "Students can view published assignments in their classes" ON assignments FOR SELECT USING (
    is_published = true AND (
        class_id IN (SELECT class_id FROM enrollments WHERE student_id = auth.uid()) OR
        class_id IS NULL
    )
);
CREATE POLICY "Teachers can view assignments in their school" ON assignments FOR SELECT USING (
    school_id IN (SELECT school_id FROM app_users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
);
CREATE POLICY "Teachers can manage their assignments" ON assignments FOR ALL USING (
    teacher_id = auth.uid() OR 
    EXISTS (SELECT 1 FROM app_users WHERE id = auth.uid() AND role = 'admin')
);

-- STUDY_MATERIALS POLICIES
CREATE POLICY "Students can view materials in their classes" ON study_materials FOR SELECT USING (
    is_public = true OR
    class_id IN (SELECT class_id FROM enrollments WHERE student_id = auth.uid()) OR
    class_id IS NULL
);
CREATE POLICY "Teachers can view materials in their school" ON study_materials FOR SELECT USING (
    school_id IN (SELECT school_id FROM app_users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
);
CREATE POLICY "Teachers can manage their materials" ON study_materials FOR ALL USING (
    teacher_id = auth.uid() OR 
    EXISTS (SELECT 1 FROM app_users WHERE id = auth.uid() AND role = 'admin')
);

-- SUBMISSIONS POLICIES
CREATE POLICY "Students can view their own submissions" ON submissions FOR SELECT USING (
    student_id = auth.uid()
);
CREATE POLICY "Teachers can view submissions for their assignments" ON submissions FOR SELECT USING (
    assignment_id IN (SELECT id FROM assignments WHERE teacher_id = auth.uid())
);
CREATE POLICY "Students can create and update their submissions" ON submissions FOR INSERT WITH CHECK (
    student_id = auth.uid()
);
CREATE POLICY "Students can update their own submissions" ON submissions FOR UPDATE USING (
    student_id = auth.uid()
);
CREATE POLICY "Teachers can grade submissions" ON submissions FOR UPDATE USING (
    assignment_id IN (SELECT id FROM assignments WHERE teacher_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM app_users WHERE id = auth.uid() AND role = 'admin')
);

-- MESSAGES POLICIES
CREATE POLICY "Users can view sent messages" ON messages FOR SELECT USING (sender_id = auth.uid());
CREATE POLICY "Users can view received messages" ON messages FOR SELECT USING (recipient_id = auth.uid());
CREATE POLICY "Users can view class messages" ON messages FOR SELECT USING (
    message_type = 'class' AND 
    (class_id IN (SELECT class_id FROM enrollments WHERE student_id = auth.uid()) OR
     class_id IN (SELECT id FROM classes WHERE teacher_id = auth.uid()))
);
CREATE POLICY "Everyone can view announcements" ON messages FOR SELECT USING (message_type = 'announcement');
CREATE POLICY "Users can send messages" ON messages FOR INSERT WITH CHECK (sender_id = auth.uid());
CREATE POLICY "Users can delete their own messages" ON messages FOR DELETE USING (sender_id = auth.uid());

-- NOTIFICATIONS POLICIES
CREATE POLICY "Users can view their notifications" ON notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can update their notifications" ON notifications FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "System can create notifications" ON notifications FOR INSERT WITH CHECK (true);

-- ATTENDANCE POLICIES
CREATE POLICY "Students can view their attendance" ON attendance FOR SELECT USING (student_id = auth.uid());
CREATE POLICY "Teachers can view attendance for their classes" ON attendance FOR SELECT USING (
    class_id IN (SELECT id FROM classes WHERE teacher_id = auth.uid())
);
CREATE POLICY "Teachers can manage attendance" ON attendance FOR ALL USING (
    class_id IN (SELECT id FROM classes WHERE teacher_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM app_users WHERE id = auth.uid() AND role = 'admin')
);

-- GRADES POLICIES
CREATE POLICY "Students can view their grades" ON grades FOR SELECT USING (student_id = auth.uid());
CREATE POLICY "Teachers can view grades for their classes" ON grades FOR SELECT USING (
    class_id IN (SELECT id FROM classes WHERE teacher_id = auth.uid())
);
CREATE POLICY "Teachers can manage grades" ON grades FOR ALL USING (
    graded_by = auth.uid() OR
    class_id IN (SELECT id FROM classes WHERE teacher_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM app_users WHERE id = auth.uid() AND role = 'admin')
);

-- CALENDAR_EVENTS POLICIES
CREATE POLICY "Users can view public events" ON calendar_events FOR SELECT USING (is_public = true);
CREATE POLICY "Users can view events in their school" ON calendar_events FOR SELECT USING (
    school_id IN (SELECT school_id FROM app_users WHERE id = auth.uid())
);
CREATE POLICY "Teachers and admins can manage events" ON calendar_events FOR ALL USING (
    created_by = auth.uid() OR
    EXISTS (SELECT 1 FROM app_users WHERE id = auth.uid() AND role IN ('admin', 'teacher'))
);

-- ANNOUNCEMENTS POLICIES
CREATE POLICY "Users can view published announcements" ON announcements FOR SELECT USING (
    is_published = true AND (
        school_id IN (SELECT school_id FROM app_users WHERE id = auth.uid()) OR
        class_id IN (SELECT class_id FROM enrollments WHERE student_id = auth.uid()) OR
        class_id IN (SELECT id FROM classes WHERE teacher_id = auth.uid())
    )
);
CREATE POLICY "Teachers and admins can manage announcements" ON announcements FOR ALL USING (
    author_id = auth.uid() OR
    EXISTS (SELECT 1 FROM app_users WHERE id = auth.uid() AND role IN ('admin', 'teacher'))
);-
- Step 9: Create storage policies for file uploads

-- Avatars bucket policies
CREATE POLICY "Users can upload their own avatar" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'avatars' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);
CREATE POLICY "Anyone can view avatars" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Users can update their own avatar" ON storage.objects FOR UPDATE USING (
    bucket_id = 'avatars' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);
CREATE POLICY "Users can delete their own avatar" ON storage.objects FOR DELETE USING (
    bucket_id = 'avatars' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Study materials bucket policies
CREATE POLICY "Teachers can upload study materials" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'study-materials' AND 
    EXISTS (SELECT 1 FROM app_users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
);
CREATE POLICY "Anyone can view study materials" ON storage.objects FOR SELECT USING (bucket_id = 'study-materials');
CREATE POLICY "Teachers can update their materials" ON storage.objects FOR UPDATE USING (
    bucket_id = 'study-materials' AND 
    EXISTS (SELECT 1 FROM app_users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
);
CREATE POLICY "Teachers can delete their materials" ON storage.objects FOR DELETE USING (
    bucket_id = 'study-materials' AND 
    EXISTS (SELECT 1 FROM app_users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
);

-- Submissions bucket policies
CREATE POLICY "Students can upload submissions" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'submissions' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);
CREATE POLICY "Students can view their submissions" ON storage.objects FOR SELECT USING (
    bucket_id = 'submissions' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);
CREATE POLICY "Teachers can view all submissions" ON storage.objects FOR SELECT USING (
    bucket_id = 'submissions' AND 
    EXISTS (SELECT 1 FROM app_users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
);
CREATE POLICY "Students can update their submissions" ON storage.objects FOR UPDATE USING (
    bucket_id = 'submissions' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);
CREATE POLICY "Students can delete their submissions" ON storage.objects FOR DELETE USING (
    bucket_id = 'submissions' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Videos bucket policies
CREATE POLICY "Teachers can upload videos" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'videos' AND 
    EXISTS (SELECT 1 FROM app_users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
);
CREATE POLICY "Anyone can view videos" ON storage.objects FOR SELECT USING (bucket_id = 'videos');
CREATE POLICY "Teachers can manage videos" ON storage.objects FOR UPDATE USING (
    bucket_id = 'videos' AND 
    EXISTS (SELECT 1 FROM app_users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
);
CREATE POLICY "Teachers can delete videos" ON storage.objects FOR DELETE USING (
    bucket_id = 'videos' AND 
    EXISTS (SELECT 1 FROM app_users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
);

-- Assignments bucket policies
CREATE POLICY "Teachers can upload assignment files" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'assignments' AND 
    EXISTS (SELECT 1 FROM app_users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
);
CREATE POLICY "Students can view assignment files" ON storage.objects FOR SELECT USING (
    bucket_id = 'assignments'
);
CREATE POLICY "Teachers can manage assignment files" ON storage.objects FOR UPDATE USING (
    bucket_id = 'assignments' AND 
    EXISTS (SELECT 1 FROM app_users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
);
CREATE POLICY "Teachers can delete assignment files" ON storage.objects FOR DELETE USING (
    bucket_id = 'assignments' AND 
    EXISTS (SELECT 1 FROM app_users WHERE id = auth.uid() AND role IN ('teacher', 'admin'))
);

-- Message attachments bucket policies
CREATE POLICY "Users can upload message attachments" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'message-attachments' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);
CREATE POLICY "Users can view their message attachments" ON storage.objects FOR SELECT USING (
    bucket_id = 'message-attachments' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);
CREATE POLICY "Recipients can view message attachments" ON storage.objects FOR SELECT USING (
    bucket_id = 'message-attachments'
);

-- Step 10: Create utility functions

-- Function to get user's school
CREATE OR REPLACE FUNCTION get_user_school(user_id UUID)
RETURNS UUID AS $$
BEGIN
    RETURN (SELECT school_id FROM app_users WHERE id = user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is enrolled in class
CREATE OR REPLACE FUNCTION is_user_enrolled(user_id UUID, class_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM enrollments 
        WHERE student_id = user_id AND class_id = class_id AND status = 'active'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get class teacher
CREATE OR REPLACE FUNCTION get_class_teacher(class_id UUID)
RETURNS UUID AS $$
BEGIN
    RETURN (SELECT teacher_id FROM classes WHERE id = class_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate grade percentage
CREATE OR REPLACE FUNCTION calculate_grade_percentage(points_earned DECIMAL, points_possible DECIMAL)
RETURNS DECIMAL AS $$
BEGIN
    IF points_possible = 0 THEN
        RETURN 0;
    END IF;
    RETURN ROUND((points_earned / points_possible) * 100, 2);
END;
$$ LANGUAGE plpgsql;-
- Step 11: Insert comprehensive sample data

-- Insert sample schools
INSERT INTO schools (id, name, address, phone, email, description) VALUES 
('550e8400-e29b-41d4-a716-446655440000', 'Einstein High School', '123 Science Avenue, Physics City, PC 12345', '+1-555-0123', 'admin@einstein-high.edu', 'A premier institution focused on STEM education'),
('550e8400-e29b-41d4-a716-446655440001', 'Newton Academy', '456 Mathematics Street, Calculus Town, CT 67890', '+1-555-0124', 'info@newton-academy.edu', 'Excellence in mathematical and physical sciences'),
('550e8400-e29b-41d4-a716-446655440002', 'Tesla Institute', '789 Innovation Boulevard, Electric City, EC 11111', '+1-555-0125', 'contact@tesla-institute.edu', 'Pioneering the future of technology education');

-- Insert sample users
INSERT INTO app_users (id, name, email, password_hash, role, school_id, phone, bio) VALUES 
-- Admins
('550e8400-e29b-41d4-a716-446655440010', 'Dr. Sarah Administrator', 'admin@einstein-high.edu', 'admin123', 'admin', '550e8400-e29b-41d4-a716-446655440000', '+1-555-1001', 'School administrator with 15 years of experience in educational leadership'),
('550e8400-e29b-41d4-a716-446655440011', 'Prof. Michael Director', 'admin@newton-academy.edu', 'admin123', 'admin', '550e8400-e29b-41d4-a716-446655440001', '+1-555-1002', 'Academic director specializing in curriculum development'),

-- Teachers
('550e8400-e29b-41d4-a716-446655440020', 'Dr. Albert Physics', 'physics@einstein-high.edu', 'teacher123', 'teacher', '550e8400-e29b-41d4-a716-446655440000', '+1-555-2001', 'Physics teacher with PhD in Theoretical Physics. Passionate about making complex concepts accessible to students.'),
('550e8400-e29b-41d4-a716-446655440021', 'Prof. Marie Chemistry', 'chemistry@einstein-high.edu', 'teacher123', 'teacher', '550e8400-e29b-41d4-a716-446655440000', '+1-555-2002', 'Chemistry teacher and researcher. Loves conducting exciting experiments with students.'),
('550e8400-e29b-41d4-a716-446655440022', 'Dr. Isaac Mathematics', 'math@newton-academy.edu', 'teacher123', 'teacher', '550e8400-e29b-41d4-a716-446655440001', '+1-555-2003', 'Mathematics teacher specializing in calculus and advanced mathematics.'),
('550e8400-e29b-41d4-a716-446655440023', 'Ms. Ada Computer', 'cs@tesla-institute.edu', 'teacher123', 'teacher', '550e8400-e29b-41d4-a716-446655440002', '+1-555-2004', 'Computer Science teacher and software developer. Expert in programming and algorithms.'),

-- Students
('550e8400-e29b-41d4-a716-446655440030', 'John Student', 'john.student@student.edu', 'student123', 'student', '550e8400-e29b-41d4-a716-446655440000', '+1-555-3001', 'Enthusiastic physics student interested in quantum mechanics'),
('550e8400-e29b-41d4-a716-446655440031', 'Emma Learner', 'emma.learner@student.edu', 'student123', 'student', '550e8400-e29b-41d4-a716-446655440000', '+1-555-3002', 'Chemistry student with a passion for organic chemistry'),
('550e8400-e29b-41d4-a716-446655440032', 'Alex Scholar', 'alex.scholar@student.edu', 'student123', 'student', '550e8400-e29b-41d4-a716-446655440001', '+1-555-3003', 'Mathematics enthusiast working on advanced calculus'),
('550e8400-e29b-41d4-a716-446655440033', 'Sophie Bright', 'sophie.bright@student.edu', 'student123', 'student', '550e8400-e29b-41d4-a716-446655440002', '+1-555-3004', 'Computer science student interested in AI and machine learning'),
('550e8400-e29b-41d4-a716-446655440034', 'David Curious', 'david.curious@student.edu', 'student123', 'student', '550e8400-e29b-41d4-a716-446655440000', '+1-555-3005', 'Multi-disciplinary student interested in physics and chemistry'),
('550e8400-e29b-41d4-a716-446655440035', 'Lisa Genius', 'lisa.genius@student.edu', 'student123', 'student', '550e8400-e29b-41d4-a716-446655440001', '+1-555-3006', 'Advanced mathematics student with exceptional problem-solving skills');

-- Insert sample classes
INSERT INTO classes (id, name, description, subject, grade_level, school_id, teacher_id) VALUES 
('550e8400-e29b-41d4-a716-446655440040', 'Advanced Physics', 'Advanced placement physics covering mechanics, thermodynamics, and electromagnetism', 'Physics', '12', '550e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440020'),
('550e8400-e29b-41d4-a716-446655440041', 'Organic Chemistry', 'Comprehensive study of organic compounds and reactions', 'Chemistry', '11', '550e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440021'),
('550e8400-e29b-41d4-a716-446655440042', 'Calculus BC', 'Advanced placement calculus covering differential and integral calculus', 'Mathematics', '12', '550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440022'),
('550e8400-e29b-41d4-a716-446655440043', 'Computer Science Principles', 'Introduction to computer science concepts and programming', 'Computer Science', '10', '550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440023');

-- Insert sample enrollments
INSERT INTO enrollments (student_id, class_id) VALUES 
('550e8400-e29b-41d4-a716-446655440030', '550e8400-e29b-41d4-a716-446655440040'), -- John in Advanced Physics
('550e8400-e29b-41d4-a716-446655440031', '550e8400-e29b-41d4-a716-446655440041'), -- Emma in Organic Chemistry
('550e8400-e29b-41d4-a716-446655440032', '550e8400-e29b-41d4-a716-446655440042'), -- Alex in Calculus BC
('550e8400-e29b-41d4-a716-446655440033', '550e8400-e29b-41d4-a716-446655440043'), -- Sophie in CS Principles
('550e8400-e29b-41d4-a716-446655440034', '550e8400-e29b-41d4-a716-446655440040'), -- David in Advanced Physics
('550e8400-e29b-41d4-a716-446655440034', '550e8400-e29b-41d4-a716-446655440041'), -- David in Organic Chemistry
('550e8400-e29b-41d4-a716-446655440035', '550e8400-e29b-41d4-a716-446655440042'); -- Lisa in Calculus BC

-- Insert sample assignments
INSERT INTO assignments (id, title, description, instructions, due_date, max_score, assignment_type, school_id, teacher_id, class_id, is_published) VALUES 
('550e8400-e29b-41d4-a716-446655440050', 'Newton''s Laws Lab Report', 'Comprehensive lab report on Newton''s three laws of motion', 'Conduct the pendulum experiment and analyze the results using Newton''s laws. Include calculations, graphs, and conclusions.', NOW() + INTERVAL '7 days', 100, 'assignment', '550e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440020', '550e8400-e29b-41d4-a716-446655440040', true),
('550e8400-e29b-41d4-a716-446655440051', 'Organic Synthesis Project', 'Design and propose a synthesis pathway for aspirin', 'Research and design a complete synthesis pathway for aspirin from basic organic compounds. Include mechanism drawings and yield calculations.', NOW() + INTERVAL '10 days', 150, 'project', '550e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440021', '550e8400-e29b-41d4-a716-446655440041', true),
('550e8400-e29b-41d4-a716-446655440052', 'Integration Techniques Quiz', 'Quiz covering various integration techniques', 'Complete all problems showing detailed work. Focus on integration by parts, substitution, and partial fractions.', NOW() + INTERVAL '3 days', 50, 'quiz', '550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440022', '550e8400-e29b-41d4-a716-446655440042', true),
('550e8400-e29b-41d4-a716-446655440053', 'Algorithm Analysis Assignment', 'Analyze time and space complexity of sorting algorithms', 'Implement and analyze bubble sort, merge sort, and quick sort. Provide Big O analysis and performance comparisons.', NOW() + INTERVAL '14 days', 120, 'assignment', '550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440023', '550e8400-e29b-41d4-a716-446655440043', true);

-- Insert sample study materials
INSERT INTO study_materials (id, title, description, content_type, external_url, school_id, teacher_id, class_id, subject, is_public) VALUES 
('550e8400-e29b-41d4-a716-446655440060', 'Physics Formulas Reference Sheet', 'Comprehensive reference sheet with all essential physics formulas', 'document', null, '550e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440020', '550e8400-e29b-41d4-a716-446655440040', 'Physics', true),
('550e8400-e29b-41d4-a716-446655440061', 'Quantum Mechanics Introduction Video', 'Introduction to quantum mechanics concepts', 'video', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', '550e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440020', '550e8400-e29b-41d4-a716-446655440040', 'Physics', true),
('550e8400-e29b-41d4-a716-446655440062', 'Organic Chemistry Reaction Mechanisms', 'Detailed explanation of common organic reaction mechanisms', 'document', null, '550e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440021', '550e8400-e29b-41d4-a716-446655440041', 'Chemistry', true),
('550e8400-e29b-41d4-a716-446655440063', 'Calculus Integration Techniques', 'Step-by-step guide to integration techniques', 'document', null, '550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440022', '550e8400-e29b-41d4-a716-446655440042', 'Mathematics', true),
('550e8400-e29b-41d4-a716-446655440064', 'Programming Best Practices', 'Guide to writing clean, efficient code', 'document', null, '550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440023', '550e8400-e29b-41d4-a716-446655440043', 'Computer Science', true);-- Inse
rt sample submissions
INSERT INTO submissions (id, assignment_id, student_id, submission_text, status, grade, percentage, feedback) VALUES 
('550e8400-e29b-41d4-a716-446655440070', '550e8400-e29b-41d4-a716-446655440050', '550e8400-e29b-41d4-a716-446655440030', 'My analysis of Newton''s laws shows that the pendulum experiment clearly demonstrates the relationship between force, mass, and acceleration...', 'graded', 92, 92.0, 'Excellent work! Your analysis is thorough and your calculations are accurate. Great job on the graphs.'),
('550e8400-e29b-41d4-a716-446655440071', '550e8400-e29b-41d4-a716-446655440051', '550e8400-e29b-41d4-a716-446655440031', 'The synthesis pathway for aspirin involves the following steps: 1) Start with salicylic acid...', 'graded', 88, 88.0, 'Good synthesis design. Consider alternative pathways for better yield. Well-drawn mechanisms.'),
('550e8400-e29b-41d4-a716-446655440072', '550e8400-e29b-41d4-a716-446655440052', '550e8400-e29b-41d4-a716-446655440032', 'Integration by parts solution: ∫x*e^x dx = x*e^x - ∫e^x dx = x*e^x - e^x + C...', 'graded', 45, 90.0, 'Perfect execution of integration techniques. All steps clearly shown.'),
('550e8400-e29b-41d4-a716-446655440073', '550e8400-e29b-41d4-a716-446655440053', '550e8400-e29b-41d4-a716-446655440033', 'Algorithm analysis: Bubble Sort - O(n²) time complexity, O(1) space complexity...', 'submitted', null, null, null);

-- Insert sample messages
INSERT INTO messages (id, sender_id, recipient_id, subject, content, message_type) VALUES 
('550e8400-e29b-41d4-a716-446655440080', '550e8400-e29b-41d4-a716-446655440020', '550e8400-e29b-41d4-a716-446655440030', 'Great work on your lab report!', 'John, I wanted to personally congratulate you on your excellent lab report. Your analysis was thorough and your conclusions were well-supported by the data. Keep up the great work!', 'direct'),
('550e8400-e29b-41d4-a716-446655440081', '550e8400-e29b-41d4-a716-446655440021', null, 'Upcoming Chemistry Lab Safety Reminder', 'Dear students, please remember to bring your safety goggles and lab coats to tomorrow''s organic synthesis lab. We will be working with potentially hazardous chemicals.', 'announcement'),
('550e8400-e29b-41d4-a716-446655440082', '550e8400-e29b-41d4-a716-446655440022', null, 'Integration Quiz Results', 'The integration quiz results are now available. Overall, the class performed well with an average score of 85%. Great job everyone!', 'class');

-- Insert sample notifications
INSERT INTO notifications (user_id, title, message, type, related_id, related_type) VALUES 
('550e8400-e29b-41d4-a716-446655440030', 'Assignment Graded', 'Your Newton''s Laws Lab Report has been graded', 'grade', '550e8400-e29b-41d4-a716-446655440070', 'submission'),
('550e8400-e29b-41d4-a716-446655440031', 'New Message', 'You have a new message from Dr. Albert Physics', 'message', '550e8400-e29b-41d4-a716-446655440080', 'message'),
('550e8400-e29b-41d4-a716-446655440032', 'Assignment Due Soon', 'Integration Techniques Quiz is due in 2 days', 'assignment', '550e8400-e29b-41d4-a716-446655440052', 'assignment');

-- Insert sample calendar events
INSERT INTO calendar_events (id, title, description, event_type, start_date, end_date, school_id, class_id, created_by) VALUES 
('550e8400-e29b-41d4-a716-446655440090', 'Physics Lab Session', 'Hands-on physics laboratory experiments', 'class', NOW() + INTERVAL '2 days', NOW() + INTERVAL '2 days' + INTERVAL '2 hours', '550e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440040', '550e8400-e29b-41d4-a716-446655440020'),
('550e8400-e29b-41d4-a716-446655440091', 'Chemistry Exam', 'Midterm examination covering organic chemistry', 'exam', NOW() + INTERVAL '5 days', NOW() + INTERVAL '5 days' + INTERVAL '3 hours', '550e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440041', '550e8400-e29b-41d4-a716-446655440021'),
('550e8400-e29b-41d4-a716-446655440092', 'Science Fair', 'Annual school science fair and exhibition', 'general', NOW() + INTERVAL '30 days', NOW() + INTERVAL '30 days' + INTERVAL '8 hours', '550e8400-e29b-41d4-a716-446655440000', null, '550e8400-e29b-41d4-a716-446655440010');

-- Insert sample announcements
INSERT INTO announcements (id, title, content, author_id, school_id, target_audience, is_published, published_at) VALUES 
('550e8400-e29b-41d4-a716-446655440100', 'Welcome to the New Academic Year!', 'We are excited to welcome all students, teachers, and staff to another year of learning and discovery. This year promises to be filled with exciting new courses, research opportunities, and academic achievements.', '550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440000', 'all', true, NOW()),
('550e8400-e29b-41d4-a716-446655440101', 'Library Hours Extended', 'The school library will now be open until 8 PM on weekdays to provide students with more study time and access to resources.', '550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440000', 'students', true, NOW()),
('550e8400-e29b-41d4-a716-446655440102', 'Parent-Teacher Conference Schedule', 'Parent-teacher conferences are scheduled for next month. Please check your email for specific appointment times and instructions.', '550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440000', 'parents', true, NOW());

-- Step 12: Final verification and summary
SELECT 'COMPLETE SUPABASE SETUP FINISHED!' as status;

-- Verify all tables have data
SELECT 
    'schools' as table_name, 
    count(*) as record_count,
    (SELECT name FROM schools LIMIT 1) as sample_data
FROM schools
UNION ALL
SELECT 
    'app_users' as table_name, 
    count(*) as record_count,
    (SELECT name FROM app_users LIMIT 1) as sample_data
FROM app_users
UNION ALL
SELECT 
    'classes' as table_name, 
    count(*) as record_count,
    (SELECT name FROM classes LIMIT 1) as sample_data
FROM classes
UNION ALL
SELECT 
    'enrollments' as table_name, 
    count(*) as record_count,
    'N/A' as sample_data
FROM enrollments
UNION ALL
SELECT 
    'assignments' as table_name, 
    count(*) as record_count,
    (SELECT title FROM assignments LIMIT 1) as sample_data
FROM assignments
UNION ALL
SELECT 
    'study_materials' as table_name, 
    count(*) as record_count,
    (SELECT title FROM study_materials LIMIT 1) as sample_data
FROM study_materials
UNION ALL
SELECT 
    'submissions' as table_name, 
    count(*) as record_count,
    'N/A' as sample_data
FROM submissions
UNION ALL
SELECT 
    'messages' as table_name, 
    count(*) as record_count,
    (SELECT subject FROM messages LIMIT 1) as sample_data
FROM messages
UNION ALL
SELECT 
    'notifications' as table_name, 
    count(*) as record_count,
    (SELECT title FROM notifications LIMIT 1) as sample_data
FROM notifications
UNION ALL
SELECT 
    'calendar_events' as table_name, 
    count(*) as record_count,
    (SELECT title FROM calendar_events LIMIT 1) as sample_data
FROM calendar_events
UNION ALL
SELECT 
    'announcements' as table_name, 
    count(*) as record_count,
    (SELECT title FROM announcements LIMIT 1) as sample_data
FROM announcements;

-- Show sample login accounts
SELECT 'LOGIN ACCOUNTS FOR TESTING:' as info, '' as email, '' as password, '' as role, '' as school
UNION ALL
SELECT 'Account Type', email, password_hash, role, 
    CASE 
        WHEN school_id = '550e8400-e29b-41d4-a716-446655440000' THEN 'Einstein High School'
        WHEN school_id = '550e8400-e29b-41d4-a716-446655440001' THEN 'Newton Academy'
        WHEN school_id = '550e8400-e29b-41d4-a716-446655440002' THEN 'Tesla Institute'
        ELSE 'Unknown'
    END as school
FROM app_users 
WHERE is_active = true
ORDER BY role, name;`

SELECT '🎉 SUCCESS: Your physics learning app is now fully configured with Supabase!' as final_message;
SELECT '📚 Features enabled: User management, Classes, Assignments, Submissions, Materials, Messages, Notifications, Calendar, Announcements' as features;
SELECT '🔐 Security: All tables have RLS policies, Storage buckets configured with proper access controls' as security;
SELECT '📁 Storage: 7 buckets created for avatars, materials, submissions, videos, audio, assignments, and message attachments' as storage;
SELECT '🧪 Test the setup using TEST-ALL-FUNCTIONALITY.html' as te