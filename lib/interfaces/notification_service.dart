import 'package:flowo_client/models/notification_type.dart';

/// Interface for notification services
abstract class NotificationService {
  /// Whether the service has been initialized
  bool get isInitialized;

  /// Initialize the notification service
  Future<void> initialize();

  /// Request permissions for notifications
  Future<bool> requestPermissions();

  /// Get the device token for push notifications
  Future<String?> getToken();

  /// Show a notification immediately
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationType type = NotificationType.push,
    String notificationType = 'default',
  });

  /// Schedule a notification for a future time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    NotificationType type = NotificationType.push,
    String notificationType = 'default',
  });

  /// Cancel a specific notification
  Future<void> cancelNotification(int id);

  /// Cancel all notifications
  Future<void> cancelAllNotifications();

  /// Register a callback for foreground messages
  void onForegroundMessage(Function(Map<String, dynamic>) callback);

  /// Register a callback for background messages
  void onBackgroundMessage(Function(Map<String, dynamic>) callback);

  /// Register a callback for notification taps
  void onNotificationTap(Function(Map<String, dynamic>) callback);

  /// Subscribe to a topic for topic-based notifications
  Future<void> subscribeToTopic(String topic);

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic);
}