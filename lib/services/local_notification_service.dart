import 'package:flowo_client/interfaces/notification_service.dart';
import 'package:flowo_client/models/notification_type.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService implements INotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        // Handle notification tap
        final String? payload = notificationResponse.payload;
        if (payload != null) {
          logInfo('Notification payload: $payload');
          // Navigate to task details page or handle as needed
        }
      },
    );

    _isInitialized = true;
    logInfo('Local notification service initialized');
  }

  @override
  Future<void> notifyTaskStart(Task task, ScheduledTask scheduledTask) async {
    if (!_isInitialized) await initialize();

    // Skip if notification type is none
    if (scheduledTask.notification == NotificationType.none) return;

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'task_start_channel',
      'Task Start Notifications',
      channelDescription: 'Notifications for when tasks start',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration:
          scheduledTask.notification == NotificationType.vibration ||
              scheduledTask.notification == NotificationType.both,
      playSound: scheduledTask.notification == NotificationType.sound ||
          scheduledTask.notification == NotificationType.both,
    );

    final DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: scheduledTask.notification == NotificationType.sound ||
          scheduledTask.notification == NotificationType.both,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      task.id.hashCode,
      'Task Started: ${task.title}',
      'Your task has started.',
      platformChannelSpecifics,
      payload: task.id,
    );

    logInfo('Task start notification sent for: ${task.title}');
  }

  @override
  Future<void> notifyTaskReminder(
      Task task, ScheduledTask scheduledTask, Duration timeBeforeStart) async {
    if (!_isInitialized) await initialize();

    // Skip if notification type is none
    if (scheduledTask.notification == NotificationType.none) return;

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'task_reminder_channel',
      'Task Reminder Notifications',
      channelDescription: 'Reminders for upcoming tasks',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration:
          scheduledTask.notification == NotificationType.vibration ||
              scheduledTask.notification == NotificationType.both,
      playSound: scheduledTask.notification == NotificationType.sound ||
          scheduledTask.notification == NotificationType.both,
    );

    final DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: scheduledTask.notification == NotificationType.sound ||
          scheduledTask.notification == NotificationType.both,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    // Calculate minutes before start
    final minutes = timeBeforeStart.inMinutes;
    final reminderText =
        minutes > 0 ? 'Starting in $minutes minutes' : 'Starting now';

    await _flutterLocalNotificationsPlugin.show(
      task.id.hashCode + 1000, // Different ID for reminders
      'Reminder: ${task.title}',
      reminderText,
      platformChannelSpecifics,
      payload: task.id,
    );

    logInfo('Task reminder notification sent for: ${task.title}');
  }

  @override
  Future<void> cancelNotification(String taskId) async {
    if (!_isInitialized) await initialize();

    await _flutterLocalNotificationsPlugin.cancel(taskId.hashCode);
    await _flutterLocalNotificationsPlugin
        .cancel(taskId.hashCode + 1000); // Cancel reminder too

    logInfo('Notifications cancelled for task: $taskId');
  }

  @override
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) await initialize();

    await _flutterLocalNotificationsPlugin.cancelAll();

    logInfo('All notifications cancelled');
  }

  // Schedule a notification for a future time
  Future<void> scheduleNotification(Task task, ScheduledTask scheduledTask,
      DateTime scheduledTime, bool isReminder) async {
    if (!_isInitialized) await initialize();

    // Skip if notification type is none
    if (scheduledTask.notification == NotificationType.none) return;

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      isReminder ? 'task_reminder_channel' : 'task_start_channel',
      isReminder ? 'Task Reminder Notifications' : 'Task Start Notifications',
      channelDescription: isReminder
          ? 'Reminders for upcoming tasks'
          : 'Notifications for when tasks start',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration:
          scheduledTask.notification == NotificationType.vibration ||
              scheduledTask.notification == NotificationType.both,
      playSound: scheduledTask.notification == NotificationType.sound ||
          scheduledTask.notification == NotificationType.both,
    );

    final DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: scheduledTask.notification == NotificationType.sound ||
          scheduledTask.notification == NotificationType.both,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final title =
        isReminder ? 'Reminder: ${task.title}' : 'Task Started: ${task.title}';
    final body =
        isReminder ? 'Your task is starting soon.' : 'Your task has started.';
    final id = isReminder ? task.id.hashCode + 1000 : task.id.hashCode;

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id,
    );

    logInfo(
        '${isReminder ? "Reminder" : "Task start"} notification scheduled for: ${task.title} at ${scheduledTime.toString()}');
  }
}
