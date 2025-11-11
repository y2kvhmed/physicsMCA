# Database Fix Guide

## Run these SQL scripts in order in your Supabase SQL Editor:

### Step 1: Run FINAL-FIX-ALL-ISSUES.sql
This fixes:
- Disables all RLS policies
- Makes storage buckets public
- Adds missing columns to assignments, study_materials, lessons
- Makes columns nullable

### Step 2: Run ADD-MISSING-COLUMNS.sql
This fixes:
- Adds missing columns to messages table (is_pinned, priority, metadata, file fields)
- Creates chat-files bucket
- Removes mime type restrictions from all storage buckets

### Step 3: Refresh your app

## Current Issues Fixed:

✅ **Teacher Stats Error** - Fixed `.in()` iterator issue in database.ts
✅ **Submissions Query** - Removed invalid `class:classes` join (submissions don't have direct class relationship)
✅ **Storage Mime Types** - All buckets now accept all file types
✅ **Messages Table** - Added all missing columns

## Remaining Issues:

⚠️ **Video "Object not found"** - The videos were uploaded successfully but the path structure might be wrong. Check:
- Path: `videos/recordings/{school_id}/{filename}`
- Make sure the school_id in the path matches the actual school

## If you still see errors:

1. Open browser console
2. Look for the actual error message (not just "400")
3. Check what data is being sent vs what the database expects
4. Run this query in Supabase SQL Editor to see your table structure:

```sql
-- Check messages table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'messages'
ORDER BY ordinal_position;

-- Check assignments table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'assignments'
ORDER BY ordinal_position;

-- Check study_materials table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'study_materials'
ORDER BY ordinal_position;
```
