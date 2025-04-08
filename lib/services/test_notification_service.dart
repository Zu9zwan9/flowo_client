import 'dart:io';

import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotiService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initNotification() async {
    if (_isInitialized) return;
    try {
      tz.initializeTimeZones();
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));

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
      }

      await notificationsPlugin.initialize(initSettings);
      _isInitialized = true;
      appLogger.info('Notification initialization successful', 'NotiService');
    } catch (e) {
      appLogger.error('Notification initialization failed: $e', 'NotiService');
      _isInitialized = false;
    }
  }

  Future<void> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      const methodChannel = MethodChannel('flutter_local_notifications');
      try {
        final bool granted = await methodChannel.invokeMethod(
          'requestExactAlarmPermission',
        );
        if (!granted) {
          appLogger.warning(
            'Exact alarm permission not granted',
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

  Future<void> showTestNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    await notificationsPlugin.show(id, title, body, notificationDetails());
  }

  Future<void> scheduleNotification({
    int id = 1,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    logDebug('Scheduled date: $scheduledDate, now: ${DateTime.now()}');

    await notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelNotification() async {
    await notificationsPlugin.cancelAll();
  }
}
