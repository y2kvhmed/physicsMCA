import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, RefreshControl, Alert } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { getCurrentUser } from '../lib/auth';
import { supabase } from '../lib/supabase';
import { handleError, showSuccess } from '../lib/utils';
import { hapticFeedback } from '../lib/haptics';
import AnimatedCard from '../components/AnimatedCard';
import LoadingSpinner from '../components/LoadingSpinner';
import Button from '../components/Button';
import { Colors } from '../constants/Colors';
import { Spacing } from '../constants/Styles';

const ATTENDANCE_STATUS = [
  { value: 'present', label: 'Present', icon: 'checkmark-circle', color: Colors.success },
  { value: 'absent', label: 'Absent', icon: 'close-circle', color: Colors.error },
  { value: 'late', label: 'Late', icon: 'time', color: Colors.warning },
  { value: 'excused', label: 'Excused', icon: 'information-circle', color: Colors.info },
];

export default function Attendance() {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [students, setStudents] = useState<any[]>([]);
  const [attendance, setAttendance] = useState<Map<string, string>>(new Map());
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    loadData();
  }, [selectedDate]);

  const loadData = async () => {
    try {
      const currentUser = await getCurrentUser();
      if (!currentUser || currentUser.role !== 'teacher') {
        router.replace('/');
        return;
      }
      setUser(currentUser);

      // Load students from teacher's school
      const { data: studentsData, error: studentsError } = await supabase
        .from('app_users')
        .select('id, name, email')
        .eq('school_id', currentUser.school_id)
        .eq('role', 'student')
        .eq('is_active', true)
        .order('name');

      if (studentsError) throw studentsError;
      setStudents(studentsData || []);

      // Load existing attendance for selected date
      const dateStr = selectedDate.toISOString().split('T')[0];
      const { data: attendanceData, error: attendanceError } = await supabase
        .from('attendance')
        .select('student_id, status')
        .eq('date', dateStr)
        .eq('school_id', currentUser.school_id);

      if (attendanceError) throw attendanceError;

      // Convert to Map for easy lookup
      const attendanceMap = new Map();
      attendanceData?.forEach((record: any) => {
        attendanceMap.set(record.student_id, record.status);
      });
      setAttendance(attendanceMap);
    } catch (error) {
      handleError(error, 'Failed to load attendance data');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const onRefresh = () => {
    setRefreshing(true);
    loadData();
  };

  const changeDate = (days: number) => {
    hapticFeedback.selection();
    const newDate = new Date(selectedDate);
    newDate.setDate(newDate.getDate() + days);
    setSelectedDate(newDate);
  };

  const setToday = () => {
    hapticFeedback.light();
    setSelectedDate(new Date());
  };

  const markAttendance = (studentId: string, status: string) => {
    hapticFeedback.selection();
    const newAttendance = new Map(attendance);
    newAttendance.set(studentId, status);
    setAttendance(newAttendance);
  };

  const saveAttendance = async () => {
    if (attendance.size === 0) {
      Alert.alert('No Changes', 'Please mark attendance for at least one student');
      return;
    }

    setSaving(true);
    try {
      hapticFeedback.medium();
      const dateStr = selectedDate.toISOString().split('T')[0];

      // Prepare attendance records
      const records = Array.from(attendance.entries()).map(([studentId, status]) => ({
        teacher_id: user.id,
        school_id: user.school_id,
        student_id: studentId,
        date: dateStr,
        status,
      }));

      // Upsert attendance records (insert or update if exists)
      const { error } = await supabase
        .from('attendance')
        .upsert(records, {
          onConflict: 'student_id,date',
        });

      if (error) throw error;

      hapticFeedback.success();
      showSuccess('Attendance saved successfully');
    } catch (error) {
      hapticFeedback.error();
      handleError(error, 'Failed to save attendance');
    } finally {
      setSaving(false);
    }
  };

  const exportAttendance = async () => {
    Alert.alert(
      'Export Attendance',
      'Export attendance for the current month as CSV?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Export',
          onPress: async () => {
            try {
              hapticFeedback.medium();
              
              // Get first and last day of current month
              const firstDay = new Date(selectedDate.getFullYear(), selectedDate.getMonth(), 1);
              const lastDay = new Date(selectedDate.getFullYear(), selectedDate.getMonth() + 1, 0);

              const { data, error } = await supabase
                .from('attendance')
                .select(`
                  date,
                  status,
                  student:app_users!attendance_student_id_fkey(name, email)
                `)
                .eq('school_id', user.school_id)
                .gte('date', firstDay.toISOString().split('T')[0])
                .lte('date', lastDay.toISOString().split('T')[0])
                .order('date')
                .order('student_id');

              if (error) throw error;

              // Convert to CSV
              const csv = convertToCSV(data);
              
              // For web, trigger download
              if (typeof window !== 'undefined') {
                const blob = new Blob([csv], { type: 'text/csv' });
                const url = window.URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = `attendance-${firstDay.toISOString().split('T')[0]}.csv`;
                a.click();
                window.URL.revokeObjectURL(url);
              }

              hapticFeedback.success();
              showSuccess('Attendance exported');
            } catch (error) {
              hapticFeedback.error();
              handleError(error, 'Failed to export attendance');
            }
          },
        },
      ]
    );
  };

  const convertToCSV = (data: any[]): string => {
    const headers = ['Date', 'Student Name', 'Email', 'Status'];
    const rows = data.map((record: any) => [
      record.date,
      record.student?.name || '',
      record.student?.email || '',
      record.status,
    ]);

    return [
      headers.join(','),
      ...rows.map((row: any[]) => row.join(',')),
    ].join('\n');
  };

  const getAttendanceStats = () => {
    const stats = {
      present: 0,
      absent: 0,
      late: 0,
      excused: 0,
      unmarked: students.length,
    };

    attendance.forEach((status) => {
      if (status in stats) {
        stats[status as keyof typeof stats]++;
        stats.unmarked--;
      }
    });

    return stats;
  };

  if (loading) {
    return <LoadingSpinner />;
  }

  const stats = getAttendanceStats();
  const isToday = selectedDate.toDateString() === new Date().toDateString();

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <Ionicons name="arrow-back" size={24} color={Colors.primary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Attendance</Text>
        <TouchableOpacity onPress={exportAttendance}>
          <Ionicons name="download-outline" size={24} color={Colors.primary} />
        </TouchableOpacity>
      </View>

      {/* Date Selector */}
      <View style={styles.dateSelector}>
        <TouchableOpacity onPress={() => changeDate(-1)} style={styles.dateButton}>
          <Ionicons name="chevron-back" size={24} color={Colors.primary} />
        </TouchableOpacity>

        <View style={styles.dateDisplay}>
          <Text style={styles.dateText}>
            {selectedDate.toLocaleDateString('en-US', {
              weekday: 'short',
              month: 'short',
              day: 'numeric',
              year: 'numeric',
            })}
          </Text>
          {!isToday && (
            <TouchableOpacity onPress={setToday} style={styles.todayButton}>
              <Text style={styles.todayText}>Today</Text>
            </TouchableOpacity>
          )}
        </View>

        <TouchableOpacity onPress={() => changeDate(1)} style={styles.dateButton}>
          <Ionicons name="chevron-forward" size={24} color={Colors.primary} />
        </TouchableOpacity>
      </View>

      {/* Stats */}
      <View style={styles.statsContainer}>
        <View style={styles.statItem}>
          <Ionicons name="checkmark-circle" size={20} color={Colors.success} />
          <Text style={styles.statValue}>{stats.present}</Text>
          <Text style={styles.statLabel}>Present</Text>
        </View>
        <View style={styles.statItem}>
          <Ionicons name="close-circle" size={20} color={Colors.error} />
          <Text style={styles.statValue}>{stats.absent}</Text>
          <Text style={styles.statLabel}>Absent</Text>
        </View>
        <View style={styles.statItem}>
          <Ionicons name="time" size={20} color={Colors.warning} />
          <Text style={styles.statValue}>{stats.late}</Text>
          <Text style={styles.statLabel}>Late</Text>
        </View>
        <View style={styles.statItem}>
          <Ionicons name="information-circle" size={20} color={Colors.info} />
          <Text style={styles.statValue}>{stats.excused}</Text>
          <Text style={styles.statLabel}>Excused</Text>
        </View>
      </View>

      <ScrollView
        style={styles.content}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      >
        {students.map((student, index) => {
          const currentStatus = attendance.get(student.id);
          
          return (
            <AnimatedCard key={student.id} delay={30 * (index + 1)} style={styles.studentCard}>
              <View style={styles.studentInfo}>
                <View style={styles.studentAvatar}>
                  <Text style={styles.studentInitial}>
                    {student.name.charAt(0).toUpperCase()}
                  </Text>
                </View>
                <View style={styles.studentDetails}>
                  <Text style={styles.studentName}>{student.name}</Text>
                  <Text style={styles.studentEmail}>{student.email}</Text>
                </View>
              </View>

              <View style={styles.statusButtons}>
                {ATTENDANCE_STATUS.map((status) => (
                  <TouchableOpacity
                    key={status.value}
                    style={[
                      styles.statusButton,
                      currentStatus === status.value && {
                        backgroundColor: status.color + '20',
                        borderColor: status.color,
                      },
                    ]}
                    onPress={() => markAttendance(student.id, status.value)}
                  >
                    <Ionicons
                      name={status.icon}
                      size={20}
                      color={currentStatus === status.value ? status.color : Colors.text.secondary}
                    />
                  </TouchableOpacity>
                ))}
              </View>
            </AnimatedCard>
          );
        })}
      </ScrollView>

      <View style={styles.footer}>
        <Button
          title={saving ? 'Saving...' : 'Save Attendance'}
          onPress={saveAttendance}
          loading={saving}
          disabled={saving || attendance.size === 0}
        />
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.background,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: Spacing.lg,
    backgroundColor: Colors.card.background,
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: Colors.text.primary,
  },
  dateSelector: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: Spacing.lg,
    backgroundColor: Colors.card.background,
    marginBottom: Spacing.md,
  },
  dateButton: {
    padding: Spacing.sm,
  },
  dateDisplay: {
    alignItems: 'center',
  },
  dateText: {
    fontSize: 16,
    fontWeight: '600',
    color: Colors.text.primary,
  },
  todayButton: {
    marginTop: Spacing.xs,
    paddingHorizontal: Spacing.md,
    paddingVertical: Spacing.xs,
    backgroundColor: Colors.primary + '20',
    borderRadius: 12,
  },
  todayText: {
    fontSize: 12,
    color: Colors.primary,
    fontWeight: '600',
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    padding: Spacing.lg,
    backgroundColor: Colors.card.background,
    marginBottom: Spacing.md,
  },
  statItem: {
    alignItems: 'center',
  },
  statValue: {
    fontSize: 18,
    fontWeight: 'bold',
    color: Colors.text.primary,
    marginTop: Spacing.xs,
  },
  statLabel: {
    fontSize: 11,
    color: Colors.text.secondary,
    marginTop: 2,
  },
  content: {
    flex: 1,
    padding: Spacing.lg,
  },
  studentCard: {
    marginBottom: Spacing.md,
    padding: Spacing.lg,
  },
  studentInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: Spacing.md,
  },
  studentAvatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: Colors.primary + '20',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: Spacing.md,
  },
  studentInitial: {
    fontSize: 18,
    fontWeight: 'bold',
    color: Colors.primary,
  },
  studentDetails: {
    flex: 1,
  },
  studentName: {
    fontSize: 16,
    fontWeight: '600',
    color: Colors.text.primary,
  },
  studentEmail: {
    fontSize: 12,
    color: Colors.text.secondary,
    marginTop: 2,
  },
  statusButtons: {
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  statusButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    borderWidth: 2,
    borderColor: Colors.border.medium,
    justifyContent: 'center',
    alignItems: 'center',
  },
  footer: {
    padding: Spacing.lg,
    backgroundColor: Colors.card.background,
    borderTopWidth: 1,
    borderTopColor: Colors.border.light,
  },
});
