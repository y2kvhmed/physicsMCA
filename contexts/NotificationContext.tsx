import React, { createContext, useContext, useEffect, useState, useRef } from 'react';
import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';
import { useRouter } from 'expo-router';
import { registerForPushNotifications, getUnreadNotifications, markNotificationAsRead } from '../lib/pushNotifications';
import { getCurrentUser } from '../lib/auth';

interface NotificationContextType {
  expoPushToken: string | null;
  notifications: any[];
  unreadCount: number;
  refreshNotifications: () => Promise<void>;
  markAsRead: (notificationId: string) => Promise<void>;
  markAllAsRead: () => Promise<void>;
}

const NotificationContext = createContext<NotificationContextType>({
  expoPushToken: null,
  notifications: [],
  unreadCount: 0,
  refreshNotifications: async () => {},
  markAsRead: async () => {},
  markAllAsRead: async () => {},
});

export const useNotifications = () => useContext(NotificationContext);

export function NotificationProvider({ children }: { children: React.ReactNode }) {
  const [expoPushToken, setExpoPushToken] = useState<string | null>(null);
  const [notifications, setNotifications] = useState<any[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const router = useRouter();
  const notificationListener = useRef<any>();
  const responseListener = useRef<any>();

  useEffect(() => {
    setupNotifications();

    // Cleanup listeners on unmount
    return () => {
      if (notificationListener.current) {
        Notifications.removeNotificationSubscription(notificationListener.current);
      }
      if (responseListener.current) {
        Notifications.removeNotificationSubscription(responseListener.current);
      }
    };
  }, []);

  const setupNotifications = async () => {
    try {
      const user = await getCurrentUser();
      if (!user) return;

      // Register for push notifications
      const token = await registerForPushNotifications(user.id);
      setExpoPushToken(token);

      // Load initial notifications
      await refreshNotifications();

      // Listen for notifications received while app is foregrounded
      notificationListener.current = Notifications.addNotificationReceivedListener((notification) => {
        console.log('Notification received:', notification);
        refreshNotifications();
      });

      // Listen for user tapping on notification
      responseListener.current = Notifications.addNotificationResponseReceivedListener((response) => {
        console.log('Notification tapped:', response);
        handleNotificationTap(response.notification);
      });

      // Set up badge count
      if (Platform.OS !== 'web') {
        Notifications.setBadgeCountAsync(unreadCount);
      }
    } catch (error) {
      console.error('Error setting up notifications:', error);
    }
  };

  const refreshNotifications = async () => {
    try {
      const user = await getCurrentUser();
      if (!user) return;

      const unread = await getUnreadNotifications(user.id);
      setNotifications(unread);
      setUnreadCount(unread.length);

      // Update badge count
      if (Platform.OS !== 'web') {
        Notifications.setBadgeCountAsync(unread.length);
      }
    } catch (error) {
      console.error('Error refreshing notifications:', error);
    }
  };

  const markAsRead = async (notificationId: string) => {
    try {
      await markNotificationAsRead(notificationId);
      await refreshNotifications();
    } catch (error) {
      console.error('Error marking notification as read:', error);
    }
  };

  const markAllAsRead = async () => {
    try {
      const user = await getCurrentUser();
      if (!user) return;

      // Mark all as read
      const promises = notifications.map((n) => markNotificationAsRead(n.id));
      await Promise.all(promises);
      await refreshNotifications();
    } catch (error) {
      console.error('Error marking all as read:', error);
    }
  };

  const handleNotificationTap = (notification: any) => {
    const data = notification.request.content.data;
    
    // Navigate based on notification type
    if (data?.type === 'assignment' && data?.entityId) {
      router.push(`/assignment-details?id=${data.entityId}`);
    } else if (data?.type === 'material' && data?.entityId) {
      router.push('/materials-list');
    } else if (data?.type === 'recording' && data?.entityId) {
      router.push('/recordings');
    } else if (data?.type === 'assignment_reminder' && data?.entityId) {
      router.push(`/assignment-details?id=${data.entityId}`);
    }
  };

  return (
    <NotificationContext.Provider
      value={{
        expoPushToken,
        notifications,
        unreadCount,
        refreshNotifications,
        markAsRead,
        markAllAsRead,
      }}
    >
      {children}
    </NotificationContext.Provider>
  );
}
