import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flowo_client/interfaces/notification_service.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

// This function must be top-level (not a class method)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Initialize Firebase if needed
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp();
      } catch (e) {
        if (kDebugMode) {
          print('Failed to initialize Firebase in background handler: $e');
        }
        return;
      }
    }

    if (kDebugMode) {
      print('Handling a background message: ${message.messageId}');
    }

    // Handle the background message
    // For example, you could show a notification or update local storage
  } catch (e) {
    if (kDebugMode) {
      print('Error in background message handler: $e');
    }
  }
}

/// A service that handles push notifications using Firebase Cloud Messaging.
/// This implementation follows SOLID principles and Apple's Human Interface Guidelines.
class PushNotificationService implements IPushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Server URL for sending push notifications (replace with your actual server URL)
  final String _serverUrl = 'https://your-server-url.com/api/notifications';

  // Channel ID for Android notifications
  static const String _channelId = 'high_importance_channel';
  static const String _channelName = 'High Importance Notifications';
  static const String _channelDescription =
      'Channel for important notifications';

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase if it hasn't been initialized yet
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp();
        } catch (e) {
          logError('Failed to initialize Firebase: $e');
          // Mark as initialized but with limited functionality
          _isInitialized = true;
          return;
        }
      }

      // Request permission for iOS and web
      try {
        await requestPermission();
      } catch (e) {
        logError('Failed to request notification permission: $e');
        // Continue with limited functionality
      }

      // Initialize local notifications for displaying FCM messages
      await _initializeLocalNotifications();

      try {
        // Configure message handling
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );

        // Check for initial message (app opened from terminated state)
        RemoteMessage? initialMessage =
            await FirebaseMessaging.instance.getInitialMessage();
        if (initialMessage != null) {
          _handleInitialMessage(initialMessage);
        }
      } catch (e) {
        logError('Failed to configure message handling: $e');
        // Continue with limited functionality
      }

      // Subscribe to topics if needed
      // await _firebaseMessaging.subscribeToTopic('tasks');

      _isInitialized = true;
      logInfo('Push notification service initialized');
    } catch (e) {
      logError('Failed to initialize push notification service: $e');
      // Mark as initialized but with limited functionality
      _isInitialized = true;
    }
  }

  /// Initialize local notifications plugin for displaying FCM messages
  Future<void> _initializeLocalNotifications() async {
    // iOS initialization settings
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    // Android initialization settings
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize settings
    final InitializationSettings initializationSettings =
        InitializationSettings(
          iOS: initializationSettingsIOS,
          android: initializationSettingsAndroid,
        );

    // Initialize plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDescription,
              importance: Importance.high,
            ),
          );
    }
  }

  /// Handle notification response (when user taps on notification)
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload != null) {
      logInfo('Notification tapped with payload: $payload');

      // Parse the payload and handle navigation
      try {
        final Map<String, dynamic> data = json.decode(payload);
        if (data.containsKey('taskId')) {
          // TODO: Navigate to task details screen
          logInfo('Should navigate to task: ${data['taskId']}');
        }
      } catch (e) {
        logError('Failed to parse notification payload: $e');
      }
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    logInfo('Received foreground message: ${message.notification?.title}');

    // Show a local notification with the FCM message
    _showLocalNotificationFromFCM(message);
  }

  /// Handle messages when app is opened from notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    logInfo(
      'App opened from push notification: ${message.notification?.title}',
    );

    // Handle navigation based on the message data
    if (message.data.containsKey('taskId')) {
      // TODO: Navigate to task details screen
      logInfo('Should navigate to task: ${message.data['taskId']}');
    }
  }

  /// Handle initial message (app opened from terminated state)
  void _handleInitialMessage(RemoteMessage message) {
    logInfo(
      'App opened from terminated state with notification: ${message.notification?.title}',
    );

    // Handle navigation based on the message data
    if (message.data.containsKey('taskId')) {
      // TODO: Navigate to task details screen
      logInfo('Should navigate to task: ${message.data['taskId']}');
    }
  }

  /// Show a local notification from a Firebase Cloud Messaging message
  Future<void> _showLocalNotificationFromFCM(RemoteMessage message) async {
    // Get notification details from the message
    final RemoteNotification? notification = message.notification;
    final AndroidNotification? android = message.notification?.android;
    final AppleNotification? apple = message.notification?.apple;

    // If notification is null, return
    if (notification == null) return;

    // Prepare notification details
    String title = notification.title ?? 'Task Notification';
    String body = notification.body ?? '';
    String? payload = json.encode(message.data);

    // Get system colors for iOS (following Apple's Human Interface Guidelines)
    Color? backgroundColor;
    Color? foregroundColor;

    if (Platform.isIOS || Platform.isMacOS) {
      // Use system colors for iOS (dynamic colors based on light/dark mode)
      backgroundColor = null; // Use system default
      foregroundColor = null; // Use system default
    }

    // Show notification
    await _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          // Use system sound for notifications (Apple HIG recommendation)
          sound: 'default',
          // Use system notification category if available
          categoryIdentifier: 'taskNotification',
        ),
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          // Use default color
          color: Colors.blue,
        ),
      ),
      payload: payload,
    );
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
            criticalAlert: true, // For critical notifications
            announcement: true, // For Siri to announce notifications
          );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }
    return true; // Android doesn't need explicit permission for FCM
  }

  @override
  Future<String?> getDeviceToken() async {
    if (!_isInitialized) await initialize();
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      logError('Failed to get device token: $e');
      return null;
    }
  }

  /// Send a notification to the server for delivery via FCM
  Future<bool> _sendNotificationToServer({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    String? imageUrl,
    String? sound,
    int? badge,
    bool critical = false,
  }) async {
    try {
      // Get the device token
      final String? token = await getDeviceToken();
      if (token == null) {
        logError('Failed to get device token for sending notification');
        return false;
      }

      // Prepare the notification payload
      final Map<String, dynamic> payload = {
        'token': token,
        'notification': {
          'title': title,
          'body': body,
          'image': imageUrl,
          'sound': sound ?? 'default',
          'badge': badge,
          'critical': critical ? 1 : 0,
        },
        'data': data,
        // iOS specific configuration
        'apns': {
          'payload': {
            'aps': {
              'sound': sound ?? 'default',
              'badge': badge,
              'content-available': 1,
              'mutable-content': 1,
              'category': 'taskNotification',
              'thread-id': data['taskId'],
            },
          },
          'headers': {
            'apns-priority': critical ? '10' : '5',
            'apns-push-type': 'alert',
          },
        },
        // Android specific configuration
        'android': {
          'priority': critical ? 'high' : 'normal',
          'notification': {
            'channel_id': _channelId,
            'notification_priority':
                critical ? 'PRIORITY_HIGH' : 'PRIORITY_DEFAULT',
            'default_sound': sound == null,
            'default_vibrate_timings': true,
          },
        },
      };

      // Send the notification to the server
      final http.Response response = await http.post(
        Uri.parse(_serverUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer YOUR_SERVER_API_KEY', // Replace with your server API key
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        logInfo('Notification sent to server successfully');
        return true;
      } else {
        logError('Failed to send notification to server: ${response.body}');
        return false;
      }
    } catch (e) {
      logError('Error sending notification to server: $e');
      return false;
    }
  }

  @override
  Future<void> notifyTaskStart(Task task, ScheduledTask scheduledTask) async {
    try {
      if (!_isInitialized) await initialize();

      // Prepare notification data
      final String title = 'Task Started: ${task.title}';
      final String body = 'Your task has started.';
      final Map<String, dynamic> data = {
        'taskId': task.id,
        'type': 'task_start',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Send notification to server for delivery via FCM
      await _sendNotificationToServer(
        title: title,
        body: body,
        data: data,
        sound: 'default',
        badge: 1,
      );

      logInfo('Push notification for task start sent: ${task.title}');
    } catch (e) {
      logError('Failed to send push notification for task start: $e');
      // Continue without sending the notification
    }
  }

  @override
  Future<void> notifyTaskReminder(
    Task task,
    ScheduledTask scheduledTask,
    Duration timeBeforeStart,
  ) async {
    try {
      if (!_isInitialized) await initialize();

      // Calculate minutes before start
      final minutes = timeBeforeStart.inMinutes;
      final reminderText =
          minutes > 0 ? 'Starting in $minutes minutes' : 'Starting now';

      // Prepare notification data
      final String title = 'Reminder: ${task.title}';
      final String body = reminderText;
      final Map<String, dynamic> data = {
        'taskId': task.id,
        'type': 'task_reminder',
        'minutesBeforeStart': minutes,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Determine if this is a critical notification (starting soon)
      final bool isCritical = minutes <= 5;

      // Send notification to server for delivery via FCM
      await _sendNotificationToServer(
        title: title,
        body: body,
        data: data,
        sound: isCritical ? 'critical.aiff' : 'default',
        badge: 1,
        critical: isCritical,
      );

      logInfo(
        'Push notification for task reminder sent: ${task.title} - $reminderText',
      );
    } catch (e) {
      logError('Failed to send push notification for task reminder: $e');
      // Continue without sending the notification
    }
  }

  @override
  Future<void> cancelNotification(String taskId) async {
    try {
      if (!_isInitialized) await initialize();

      // For push notifications, cancellation would typically be handled by the server
      // Send a request to the server to cancel notifications for this task
      final http.Response response = await http.delete(
        Uri.parse('$_serverUrl/cancel/$taskId'),
        headers: {
          'Authorization':
              'Bearer YOUR_SERVER_API_KEY', // Replace with your server API key
        },
      );

      if (response.statusCode == 200) {
        logInfo('Push notification cancellation sent for task: $taskId');
      } else {
        logError('Failed to cancel push notification: ${response.body}');
      }
    } catch (e) {
      logError('Failed to cancel push notification: $e');
      // Continue without cancelling the notification
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    try {
      if (!_isInitialized) await initialize();

      // For push notifications, cancellation would typically be handled by the server
      // Send a request to the server to cancel all notifications
      final http.Response response = await http.delete(
        Uri.parse('$_serverUrl/cancel-all'),
        headers: {
          'Authorization':
              'Bearer YOUR_SERVER_API_KEY', // Replace with your server API key
        },
      );

      if (response.statusCode == 200) {
        logInfo('All push notifications cancelled');
      } else {
        logError('Failed to cancel all push notifications: ${response.body}');
      }
    } catch (e) {
      logError('Failed to cancel all push notifications: $e');
      // Continue without cancelling the notifications
    }
  }
}
