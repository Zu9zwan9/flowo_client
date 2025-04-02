import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flowo_client/interfaces/notification_service.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/models/user_settings.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

// This function must be top-level (not a class method)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  if (kDebugMode) {
    print('Handling a background message: ${message.messageId}');
  }
  // Handle background message
}

/// Service for handling push notifications using Firebase Cloud Messaging
class PushNotificationService implements IPushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  NotificationPreferences? _preferences;

  // Server URL for sending push notifications
  // In a real app, this would be your backend server that handles FCM
  static const String _serverUrl = 'https://fcm.googleapis.com/fcm/send';

  // FCM server key (in a real app, this would be stored securely on your backend)
  static const String _serverKey =
      'firebase-adminsdk-fbsvc@flowo-fc2e5.iam.gserviceaccount.com';

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase if it hasn't been initialized yet
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Request permission for iOS and web
      await requestPermission();

      // Initialize local notifications for handling FCM messages
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

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      // Configure message handling
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Subscribe to topics
      await _firebaseMessaging.subscribeToTopic('all_users');

      _isInitialized = true;
      logInfo('Push notification service initialized');
    } catch (e) {
      logError('Failed to initialize push notification service: $e');
      rethrow;
    }
  }

  /// Set notification preferences
  void setNotificationPreferences(NotificationPreferences preferences) {
    _preferences = preferences;
    logInfo('Push notification preferences updated');
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload != null) {
      logInfo('Notification payload: $payload');
      // Handle notification tap - navigate to appropriate screen
      // This would typically be handled by a navigation service
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    logInfo('Received foreground message: ${message.notification?.title}');

    // Show a local notification when a FCM message is received in foreground
    if (message.notification != null) {
      _showLocalNotification(
        message.notification!.title ?? 'New Notification',
        message.notification!.body ?? '',
        message.data,
      );
    }
  }

  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    final androidDetails = AndroidNotificationDetails(
      'push_notification_channel',
      'Push Notifications',
      channelDescription: 'Channel for push notifications',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: _preferences?.vibrationPattern != 'none',
      playSound: _preferences?.notificationSound != null,
      color:
          _preferences?.useSystemColor == true ? null : const Color(0xFF007AFF),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: _preferences?.notificationSound != null,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: jsonEncode(data),
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    logInfo(
      'App opened from push notification: ${message.notification?.title}',
    );

    // Handle navigation based on the notification data
    if (message.data.containsKey('taskId')) {
      // Navigate to task details
      // This would typically be handled by a navigation service
      logInfo('Should navigate to task: ${message.data['taskId']}');
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }
    return true; // Android doesn't need explicit permission for FCM
  }

  @override
  Future<String?> getDeviceToken() async {
    if (!_isInitialized) await initialize();
    return await _firebaseMessaging.getToken();
  }

  /// Send a notification to the FCM server
  Future<bool> _sendNotificationToServer({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    String? token,
    String? topic,
  }) async {
    try {
      // In a real app, this would be a request to your backend server
      // which would then use FCM to send the notification
      // For demonstration purposes, we're showing how to directly call FCM
      // (not recommended for production apps due to security concerns)

      final Map<String, dynamic> notification = {
        'body': body,
        'title': title,
        'sound': 'default',
      };

      final Map<String, dynamic> payload = {
        'notification': notification,
        'data': data,
        'priority': 'high',
      };

      // Target either a specific device or a topic
      if (token != null) {
        payload['to'] = token;
      } else if (topic != null) {
        payload['to'] = '/topics/$topic';
      } else {
        logError('No target specified for push notification');
        return false;
      }

      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        logInfo('Push notification sent successfully');
        return true;
      } else {
        logError('Failed to send push notification: ${response.body}');
        return false;
      }
    } catch (e) {
      logError('Error sending push notification: $e');
      return false;
    }
  }

  @override
  Future<void> notifyTaskStart(Task task, ScheduledTask scheduledTask) async {
    if (!_isInitialized) await initialize();

    if (_preferences?.enableTaskStartNotifications != true) {
      logInfo('Task start notifications are disabled');
      return;
    }

    final token = await getDeviceToken();
    if (token == null) {
      logError('Failed to get device token for push notification');
      return;
    }

    await _sendNotificationToServer(
      title: 'Task Started: ${task.title}',
      body: 'Your task has started.',
      data: {'taskId': task.id, 'action': 'task_start'},
      token: token,
    );

    // Also show a local notification in case the app is in foreground
    await _showLocalNotification(
      'Task Started: ${task.title}',
      'Your task has started.',
      {'taskId': task.id, 'action': 'task_start'},
    );
  }

  @override
  Future<void> notifyTaskReminder(
    Task task,
    ScheduledTask scheduledTask,
    Duration timeBeforeStart,
  ) async {
    if (!_isInitialized) await initialize();

    if (_preferences?.enableTaskReminderNotifications != true) {
      logInfo('Task reminder notifications are disabled');
      return;
    }

    // Calculate minutes before start
    final minutes = timeBeforeStart.inMinutes;
    final reminderText =
        minutes > 0 ? 'Starting in $minutes minutes' : 'Starting now';

    final token = await getDeviceToken();
    if (token == null) {
      logError('Failed to get device token for push notification');
      return;
    }

    await _sendNotificationToServer(
      title: 'Reminder: ${task.title}',
      body: reminderText,
      data: {
        'taskId': task.id,
        'action': 'task_reminder',
        'timeBeforeStart': timeBeforeStart.inMilliseconds,
      },
      token: token,
    );

    // Also show a local notification in case the app is in foreground
    await _showLocalNotification('Reminder: ${task.title}', reminderText, {
      'taskId': task.id,
      'action': 'task_reminder',
      'timeBeforeStart': timeBeforeStart.inMilliseconds,
    });
  }

  @override
  Future<void> cancelNotification(String taskId) async {
    if (!_isInitialized) await initialize();

    // For push notifications, cancellation would typically be handled by the server
    // Here we're just logging it
    logInfo('Push notification cancellation would be sent for task: $taskId');

    // Cancel local notifications for this task
    final notificationId = taskId.hashCode;
    await _localNotifications.cancel(notificationId);
    await _localNotifications.cancel(
      notificationId + 1000,
    ); // Cancel reminder too
  }

  @override
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) await initialize();

    // For push notifications, cancellation would typically be handled by the server
    // Here we're just logging it
    logInfo('All push notifications would be cancelled');

    // Cancel all local notifications
    await _localNotifications.cancelAll();
  }
}
