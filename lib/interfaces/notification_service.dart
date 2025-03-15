import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/task.dart';

/// Base interface for all notification services
abstract class INotificationService {
  /// Initialize the notification service
  Future<void> initialize();

  /// Send a notification for a task start
  Future<void> notifyTaskStart(Task task, ScheduledTask scheduledTask);

  /// Send a reminder notification for an upcoming task
  Future<void> notifyTaskReminder(
    Task task,
    ScheduledTask scheduledTask,
    Duration timeBeforeStart,
  );

  /// Cancel a notification for a specific task
  Future<void> cancelNotification(String taskId);

  /// Cancel all notifications
  Future<void> cancelAllNotifications();
}

/// Interface for push notification services
abstract class IPushNotificationService extends INotificationService {
  /// Request permission for push notifications
  Future<bool> requestPermission();

  /// Get the device token for push notifications
  Future<String?> getDeviceToken();
}

/// Interface for email notification services
abstract class IEmailNotificationService extends INotificationService {
  /// Set the sender email address
  void setSenderEmail(String email);

  /// Set the recipient email address
  void setRecipientEmail(String email);

  /// Validate an email address
  bool isValidEmail(String email);
}
