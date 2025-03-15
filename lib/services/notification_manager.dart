import 'package:flowo_client/models/notification_type.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/services/email_notification_service.dart';
import 'package:flowo_client/services/local_notification_service.dart';
import 'package:flowo_client/services/push_notification_service.dart';
import 'package:flowo_client/utils/logger.dart';

/// A manager class that coordinates between different notification services
/// based on the notification type specified in the scheduled task.
class NotificationManager {
  final LocalNotificationService _localNotificationService;
  final PushNotificationService _pushNotificationService;
  final EmailNotificationService _emailNotificationService;

  bool _isInitialized = false;

  NotificationManager({
    required LocalNotificationService localNotificationService,
    required PushNotificationService pushNotificationService,
    required EmailNotificationService emailNotificationService,
  })  : _localNotificationService = localNotificationService,
        _pushNotificationService = pushNotificationService,
        _emailNotificationService = emailNotificationService;

  /// Factory method to create a NotificationManager with default services
  factory NotificationManager.createDefault() {
    return NotificationManager(
      localNotificationService: LocalNotificationService(),
      pushNotificationService: PushNotificationService(),
      emailNotificationService: EmailNotificationService(),
    );
  }

  /// Initialize all notification services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _localNotificationService.initialize();
      await _pushNotificationService.initialize();
      await _emailNotificationService.initialize();

      _isInitialized = true;
      logInfo('Notification manager initialized');
    } catch (e) {
      logError('Failed to initialize notification manager: $e');
      rethrow;
    }
  }

  /// Set the recipient email for email notifications
  void setRecipientEmail(String email) {
    _emailNotificationService.setRecipientEmail(email);
  }

  /// Schedule a notification for a task start
  Future<void> scheduleTaskStartNotification(
      Task task, ScheduledTask scheduledTask, DateTime scheduledTime) async {
    if (!_isInitialized) await initialize();

    try {
      switch (scheduledTask.notification) {
        case NotificationType.none:
          // No notification needed
          break;
        case NotificationType.vibration:
        case NotificationType.sound:
        case NotificationType.both:
          // Local notification
          await _localNotificationService.scheduleNotification(
              task, scheduledTask, scheduledTime, false // Not a reminder
              );
          break;
        case NotificationType.push:
          // Push notification
          // Since we can't directly schedule push notifications from the client,
          // we would typically schedule this on a server. For now, we'll just log it.
          logInfo(
              'Would schedule push notification for task start: ${task.title} at $scheduledTime');
          break;
        case NotificationType.email:
          // Email notification
          // We'll schedule this locally and send it at the appropriate time
          _scheduleEmailNotification(
              task, scheduledTask, scheduledTime, false // Not a reminder
              );
          break;
        case NotificationType.pushAndEmail:
          // Both push and email
          logInfo(
              'Would schedule push notification for task start: ${task.title} at $scheduledTime');
          _scheduleEmailNotification(
              task, scheduledTask, scheduledTime, false // Not a reminder
              );
          break;
      }
    } catch (e) {
      logError('Failed to schedule task start notification: $e');
    }
  }

  /// Schedule a notification for a task reminder
  Future<void> scheduleTaskReminderNotification(
      Task task,
      ScheduledTask scheduledTask,
      DateTime scheduledTime,
      Duration timeBeforeStart) async {
    if (!_isInitialized) await initialize();

    try {
      switch (scheduledTask.notification) {
        case NotificationType.none:
          // No notification needed
          break;
        case NotificationType.vibration:
        case NotificationType.sound:
        case NotificationType.both:
          // Local notification
          await _localNotificationService.scheduleNotification(
              task, scheduledTask, scheduledTime, true // Is a reminder
              );
          break;
        case NotificationType.push:
          // Push notification
          logInfo(
              'Would schedule push notification for task reminder: ${task.title} at $scheduledTime');
          break;
        case NotificationType.email:
          // Email notification
          _scheduleEmailNotification(
              task, scheduledTask, scheduledTime, true, // Is a reminder
              timeBeforeStart: timeBeforeStart);
          break;
        case NotificationType.pushAndEmail:
          // Both push and email
          logInfo(
              'Would schedule push notification for task reminder: ${task.title} at $scheduledTime');
          _scheduleEmailNotification(
              task, scheduledTask, scheduledTime, true, // Is a reminder
              timeBeforeStart: timeBeforeStart);
          break;
      }
    } catch (e) {
      logError('Failed to schedule task reminder notification: $e');
    }
  }

  /// Send a notification for a task start
  Future<void> notifyTaskStart(Task task, ScheduledTask scheduledTask) async {
    if (!_isInitialized) await initialize();

    try {
      switch (scheduledTask.notification) {
        case NotificationType.none:
          // No notification needed
          break;
        case NotificationType.vibration:
        case NotificationType.sound:
        case NotificationType.both:
          // Local notification
          await _localNotificationService.notifyTaskStart(task, scheduledTask);
          break;
        case NotificationType.push:
          // Push notification
          await _pushNotificationService.notifyTaskStart(task, scheduledTask);
          break;
        case NotificationType.email:
          // Email notification
          await _emailNotificationService.notifyTaskStart(task, scheduledTask);
          break;
        case NotificationType.pushAndEmail:
          // Both push and email
          await _pushNotificationService.notifyTaskStart(task, scheduledTask);
          await _emailNotificationService.notifyTaskStart(task, scheduledTask);
          break;
      }
    } catch (e) {
      logError('Failed to send task start notification: $e');
    }
  }

  /// Send a notification for a task reminder
  Future<void> notifyTaskReminder(
      Task task, ScheduledTask scheduledTask, Duration timeBeforeStart) async {
    if (!_isInitialized) await initialize();

    try {
      switch (scheduledTask.notification) {
        case NotificationType.none:
          // No notification needed
          break;
        case NotificationType.vibration:
        case NotificationType.sound:
        case NotificationType.both:
          // Local notification
          await _localNotificationService.notifyTaskReminder(
              task, scheduledTask, timeBeforeStart);
          break;
        case NotificationType.push:
          // Push notification
          await _pushNotificationService.notifyTaskReminder(
              task, scheduledTask, timeBeforeStart);
          break;
        case NotificationType.email:
          // Email notification
          await _emailNotificationService.notifyTaskReminder(
              task, scheduledTask, timeBeforeStart);
          break;
        case NotificationType.pushAndEmail:
          // Both push and email
          await _pushNotificationService.notifyTaskReminder(
              task, scheduledTask, timeBeforeStart);
          await _emailNotificationService.notifyTaskReminder(
              task, scheduledTask, timeBeforeStart);
          break;
      }
    } catch (e) {
      logError('Failed to send task reminder notification: $e');
    }
  }

  /// Cancel a notification for a specific task
  Future<void> cancelNotification(String taskId) async {
    if (!_isInitialized) await initialize();

    try {
      // Cancel notifications in all services
      await _localNotificationService.cancelNotification(taskId);
      await _pushNotificationService.cancelNotification(taskId);
      await _emailNotificationService.cancelNotification(taskId);

      logInfo('Notifications cancelled for task: $taskId');
    } catch (e) {
      logError('Failed to cancel notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) await initialize();

    try {
      // Cancel notifications in all services
      await _localNotificationService.cancelAllNotifications();
      await _pushNotificationService.cancelAllNotifications();
      await _emailNotificationService.cancelAllNotifications();

      logInfo('All notifications cancelled');
    } catch (e) {
      logError('Failed to cancel all notifications: $e');
    }
  }

  /// Schedule an email notification to be sent at a specific time
  void _scheduleEmailNotification(Task task, ScheduledTask scheduledTask,
      DateTime scheduledTime, bool isReminder,
      {Duration? timeBeforeStart}) {
    // In a real implementation, this would use a background task scheduler
    // or a server-side solution to send the email at the scheduled time.
    // For simplicity, we'll just log that we would schedule it.
    final actionType = isReminder ? 'reminder' : 'start';
    logInfo(
        'Would schedule email notification for task $actionType: ${task.title} at $scheduledTime');

    // In a real implementation, you might do something like:
    // _backgroundTaskScheduler.scheduleTask(
    //   'send_email_notification',
    //   scheduledTime,
    //   {
    //     'taskId': task.id,
    //     'isReminder': isReminder,
    //     'timeBeforeStart': timeBeforeStart?.inMilliseconds,
    //   },
    // );
  }
}
