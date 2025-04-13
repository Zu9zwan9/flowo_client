import 'dart:io';

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

class NotiService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  final List<NotificationInfo> _notifications = [];

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
          'NotiService',
        );
      } catch (e) {
        currentTimeZone = 'Europe/Kyiv';
        appLogger.warning(
          'Failed to get local timezone, using Europe/Kyiv: $e',
          'NotiService',
        );
      }
      try {
        tz.setLocalLocation(tz.getLocation(currentTimeZone));
        appLogger.info('Timezone set to: $currentTimeZone', 'NotiService');
      } catch (e) {
        currentTimeZone = 'UTC';
        tz.setLocalLocation(tz.getLocation(currentTimeZone));
        appLogger.warning(
          'Timezone $currentTimeZone not found, falling back to UTC',
          'NotiService',
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
          'your_channel_id',
          'your_channel_name',
          description: 'your_channel_description',
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
            appLogger.info('Notification ${noti.id} delivered', 'NotiService');
          } catch (e) {
            appLogger.warning(
              'Notification ${response.id} not found in tracking list',
              'NotiService',
            );
          }
        },
      );
      _isInitialized = true;
      appLogger.info('Notification initialization successful', 'NotiService');
    } catch (e) {
      _isInitialized = false;
      appLogger.error('Notification initialization failed: $e', 'NotiService');
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
          appLogger.info('Requested exact alarm permission', 'NotiService');
          final updatedCanSchedule =
              await androidPlugin?.canScheduleExactNotifications() ?? false;
          if (!updatedCanSchedule) {
            appLogger.warning(
              'Exact alarm permission not granted by user',
              'NotiService',
            );
          }
        } else {
          appLogger.info(
            'Exact alarm permission already granted',
            'NotiService',
          );
        }
      } catch (e) {
        appLogger.error(
          'Failed to request exact alarm permission: $e',
          'NotiService',
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
          'NotiService',
        );
      } catch (e) {
        appLogger.error(
          'Failed to request battery optimization exemption: $e',
          'NotiService',
        );
      }
    }
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'your_channel_id',
        'your_channel_name',
        channelDescription: 'your_channel_description',
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
      appLogger.info('Notification $id sent immediately', 'NotiService');
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
      appLogger.error('Failed to send notification $id: $e', 'NotiService');
    }
  }

  Future<String?> scheduleNotification({
    int id = 1,
    required String title,
    required String body,
    required int year,
    required int month,
    required int day,
    required int hour,
    required int minute,
  }) async {
    if (!_isInitialized) {
      await initNotification();
    }
    if (!_isInitialized) {
      return 'Initialization failed';
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, year, month, day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      logError('Notification time is in the past: $scheduledDate');
    }

    appLogger.info(
      'Scheduling notification $id for $scheduledDate (current time: $now)',
      'NotiService',
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
        'NotiService',
      );

      // Проверка запланированных уведомлений
      final pendingNotifications =
          await notificationsPlugin.pendingNotificationRequests();
      appLogger.info(
        'Pending notifications: ${pendingNotifications.map((n) => n.id).toList()}',
        'NotiService',
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
      appLogger.error('Failed to schedule notification $id: $e', 'NotiService');
      return 'Failed to schedule: $e';
    }
  }

  Future<void> cancelNotification(int id) async {
    await notificationsPlugin.cancel(id);
    try {
      final noti = _notifications.firstWhere((n) => n.id == id);
      noti.status = 'cancelled';
      appLogger.info('Notification $id cancelled', 'NotiService');
    } catch (e) {
      appLogger.warning(
        'Notification $id not found in tracking list',
        'NotiService',
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
    for (var noti in _notifications) {
      noti.status = 'cancelled';
    }
    appLogger.info('All notifications cancelled', 'NotiService');
  }
}
