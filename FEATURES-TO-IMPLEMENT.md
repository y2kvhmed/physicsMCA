# Features To Implement

## Immediate Fixes Needed

### 1. ✅ Back Buttons - FIXED
- Changed to use `router.replace('/(tabs)')` instead of `router.back()`

### 2. 🔧 Recording Upload - NEEDS SQL FIX
- **Issue**: 400 error when creating lesson
- **Fix**: Run `FIX-LESSONS-TABLE.sql` in Supabase
- **Reason**: Table schema doesn't match the data being sent

## Features Requested (Not Yet Implemented)

### 3. Multi-School Teacher Support
**Requirement**: Teachers assigned to multiple schools need:
- School selector in chat
- Create different assignments per school
- Create different materials per school

**Implementation Needed**:
- Add `teacher_schools` junction table (many-to-many relationship)
- Update assignment creation UI to show school selector
- Update material creation UI to show school selector
- Update chat UI to show school selector

### 4. Assignment System
**Needs**:
- ✅ Creation (exists but may need fixes)
- ✅ Editing (exists but may need fixes)
- ✅ Deletion (exists but may need fixes)
- Test and fix any errors

### 5. Material System
**Needs**:
- ✅ Creation (exists but may need fixes)
- ✅ Editing (exists but may need fixes)
- ✅ Deletion (exists but may need fixes)
- Test and fix any errors

### 6. Submission System
**Needs**:
- ✅ Student submission (exists but may need fixes)
- ✅ Teacher grading (exists but may need fixes)
- Test and fix any errors

### 7. Chat/Messages System
**Needs**:
- Fix message sending
- Add school selector for multi-school teachers
- Test message display

## Priority Order

1. **FIRST**: Run all SQL fixes:
   - `SIMPLE-FIX-RLS.sql` (if not done)
   - `FIX-STORAGE-POLICIES.sql` (if not done)
   - `ADD-CASCADE-RULES.sql` (if not done)
   - `FIX-LESSONS-TABLE.sql` (NEW - must run)

2. **SECOND**: Test existing features:
   - Try creating assignment
   - Try creating material
   - Try submitting assignment
   - Try sending message
   - Report specific errors

3. **THIRD**: Implement multi-school support (requires database changes)

## Next Steps

1. Run `FIX-LESSONS-TABLE.sql` in Supabase
2. Test recording upload again
3. Test each feature and report specific errors
4. I'll fix issues one at a time based on actual errors
