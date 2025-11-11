-- Add Messages Table for Chat Functionality
-- Run this in Supabase SQL Editor

-- Create messages table
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID REFERENCES app_users(id) ON DELETE CASCADE NOT NULL,
    recipient_id UUID REFERENCES app_users(id) ON DELETE CASCADE,
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type TEXT CHECK (message_type IN ('direct', 'class', 'announcement')) DEFAULT 'direct',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_recipient ON messages(recipient_id);
CREATE INDEX IF NOT EXISTS idx_messages_class ON messages(class_id);
CREATE INDEX IF NOT EXISTS idx_messages_type ON messages(message_type);
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at DESC);

-- Create RLS policies for messages
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view messages they sent
CREATE POLICY "Users can view sent messages" ON messages 
FOR SELECT USING (sender_id = auth.uid());

-- Policy: Users can view messages sent to them
CREATE POLICY "Users can view received messages" ON messages 
FOR SELECT USING (recipient_id = auth.uid());

-- Policy: Users can view class messages for classes they're enrolled in
CREATE POLICY "Users can view class messages" ON messages 
FOR SELECT USING (
    message_type = 'class' AND 
    class_id IN (
        SELECT class_id FROM enrollments WHERE student_id = auth.uid()
        UNION
        SELECT id FROM classes WHERE teacher_id = auth.uid()
    )
);

-- Policy: Everyone can view announcements
CREATE POLICY "Everyone can view announcements" ON messages 
FOR SELECT USING (message_type = 'announcement');

-- Policy: Users can send messages
CREATE POLICY "Users can send messages" ON messages 
FOR INSERT WITH CHECK (sender_id = auth.uid());

-- Policy: Users can delete their own messages
CREATE POLICY "Users can delete own messages" ON messages 
FOR DELETE USING (sender_id = auth.uid());

-- Add updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_messages_updated_at 
    BEFORE UPDATE ON messages 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Insert sample messages for testing
INSERT INTO messages (sender_id, recipient_id, content, message_type) VALUES
(
    (SELECT id FROM app_users WHERE role = 'admin' LIMIT 1),
    (SELECT id FROM app_users WHERE role = 'teacher' LIMIT 1),
    'Welcome to the school management system! Please let me know if you need any help.',
    'direct'
),
(
    (SELECT id FROM app_users WHERE role = 'admin' LIMIT 1),
    NULL,
    'Welcome everyone to the new academic year! Please check your schedules and assignments.',
    'announcement'
),
(
    (SELECT id FROM app_users WHERE role = 'teacher' LIMIT 1),
    (SELECT id FROM classes LIMIT 1).id,
    'Don''t forget about tomorrow''s physics quiz on Newton''s laws!',
    'class'
);

-- Verify the setup
SELECT 'Messages table setup complete!' as status;

SELECT 
    'messages' as table_name,
    count(*) as record_count,
    (SELECT content FROM messages LIMIT 1) as sample_message
FROM messages;