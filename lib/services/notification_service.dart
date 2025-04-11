import 'dart:io';

import 'package:flowo_client/models/notification_type.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationInfo {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  String status;

  NotificationInfo({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'scheduledTime': scheduledTime.toIso8601String(),
    'status': status,
  };

  factory NotificationInfo.fromJson(Map<String, dynamic> json) =>
      NotificationInfo(
        id: json['id'],
        title: json['title'],
        body: json['body'],
        scheduledTime: DateTime.parse(json['scheduledTime']),
        status: json['status'],
      );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  final List<NotificationInfo> _notifications = [];
  final Map<String, int> _taskNotificationIds = {};

  bool get isInitialized => _isInitialized;
  List<NotificationInfo> get notifications => List.unmodifiable(_notifications);

  Future<void> initNotification() async {
    if (_isInitialized) return;
    try {
      tz.initializeTimeZones();
      String currentTimeZone;
      try {
        currentTimeZone = await FlutterTimezone.getLocalTimezone();
        appLogger.info(
          'Local timezone retrieved: $currentTimeZone',
          'NotificationService',
        );
      } catch (e) {
        currentTimeZone = 'Europe/Kyiv';
        appLogger.warning(
          'Failed to get local timezone, using Europe/Kyiv: $e',
          'NotificationService',
        );
      }
      try {
        tz.setLocalLocation(tz.getLocation(currentTimeZone));
        appLogger.info(
          'Timezone set to: $currentTimeZone',
          'NotificationService',
        );
      } catch (e) {
        currentTimeZone = 'UTC';
        tz.setLocalLocation(tz.getLocation(currentTimeZone));
        appLogger.warning(
          'Timezone $currentTimeZone not found, falling back to UTC',
          'NotificationService',
        );
      }

      const initSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const initSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: initSettingsAndroid,
        iOS: initSettingsIOS,
      );

      if (Platform.isAndroid) {
        const channel = AndroidNotificationChannel(
          'flowo_notifications',
          'Flowo Notifications',
          description: 'Notifications for tasks, events, and habits',
          importance: Importance.max,
        );
        await notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(channel);
        await requestBatteryOptimizationExemption();
        await requestExactAlarmPermission();
      }

      await notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          try {
            final noti = _notifications.firstWhere((n) => n.id == response.id);
            noti.status = 'delivered';
            appLogger.info(
              'Notification ${noti.id} delivered',
              'NotificationService',
            );
          } catch (e) {
            appLogger.warning(
              'Notification ${response.id} not found in tracking list',
              'NotificationService',
            );
          }
        },
      );
      _isInitialized = true;
      appLogger.info(
        'Notification initialization successful',
        'NotificationService',
      );
    } catch (e) {
      _isInitialized = false;
      appLogger.error(
        'Notification initialization failed: $e',
        'NotificationService',
      );
    }
  }

  Future<void> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      try {
        final androidPlugin =
            notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();
        final canSchedule =
            await androidPlugin?.canScheduleExactNotifications() ?? false;
        if (!canSchedule) {
          await androidPlugin?.requestExactAlarmsPermission();
          appLogger.info(
            'Requested exact alarm permission',
            'NotificationService',
          );
          final updatedCanSchedule =
              await androidPlugin?.canScheduleExactNotifications() ?? false;
          if (!updatedCanSchedule) {
            appLogger.warning(
              'Exact alarm permission not granted by user',
              'NotificationService',
            );
          }
        } else {
          appLogger.info(
            'Exact alarm permission already granted',
            'NotificationService',
          );
        }
      } catch (e) {
        appLogger.error(
          'Failed to request exact alarm permission: $e',
          'NotificationService',
        );
      }
    }
  }

  Future<void> requestBatteryOptimizationExemption() async {
    if (Platform.isAndroid) {
      const methodChannel = MethodChannel('flutter_local_notifications');
      try {
        await methodChannel.invokeMethod('requestBatteryOptimizationExemption');
        appLogger.info(
          'Requested battery optimization exemption',
          'NotificationService',
        );
      } catch (e) {
        appLogger.error(
          'Failed to request battery optimization exemption: $e',
          'NotificationService',
        );
      }
    }
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'flowo_notifications',
        'Flowo Notifications',
        channelDescription: 'Notifications for tasks, events, and habits',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) {
      await initNotification();
    }
    try {
      await notificationsPlugin.show(id, title, body, notificationDetails());
      _notifications.add(
        NotificationInfo(
          id: id,
          title: title,
          body: body,
          scheduledTime: DateTime.now(),
          status: 'delivered',
        ),
      );
      appLogger.info(
        'Notification $id sent immediately',
        'NotificationService',
      );
    } catch (e) {
      _notifications.add(
        NotificationInfo(
          id: id,
          title: title,
          body: body,
          scheduledTime: DateTime.now(),
          status: 'failed',
        ),
      );
      appLogger.error(
        'Failed to send notification $id: $e',
        'NotificationService',
      );
    }
  }

  Future<String?> scheduleNotification({
    int id = 1,
    required String title,
    required String body,
    required int hour,
    required int minute,
    DateTime? date,
  }) async {
    if (!_isInitialized) {
      await initNotification();
    }
    if (!_isInitialized) {
      return 'Initialization failed';
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        date != null
            ? tz.TZDateTime(
              tz.local,
              date.year,
              date.month,
              date.day,
              hour,
              minute,
            )
            : tz.TZDateTime(
              tz.local,
              now.year,
              now.month,
              now.day,
              hour,
              minute,
            );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    appLogger.info(
      'Scheduling notification $id for $scheduledDate (current time: $now)',
      'NotificationService',
    );

    try {
      if (Platform.isAndroid) {
        final androidPlugin =
            notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();
        final canSchedule =
            await androidPlugin?.canScheduleExactNotifications() ?? false;
        if (!canSchedule) {
          return 'Exact alarm permission not granted';
        }
      }

      await notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      _notifications.add(
        NotificationInfo(
          id: id,
          title: title,
          body: body,
          scheduledTime: scheduledDate,
        ),
      );
      appLogger.info(
        'Notification $id scheduled successfully at $scheduledDate',
        'NotificationService',
      );

      // Check pending notifications
      final pendingNotifications =
          await notificationsPlugin.pendingNotificationRequests();
      appLogger.info(
        'Pending notifications: ${pendingNotifications.map((n) => n.id).toList()}',
        'NotificationService',
      );

      return null;
    } catch (e) {
      _notifications.add(
        NotificationInfo(
          id: id,
          title: title,
          body: body,
          scheduledTime: scheduledDate,
          status: 'failed',
        ),
      );
      appLogger.error(
        'Failed to schedule notification $id: $e',
        'NotificationService',
      );
      return 'Failed to schedule: $e';
    }
  }

  Future<void> scheduleTaskNotification(Task task) async {
    if (!_isInitialized) {
      await initNotification();
    }

    if (task.notificationType == null ||
        task.notificationType == NotificationType.disabled ||
        task.notificationTime == null) {
      return;
    }

    // Cancel any existing notification for this task
    if (_taskNotificationIds.containsKey(task.id)) {
      await cancelNotification(_taskNotificationIds[task.id]!);
    }

    final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
    _taskNotificationIds[task.id] = notificationId;

    final deadline = DateTime.fromMillisecondsSinceEpoch(task.deadline);
    final notificationTime = deadline.subtract(
      Duration(minutes: task.notificationTime!),
    );

    // Don't schedule if the notification time is in the past
    if (notificationTime.isBefore(DateTime.now())) {
      appLogger.warning(
        'Notification time for task ${task.id} is in the past, not scheduling',
        'NotificationService',
      );
      return;
    }

    await scheduleNotification(
      id: notificationId,
      title: task.title,
      body: task.notes ?? 'Task deadline approaching',
      hour: notificationTime.hour,
      minute: notificationTime.minute,
      date: notificationTime,
    );
  }

  Future<void> scheduleEventNotification(
    Task event, {
    int minutesBefore = 30,
  }) async {
    if (!_isInitialized) {
      await initNotification();
    }

    // Cancel any existing notification for this event
    if (_taskNotificationIds.containsKey(event.id)) {
      await cancelNotification(_taskNotificationIds[event.id]!);
    }

    final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
    _taskNotificationIds[event.id] = notificationId;

    // For events, we use the scheduledTasks start time if available
    DateTime eventTime;
    if (event.scheduledTasks.isNotEmpty) {
      eventTime = event.scheduledTasks.first.startTime;
    } else {
      eventTime = DateTime.fromMillisecondsSinceEpoch(event.deadline);
    }

    final notificationTime = eventTime.subtract(
      Duration(minutes: minutesBefore),
    );

    // Don't schedule if the notification time is in the past
    if (notificationTime.isBefore(DateTime.now())) {
      appLogger.warning(
        'Notification time for event ${event.id} is in the past, not scheduling',
        'NotificationService',
      );
      return;
    }

    await scheduleNotification(
      id: notificationId,
      title: event.title,
      body: 'Event starting in $minutesBefore minutes',
      hour: notificationTime.hour,
      minute: notificationTime.minute,
      date: notificationTime,
    );
  }

  Future<void> scheduleHabitNotification(
    Task habit,
    DateTime habitTime, {
    int minutesBefore = 30,
  }) async {
    if (!_isInitialized) {
      await initNotification();
    }

    final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;
    final habitKey = '${habit.id}_${habitTime.millisecondsSinceEpoch}';
    _taskNotificationIds[habitKey] = notificationId;

    final notificationTime = habitTime.subtract(
      Duration(minutes: minutesBefore),
    );

    // Don't schedule if the notification time is in the past
    if (notificationTime.isBefore(DateTime.now())) {
      appLogger.warning(
        'Notification time for habit ${habit.id} is in the past, not scheduling',
        'NotificationService',
      );
      return;
    }

    await scheduleNotification(
      id: notificationId,
      title: habit.title,
      body: 'Habit reminder in $minutesBefore minutes',
      hour: notificationTime.hour,
      minute: notificationTime.minute,
      date: notificationTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await notificationsPlugin.cancel(id);
    try {
      final noti = _notifications.firstWhere((n) => n.id == id);
      noti.status = 'cancelled';
      appLogger.info('Notification $id cancelled', 'NotificationService');
    } catch (e) {
      appLogger.warning(
        'Notification $id not found in tracking list',
        'NotificationService',
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
    for (var noti in _notifications) {
      noti.status = 'cancelled';
    }
    _taskNotificationIds.clear();
    appLogger.info('All notifications cancelled', 'NotificationService');
  }
}
