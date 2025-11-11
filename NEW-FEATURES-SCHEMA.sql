-- ============================================
-- NEW FEATURES DATABASE SCHEMA
-- Run this to add all new tables
-- ============================================

-- 1. ATTENDANCE TABLE
DO $$ 
BEGIN
    -- Drop existing attendance table if it exists with wrong schema
    DROP TABLE IF EXISTS attendance CASCADE;
    
    -- Create new attendance table
    CREATE TABLE attendance (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      teacher_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
      school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
      student_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
      date DATE NOT NULL,
      status TEXT NOT NULL CHECK (status IN ('present', 'absent', 'late', 'excused')),
      notes TEXT,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW(),
      UNIQUE(student_id, date)
    );

    CREATE INDEX idx_attendance_date ON attendance(date);
    CREATE INDEX idx_attendance_student ON attendance(student_id);
    CREATE INDEX idx_attendance_school ON attendance(school_id);
END $$;

-- 2. STUDENT NOTES TABLE
CREATE TABLE IF NOT EXISTS student_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT,
  color TEXT DEFAULT '#FFFFFF',
  is_pinned BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notes_student ON student_notes(student_id);
CREATE INDEX IF NOT EXISTS idx_notes_pinned ON student_notes(is_pinned);

-- 3. AUDIT LOGS TABLE
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES app_users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID,
  details JSONB,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_user ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_created ON audit_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_logs(entity_type, entity_id);

-- 4. SUBMISSION COMMENTS TABLE
CREATE TABLE IF NOT EXISTS submission_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id UUID NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  comment TEXT NOT NULL,
  is_private BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_submission_comments ON submission_comments(submission_id);

-- 5. PUSH NOTIFICATION TOKENS TABLE
CREATE TABLE IF NOT EXISTS push_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_push_tokens_user ON push_tokens(user_id);

-- 6. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT NOT NULL,
  entity_id UUID,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);

-- Disable RLS on all new tables
ALTER TABLE attendance DISABLE ROW LEVEL SECURITY;
ALTER TABLE student_notes DISABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE submission_comments DISABLE ROW LEVEL SECURITY;
ALTER TABLE push_tokens DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;

SELECT '✅ New features schema created!' as status;
