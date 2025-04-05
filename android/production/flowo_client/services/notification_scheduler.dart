import 'package:flowo_client/models/notification_type.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/services/notification_manager.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flowo_client/utils/scheduler.dart';

/// A class that extends the functionality of the Scheduler to handle notifications
/// This follows the Decorator pattern to add notification functionality to the Scheduler
class NotificationScheduler {
  final Scheduler _scheduler;
  final NotificationManager _notificationManager;

  NotificationScheduler({
    required Scheduler scheduler,
    required NotificationManager notificationManager,
  }) : _scheduler = scheduler,
       _notificationManager = notificationManager;

  /// Initialize the notification manager
  Future<void> initialize() async {
    await _notificationManager.initialize();
    logInfo('Notification scheduler initialized');
  }

  /// Schedule a task and set up notifications for it
  ScheduledTask? scheduleTask(
    Task task,
    int minSessionDuration, {
    double? urgency,
    List<String>? availableDates,
  }) {
    // Use the original scheduler to schedule the task
    final scheduledTask = _scheduler.scheduleTask(
      task,
      minSessionDuration,
      urgency: urgency,
      availableDates: availableDates,
    );

    if (scheduledTask != null) {
      _scheduleNotificationsForTask(task, scheduledTask);
    }

    return scheduledTask;
  }

  /// Schedule notifications for a task
  void _scheduleNotificationsForTask(Task task, ScheduledTask scheduledTask) {
    try {
      // If notification type is none, don't schedule any notifications
      if (scheduledTask.notification == NotificationType.none) {
        return;
      }

      // Schedule task start notification
      _notificationManager.scheduleTaskStartNotification(
        task,
        scheduledTask,
        scheduledTask.startTime,
      );

      // Schedule reminder notification if needed (e.g., 15 minutes before start)
      final reminderTime = scheduledTask.startTime.subtract(
        const Duration(minutes: 15),
      );
      if (reminderTime.isAfter(DateTime.now())) {
        _notificationManager.scheduleTaskReminderNotification(
          task,
          scheduledTask,
          reminderTime,
          const Duration(minutes: 15),
        );
      }

      logInfo('Notifications scheduled for task: ${task.title}');
    } catch (e) {
      logError('Failed to schedule notifications for task: ${task.title} - $e');
    }
  }

  /// Cancel notifications for a task
  Future<void> cancelNotificationsForTask(String taskId) async {
    await _notificationManager.cancelNotification(taskId);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationManager.cancelAllNotifications();
  }

  /// Set the recipient email for email notifications
  void setRecipientEmail(String email) {
    _notificationManager.setRecipientEmail(email);
  }

  /// Update the notification type for a scheduled task
  void updateNotificationType(
    ScheduledTask scheduledTask,
    NotificationType notificationType,
  ) {
    scheduledTask.notification = notificationType;
  }

  /// Get the scheduler instance
  Scheduler get scheduler => _scheduler;
}
