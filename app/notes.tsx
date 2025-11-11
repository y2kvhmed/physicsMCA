import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, RefreshControl, TextInput, Alert } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { getCurrentUser } from '../lib/auth';
import { supabase } from '../lib/supabase';
import { handleError, showSuccess } from '../lib/utils';
import { hapticFeedback } from '../lib/haptics';
import AnimatedCard from '../components/AnimatedCard';
import LoadingSpinner from '../components/LoadingSpinner';
import EmptyState from '../components/EmptyState';
import { Colors } from '../constants/Colors';
import { Spacing } from '../constants/Styles';

const NOTE_COLORS = [
  { name: 'White', value: '#FFFFFF' },
  { name: 'Yellow', value: '#FFF9C4' },
  { name: 'Orange', value: '#FFE0B2' },
  { name: 'Pink', value: '#F8BBD0' },
  { name: 'Purple', value: '#E1BEE7' },
  { name: 'Blue', value: '#BBDEFB' },
  { name: 'Green', value: '#C8E6C9' },
];

export default function Notes() {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [notes, setNotes] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [editingNote, setEditingNote] = useState<any>(null);
  const [showEditor, setShowEditor] = useState(false);
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [selectedColor, setSelectedColor] = useState('#FFFFFF');

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const currentUser = await getCurrentUser();
      if (!currentUser) {
        router.replace('/login');
        return;
      }
      setUser(currentUser);
      await loadNotes(currentUser.id);
    } catch (error) {
      handleError(error, 'Failed to load notes');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  const loadNotes = async (userId: string) => {
    const { data, error } = await supabase
      .from('student_notes')
      .select('*')
      .eq('student_id', userId)
      .order('is_pinned', { ascending: false })
      .order('updated_at', { ascending: false });

    if (error) {
      console.error('Error loading notes:', error);
    } else {
      setNotes(data || []);
    }
  };

  const onRefresh = () => {
    setRefreshing(true);
    loadData();
  };

  const openEditor = (note?: any) => {
    hapticFeedback.light();
    if (note) {
      setEditingNote(note);
      setTitle(note.title);
      setContent(note.content || '');
      setSelectedColor(note.color || '#FFFFFF');
    } else {
      setEditingNote(null);
      setTitle('');
      setContent('');
      setSelectedColor('#FFFFFF');
    }
    setShowEditor(true);
  };

  const closeEditor = () => {
    hapticFeedback.light();
    setShowEditor(false);
    setEditingNote(null);
    setTitle('');
    setContent('');
    setSelectedColor('#FFFFFF');
  };

  const saveNote = async () => {
    if (!title.trim()) {
      Alert.alert('Error', 'Please enter a title');
      return;
    }

    try {
      hapticFeedback.medium();
      
      if (editingNote) {
        // Update existing note
        const { error } = await supabase
          .from('student_notes')
          .update({
            title: title.trim(),
            content: content.trim(),
            color: selectedColor,
            updated_at: new Date().toISOString(),
          })
          .eq('id', editingNote.id);

        if (error) throw error;
        showSuccess('Note updated');
      } else {
        // Create new note
        const { error } = await supabase
          .from('student_notes')
          .insert({
            student_id: user.id,
            title: title.trim(),
            content: content.trim(),
            color: selectedColor,
          });

        if (error) throw error;
        showSuccess('Note created');
      }

      hapticFeedback.success();
      closeEditor();
      loadNotes(user.id);
    } catch (error) {
      hapticFeedback.error();
      handleError(error, 'Failed to save note');
    }
  };

  const togglePin = async (note: any) => {
    try {
      hapticFeedback.selection();
      
      const { error } = await supabase
        .from('student_notes')
        .update({ is_pinned: !note.is_pinned })
        .eq('id', note.id);

      if (error) throw error;
      
      loadNotes(user.id);
    } catch (error) {
      handleError(error, 'Failed to pin note');
    }
  };

  const deleteNote = async (note: any) => {
    Alert.alert(
      'Delete Note',
      'Are you sure you want to delete this note?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              hapticFeedback.warning();
              
              const { error } = await supabase
                .from('student_notes')
                .delete()
                .eq('id', note.id);

              if (error) throw error;
              
              hapticFeedback.success();
              showSuccess('Note deleted');
              loadNotes(user.id);
            } catch (error) {
              hapticFeedback.error();
              handleError(error, 'Failed to delete note');
            }
          },
        },
      ]
    );
  };

  if (loading) {
    return <LoadingSpinner />;
  }

  if (showEditor) {
    return (
      <SafeAreaView style={styles.container}>
        <View style={styles.header}>
          <TouchableOpacity onPress={closeEditor}>
            <Ionicons name="close" size={24} color={Colors.primary} />
          </TouchableOpacity>
          <Text style={styles.headerTitle}>{editingNote ? 'Edit Note' : 'New Note'}</Text>
          <TouchableOpacity onPress={saveNote}>
            <Ionicons name="checkmark" size={24} color={Colors.primary} />
          </TouchableOpacity>
        </View>

        <ScrollView style={styles.editorContent}>
          <TextInput
            style={styles.titleInput}
            value={title}
            onChangeText={setTitle}
            placeholder="Note Title"
            placeholderTextColor={Colors.text.tertiary}
          />

          <TextInput
            style={styles.contentInput}
            value={content}
            onChangeText={setContent}
            placeholder="Start typing..."
            placeholderTextColor={Colors.text.tertiary}
            multiline
            textAlignVertical="top"
          />

          <Text style={styles.colorLabel}>Note Color</Text>
          <View style={styles.colorPicker}>
            {NOTE_COLORS.map((color) => (
              <TouchableOpacity
                key={color.value}
                style={[
                  styles.colorOption,
                  { backgroundColor: color.value },
                  selectedColor === color.value && styles.colorOptionSelected,
                ]}
                onPress={() => {
                  hapticFeedback.selection();
                  setSelectedColor(color.value);
                }}
              >
                {selectedColor === color.value && (
                  <Ionicons name="checkmark" size={20} color={Colors.primary} />
                )}
              </TouchableOpacity>
            ))}
          </View>
        </ScrollView>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <Ionicons name="arrow-back" size={24} color={Colors.primary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>My Notes</Text>
        <TouchableOpacity onPress={() => openEditor()}>
          <Ionicons name="add" size={24} color={Colors.primary} />
        </TouchableOpacity>
      </View>

      <ScrollView
        style={styles.content}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      >
        {notes.length === 0 ? (
          <View>
            <EmptyState
              icon="document-text"
              message="No notes yet. Create your first note to get started!"
            />
            <View style={styles.emptyActions}>
              <TouchableOpacity style={styles.createButton} onPress={() => openEditor()}>
                <Ionicons name="add-circle" size={24} color={Colors.text.inverse} />
                <Text style={styles.createButtonText}>Create First Note</Text>
              </TouchableOpacity>
            </View>
          </View>
        ) : (
          <>
            {notes.map((note, index) => (
              <AnimatedCard
                key={note.id}
                delay={50 * (index + 1)}
                style={[styles.noteCard, { backgroundColor: note.color }]}
              >
                <View style={styles.noteHeader}>
                  <View style={styles.noteTitle}>
                    {note.is_pinned && (
                      <Ionicons name="pin" size={16} color={Colors.primary} style={styles.pinIcon} />
                    )}
                    <Text style={styles.noteTitleText}>{note.title}</Text>
                  </View>
                  <View style={styles.noteActions}>
                    <TouchableOpacity onPress={() => togglePin(note)} style={styles.actionButton}>
                      <Ionicons
                        name={note.is_pinned ? 'pin' : 'pin-outline'}
                        size={20}
                        color={Colors.text.secondary}
                      />
                    </TouchableOpacity>
                    <TouchableOpacity onPress={() => openEditor(note)} style={styles.actionButton}>
                      <Ionicons name="create-outline" size={20} color={Colors.text.secondary} />
                    </TouchableOpacity>
                    <TouchableOpacity onPress={() => deleteNote(note)} style={styles.actionButton}>
                      <Ionicons name="trash-outline" size={20} color={Colors.error} />
                    </TouchableOpacity>
                  </View>
                </View>

                {note.content && (
                  <Text style={styles.noteContent} numberOfLines={5}>
                    {note.content}
                  </Text>
                )}

                <Text style={styles.noteDate}>
                  {new Date(note.updated_at).toLocaleDateString()}
                </Text>
              </AnimatedCard>
            ))}
          </>
        )}
      </ScrollView>
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
  content: {
    flex: 1,
    padding: Spacing.lg,
  },
  noteCard: {
    marginBottom: Spacing.lg,
    padding: Spacing.lg,
  },
  noteHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: Spacing.sm,
  },
  noteTitle: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
  },
  pinIcon: {
    marginRight: Spacing.xs,
  },
  noteTitleText: {
    fontSize: 18,
    fontWeight: 'bold',
    color: Colors.text.primary,
    flex: 1,
  },
  noteActions: {
    flexDirection: 'row',
    gap: Spacing.sm,
  },
  actionButton: {
    padding: Spacing.xs,
  },
  noteContent: {
    fontSize: 14,
    color: Colors.text.secondary,
    lineHeight: 20,
    marginBottom: Spacing.sm,
  },
  noteDate: {
    fontSize: 12,
    color: Colors.text.tertiary,
  },
  emptyActions: {
    alignItems: 'center',
    marginTop: Spacing.xl,
  },
  createButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.primary,
    paddingHorizontal: Spacing.xl,
    paddingVertical: Spacing.lg,
    borderRadius: 12,
  },
  createButtonText: {
    color: Colors.text.inverse,
    fontSize: 16,
    fontWeight: '600',
    marginLeft: Spacing.sm,
  },
  editorContent: {
    flex: 1,
    padding: Spacing.lg,
  },
  titleInput: {
    fontSize: 24,
    fontWeight: 'bold',
    color: Colors.text.primary,
    marginBottom: Spacing.lg,
    padding: Spacing.md,
    backgroundColor: Colors.card.background,
    borderRadius: 8,
  },
  contentInput: {
    fontSize: 16,
    color: Colors.text.primary,
    minHeight: 300,
    padding: Spacing.md,
    backgroundColor: Colors.card.background,
    borderRadius: 8,
    marginBottom: Spacing.lg,
  },
  colorLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.text.primary,
    marginBottom: Spacing.sm,
  },
  colorPicker: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.md,
  },
  colorOption: {
    width: 50,
    height: 50,
    borderRadius: 25,
    borderWidth: 2,
    borderColor: Colors.border.medium,
    justifyContent: 'center',
    alignItems: 'center',
  },
  colorOptionSelected: {
    borderColor: Colors.primary,
    borderWidth: 3,
  },
});
