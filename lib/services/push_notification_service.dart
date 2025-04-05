import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flowo_client/interfaces/notification_service.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService implements IPushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

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

      try {
        // Configure message handling
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
      } catch (e) {
        logError('Failed to configure message handling: $e');
        // Continue with limited functionality
      }

      _isInitialized = true;
      logInfo('Push notification service initialized');
    } catch (e) {
      logError('Failed to initialize push notification service: $e');
      // Mark as initialized but with limited functionality
      _isInitialized = true;
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    logInfo('Received foreground message: ${message.notification?.title}');
    // Handle the message, e.g., show a local notification
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    logInfo(
      'App opened from push notification: ${message.notification?.title}',
    );
    // Handle the message, e.g., navigate to a specific screen
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
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      logError('Failed to get device token: $e');
      return null;
    }
  }

  @override
  Future<void> notifyTaskStart(Task task, ScheduledTask scheduledTask) async {
    try {
      if (!_isInitialized) await initialize();

      // For push notifications, we would typically send this to a server
      // that would then use FCM to send the notification to the device
      // This is a simplified implementation that logs the notification
      logInfo('Push notification for task start would be sent: ${task.title}');

      // In a real implementation, you would send a request to your server:
      // await _sendNotificationToServer(
      //   title: 'Task Started: ${task.title}',
      //   body: 'Your task has started.',
      //   data: {'taskId': task.id},
      // );
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

      // For push notifications, we would typically send this to a server
      // that would then use FCM to send the notification to the device
      logInfo(
        'Push notification for task reminder would be sent: ${task.title} - $reminderText',
      );

      // In a real implementation, you would send a request to your server:
      // await _sendNotificationToServer(
      //   title: 'Reminder: ${task.title}',
      //   body: reminderText,
      //   data: {'taskId': task.id},
      // );
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
      logInfo('Push notification cancellation would be sent for task: $taskId');

      // In a real implementation, you would send a request to your server:
      // await _sendCancellationToServer(taskId);
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
      logInfo('All push notifications would be cancelled');

      // In a real implementation, you would send a request to your server:
      // await _sendCancelAllToServer();
    } catch (e) {
      logError('Failed to cancel all push notifications: $e');
      // Continue without cancelling the notifications
    }
  }
}

// This function must be top-level (not a class method)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Initialize Firebase if needed
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp();
      } catch (e) {
        print('Failed to initialize Firebase in background handler: $e');
        return;
      }
    }

    print('Handling a background message: ${message.messageId}');
    // Handle background message
  } catch (e) {
    print('Error in background message handler: $e');
  }
}
