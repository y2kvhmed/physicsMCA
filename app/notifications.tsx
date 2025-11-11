import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, RefreshControl } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useNotifications } from '../contexts/NotificationContext';
import { hapticFeedback } from '../lib/haptics';
import AnimatedCard from '../components/AnimatedCard';
import EmptyState from '../components/EmptyState';
import { Colors } from '../constants/Colors';
import { Spacing } from '../constants/Styles';

export default function NotificationsScreen() {
  const router = useRouter();
  const { notifications, unreadCount, refreshNotifications, markAsRead, markAllAsRead } = useNotifications();
  const [refreshing, setRefreshing] = React.useState(false);

  const onRefresh = async () => {
    setRefreshing(true);
    await refreshNotifications();
    setRefreshing(false);
  };

  const handleNotificationPress = async (notification: any) => {
    hapticFeedback.light();
    await markAsRead(notification.id);
    
    // Navigate based on type
    if (notification.type === 'assignment' && notification.entity_id) {
      router.push(`/assignment-details?id=${notification.entity_id}`);
    } else if (notification.type === 'material') {
      router.push('/materials-list');
    } else if (notification.type === 'recording') {
      router.push('/recordings');
    }
  };

  const handleMarkAllRead = async () => {
    hapticFeedback.medium();
    await markAllAsRead();
  };

  const getNotificationIcon = (type: string) => {
    switch (type) {
      case 'assignment': return 'document-text';
      case 'material': return 'folder';
      case 'recording': return 'videocam';
      case 'assignment_reminder': return 'alarm';
      default: return 'notifications';
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <Ionicons name="arrow-back" size={24} color={Colors.primary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Notifications</Text>
        {unreadCount > 0 && (
          <TouchableOpacity onPress={handleMarkAllRead}>
            <Text style={styles.markAllRead}>Mark All Read</Text>
          </TouchableOpacity>
        )}
        {unreadCount === 0 && <View style={{ width: 24 }} />}
      </View>

      <ScrollView
        style={styles.content}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      >
        {notifications.length === 0 ? (
          <EmptyState
            icon="notifications-off"
            message="No notifications yet. You'll see updates about assignments, materials, and recordings here."
          />
        ) : (
          notifications.map((notification, index) => (
            <AnimatedCard
              key={notification.id}
              delay={50 * (index + 1)}
              style={styles.notificationCard}
            >
              <TouchableOpacity
                onPress={() => handleNotificationPress(notification)}
                style={styles.notificationContent}
              >
                <View style={styles.iconContainer}>
                  <Ionicons
                    name={getNotificationIcon(notification.type)}
                    size={24}
                    color={Colors.primary}
                  />
                </View>
                <View style={styles.textContainer}>
                  <Text style={styles.notificationTitle}>{notification.title}</Text>
                  <Text style={styles.notificationBody}>{notification.body}</Text>
                  <Text style={styles.notificationTime}>
                    {new Date(notification.created_at).toLocaleString()}
                  </Text>
                </View>
                <Ionicons name="chevron-forward" size={20} color={Colors.text.tertiary} />
              </TouchableOpacity>
            </AnimatedCard>
          ))
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
  markAllRead: {
    fontSize: 14,
    color: Colors.primary,
    fontWeight: '600',
  },
  content: {
    flex: 1,
    padding: Spacing.lg,
  },
  notificationCard: {
    marginBottom: Spacing.md,
  },
  notificationContent: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: Spacing.md,
  },
  iconContainer: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: Colors.primary + '20',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: Spacing.md,
  },
  textContainer: {
    flex: 1,
  },
  notificationTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: Colors.text.primary,
    marginBottom: 4,
  },
  notificationBody: {
    fontSize: 14,
    color: Colors.text.secondary,
    marginBottom: 4,
  },
  notificationTime: {
    fontSize: 12,
    color: Colors.text.tertiary,
  },
});
