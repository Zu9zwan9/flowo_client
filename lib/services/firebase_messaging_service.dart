import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flowo_client/firebase_options.dart';
import 'package:flowo_client/interfaces/notification_service.dart';
import 'package:flowo_client/models/notification_type.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// A global handler for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if it hasn't been initialized yet
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  appLogger.info(
    'Handling a background message: ${message.messageId}',
    'FirebaseMessagingService',
  );
  // Process the notification data
  final RemoteNotification? notification = message.notification;
  final Map<String, dynamic> data = message.data;

  // Log message data for debugging
  appLogger.info(
    'Background message data: ${data.toString()}',
    'FirebaseMessagingBackgroundHandler',
  );

  // Initialize local notifications for background messages
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize local notifications
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Create high importance notification channel for Android
  if (Platform.isAndroid) {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // Check message type from data payload and handle accordingly
  final String messageType = data['type'] ?? 'default';
  final int notificationId = message.hashCode;
  final String title =
      notification?.title ?? data['title'] ?? 'New Notification';
  final String body =
      notification?.body ?? data['body'] ?? 'You have a new notification';

  // Create notification details based on platform
  NotificationDetails notificationDetails;

  if (Platform.isAndroid) {
    notificationDetails = const NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
  } else {
    notificationDetails = const NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // Handle different notification types
  switch (messageType) {
    case 'task':
      // Handle task-related notifications
      appLogger.info(
        'Processing task notification in background',
        'FirebaseMessagingBackgroundHandler',
      );

      final String taskId = data['taskId'] ?? '';
      final String taskTitle = data['taskTitle'] ?? title;
      final String taskBody = data['taskBody'] ?? body;

      // Show notification with task-specific payload
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        taskTitle,
        taskBody,
        notificationDetails,
        payload: '{"type":"task","taskId":"$taskId"}',
      );
      break;

    case 'event':
      // Handle event-related notifications
      appLogger.info(
        'Processing event notification in background',
        'FirebaseMessagingBackgroundHandler',
      );

      final String eventId = data['eventId'] ?? '';
      final String eventTitle = data['eventTitle'] ?? title;
      final String eventBody = data['eventBody'] ?? body;

      // Show notification with event-specific payload
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        eventTitle,
        eventBody,
        notificationDetails,
        payload: '{"type":"event","eventId":"$eventId"}',
      );
      break;

    case 'habit':
      // Handle habit-related notifications
      appLogger.info(
        'Processing habit notification in background',
        'FirebaseMessagingBackgroundHandler',
      );

      final String habitId = data['habitId'] ?? '';
      final String habitTitle = data['habitTitle'] ?? title;
      final String habitBody = data['habitBody'] ?? body;

      // Show notification with habit-specific payload
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        habitTitle,
        habitBody,
        notificationDetails,
        payload: '{"type":"habit","habitId":"$habitId"}',
      );
      break;

    case 'deeplink':
      // Handle deeplink notifications
      appLogger.info(
        'Processing deeplink notification in background',
        'FirebaseMessagingBackgroundHandler',
      );

      final String url = data['url'] ?? '';
      final String deeplinkTitle = data['deeplinkTitle'] ?? title;
      final String deeplinkBody = data['deeplinkBody'] ?? body;

      // Show notification with deeplink payload
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        deeplinkTitle,
        deeplinkBody,
        notificationDetails,
        payload: '{"type":"deeplink","url":"$url"}',
      );
      break;

    default:
      // Default handling for other notification types
      appLogger.info(
        'Processing default notification in background',
        'FirebaseMessagingBackgroundHandler',
      );

      // Show default notification
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: '{"type":"default"}',
      );
  }
}

/// Implementation of the NotificationService interface using Firebase Cloud Messaging.
/// This class handles push notifications using Firebase Cloud Messaging (FCM)
/// and local notifications using flutter_local_notifications.
class FirebaseMessagingService implements NotificationService {
  late final FirebaseMessaging _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  Function(Map<String, dynamic>)? _foregroundMessageCallback;
  Function(Map<String, dynamic>)? _notificationTapCallback;

  // Constants for token storage
  static const String _fcmTokenKey = 'fcm_token';
  static const String _fcmTokenTimestampKey = 'fcm_token_timestamp';

  // Stream controller for token refresh events
  final StreamController<String> _tokenRefreshController =
      StreamController<String>.broadcast();

  /// Stream of FCM token refresh events
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  /// Dispose of resources
  Future<void> dispose() async {
    await _tokenRefreshController.close();
    appLogger.info(
      'Firebase Messaging Service disposed',
      'FirebaseMessagingService',
    );
  }

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Firebase Messaging after Firebase is initialized
      _firebaseMessaging = FirebaseMessaging.instance;

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Initialize timezone for scheduled notifications
      tz.initializeTimeZones();
      final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone));

      // Initialize local notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission:
                false, // We'll request permissions separately
            requestBadgePermission: false,
            requestSoundPermission: false,
          );
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationTap(response);
        },
      );

      // Create high importance notification channel for Android
      if (Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(_channel);
      }

      // Set up foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Set up notification tap handler for when the app is in the background
      // but not terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (_notificationTapCallback != null) {
          _notificationTapCallback!(message.data);
        }
      });

      // Set up token refresh listener
      _firebaseMessaging.onTokenRefresh.listen((String token) {
        _saveToken(token);
        _tokenRefreshController.add(token);
        appLogger.info(
          'FCM Token refreshed: $token',
          'FirebaseMessagingService',
        );
      });

      // Check for initial notification (app opened from terminated state)
      final RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        appLogger.info(
          'App opened from terminated state with notification: ${initialMessage.messageId}',
          'FirebaseMessagingService',
        );

        // Handle the initial message
        Future.delayed(const Duration(seconds: 1), () {
          if (_notificationTapCallback != null) {
            _notificationTapCallback!(initialMessage.data);
          }
        });
      }

      // Get and save the current token
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }

      _isInitialized = true;
      appLogger.info(
        'Firebase Messaging Service initialized',
        'FirebaseMessagingService',
      );
    } catch (e) {
      appLogger.error(
        'Failed to initialize Firebase Messaging Service: $e',
        'FirebaseMessagingService',
      );
      _isInitialized = false;
      rethrow;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      // Request permission from user
      final NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      final bool granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (granted) {
        appLogger.info(
          'Notification permissions granted',
          'FirebaseMessagingService',
        );
      } else {
        appLogger.warning(
          'Notification permissions denied',
          'FirebaseMessagingService',
        );
      }

      return granted;
    } catch (e) {
      appLogger.error(
        'Failed to request notification permissions: $e',
        'FirebaseMessagingService',
      );
      return false;
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      // Try to get token from local storage first
      final String? storedToken = await _getStoredToken();
      if (storedToken != null) {
        appLogger.info(
          'Retrieved FCM token from storage',
          'FirebaseMessagingService',
        );
        return storedToken;
      }

      // If not in storage, get from Firebase
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveToken(token);
        appLogger.info('FCM Token: $token', 'FirebaseMessagingService');
      }
      return token;
    } catch (e) {
      appLogger.error(
        'Failed to get FCM token: $e',
        'FirebaseMessagingService',
      );
      return null;
    }
  }

  /// Save the FCM token to local storage
  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);
      await prefs.setInt(
        _fcmTokenTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      appLogger.info('FCM token saved to storage', 'FirebaseMessagingService');
    } catch (e) {
      appLogger.error(
        'Failed to save FCM token: $e',
        'FirebaseMessagingService',
      );
    }
  }

  /// Get the stored FCM token from local storage
  Future<String?> _getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_fcmTokenKey);
    } catch (e) {
      appLogger.error(
        'Failed to get stored FCM token: $e',
        'FirebaseMessagingService',
      );
      return null;
    }
  }

  /// Check if the token needs to be refreshed (older than 7 days)
  Future<bool> _isTokenExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_fcmTokenTimestampKey);
      if (timestamp == null) return true;

      final tokenAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      // Token is considered expired if older than 7 days (604800000 milliseconds)
      return tokenAge > 604800000;
    } catch (e) {
      appLogger.error(
        'Failed to check token expiration: $e',
        'FirebaseMessagingService',
      );
      return true;
    }
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      appLogger.info('Subscribed to topic: $topic', 'FirebaseMessagingService');
    } catch (e) {
      appLogger.error(
        'Failed to subscribe to topic $topic: $e',
        'FirebaseMessagingService',
      );
      rethrow;
    }
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      appLogger.info(
        'Unsubscribed from topic: $topic',
        'FirebaseMessagingService',
      );
    } catch (e) {
      appLogger.error(
        'Failed to unsubscribe from topic $topic: $e',
        'FirebaseMessagingService',
      );
      rethrow;
    }
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationType type = NotificationType.push,
    String notificationType = 'default',
  }) async {
    if (type == NotificationType.disabled || type == NotificationType.none) {
      return;
    }

    try {
      // Create actions for Android and iOS
      final androidActions = createAndroidActions(notificationType);
      final iosActions = createIosActions(notificationType);
      final categoryId = 'category_$notificationType';

      // Create notification details based on notification type and actions
      final NotificationDetails notificationDetails =
          _createNotificationDetails(
            type,
            androidActions: androidActions,
            iosActions: iosActions,
            categoryId: categoryId,
          );

      // Show the notification
      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      appLogger.info(
        'Showed notification with id: $id',
        'FirebaseMessagingService',
      );
    } catch (e) {
      appLogger.error(
        'Failed to show notification: $e',
        'FirebaseMessagingService',
      );
      rethrow;
    }
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    NotificationType type = NotificationType.push,
    String notificationType = 'default',
  }) async {
    if (type == NotificationType.disabled || type == NotificationType.none) {
      return;
    }

    try {
      // Convert DateTime to TZDateTime
      final tz.TZDateTime zonedScheduledTime = tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      );

      // Create actions for Android and iOS
      final androidActions = createAndroidActions(notificationType);
      final iosActions = createIosActions(notificationType);
      final categoryId = 'category_$notificationType';

      // Create notification details based on notification type and actions
      final NotificationDetails notificationDetails =
          _createNotificationDetails(
            type,
            androidActions: androidActions,
            iosActions: iosActions,
            categoryId: categoryId,
          );

      // Schedule the notification
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        zonedScheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );

      appLogger.info(
        'Scheduled notification with id: $id for $scheduledTime',
        'FirebaseMessagingService',
      );
    } catch (e) {
      appLogger.error(
        'Failed to schedule notification: $e',
        'FirebaseMessagingService',
      );
      rethrow;
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      appLogger.info(
        'Cancelled notification with id: $id',
        'FirebaseMessagingService',
      );
    } catch (e) {
      appLogger.error(
        'Failed to cancel notification: $e',
        'FirebaseMessagingService',
      );
      rethrow;
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      appLogger.info('Cancelled all notifications', 'FirebaseMessagingService');
    } catch (e) {
      appLogger.error(
        'Failed to cancel all notifications: $e',
        'FirebaseMessagingService',
      );
      rethrow;
    }
  }

  @override
  void onForegroundMessage(Function(Map<String, dynamic>) callback) {
    _foregroundMessageCallback = callback;
  }

  @override
  void onBackgroundMessage(Function(Map<String, dynamic>) callback) {
    // Background message handling is set up in initialize() method
    // This method is kept for interface compliance
    appLogger.info(
      'Background message handler is set up during initialization',
      'FirebaseMessagingService',
    );
  }

  @override
  void onNotificationTap(Function(Map<String, dynamic>) callback) {
    _notificationTapCallback = callback;
  }

  // Helper method to create notification details based on notification type
  NotificationDetails _createNotificationDetails(
    NotificationType type, {
    List<AndroidNotificationAction>? androidActions,
    List<DarwinNotificationAction>? iosActions,
    String? categoryId,
  }) {
    AndroidNotificationDetails androidDetails;
    DarwinNotificationDetails iosDetails;

    // Configure Android notification details
    switch (type) {
      case NotificationType.vibration:
        androidDetails = AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
          playSound: false,
          actions: androidActions,
        );
        break;
      case NotificationType.sound:
        androidDetails = AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: false,
          actions: androidActions,
        );
        break;
      case NotificationType.both:
        androidDetails = AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
          playSound: true,
          actions: androidActions,
        );
        break;
      case NotificationType.push:
      case NotificationType.pushAndEmail:
      default:
        androidDetails = AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          actions: androidActions,
        );
        break;
    }

    // Configure iOS notification details with action buttons
    List<DarwinNotificationCategory>? darwinCategories;

    if (iosActions != null && iosActions.isNotEmpty && categoryId != null) {
      // Create a category for these actions
      darwinCategories = [
        DarwinNotificationCategory(
          categoryId,
          actions: iosActions,
          options: <DarwinNotificationCategoryOption>{
            DarwinNotificationCategoryOption.allowAnnouncement,
          },
        ),
      ];
    }

    // Configure iOS notification details
    switch (type) {
      case NotificationType.vibration:
        iosDetails = DarwinNotificationDetails(
          presentSound: false,
          presentBadge: true,
          presentAlert: true,
          categoryIdentifier: categoryId,
        );
        break;
      case NotificationType.sound:
        iosDetails = DarwinNotificationDetails(
          presentSound: true,
          presentBadge: true,
          presentAlert: true,
          categoryIdentifier: categoryId,
        );
        break;
      case NotificationType.both:
      case NotificationType.push:
      case NotificationType.pushAndEmail:
      default:
        iosDetails = DarwinNotificationDetails(
          presentSound: true,
          presentBadge: true,
          presentAlert: true,
          categoryIdentifier: categoryId,
        );
        break;
    }

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  /// Create Android notification actions
  List<AndroidNotificationAction> createAndroidActions(
    String type, {
    String? id,
  }) {
    switch (type) {
      case 'task':
        return [
          const AndroidNotificationAction(
            'mark_complete',
            'Mark Complete',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction('snooze', 'Snooze'),
        ];
      case 'event':
        return [
          const AndroidNotificationAction(
            'view_details',
            'View Details',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction('dismiss', 'Dismiss'),
        ];
      case 'habit':
        return [
          const AndroidNotificationAction(
            'mark_done',
            'Mark Done',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction('skip', 'Skip Today'),
        ];
      default:
        return [
          const AndroidNotificationAction(
            'open',
            'Open',
            showsUserInterface: true,
          ),
        ];
    }
  }

  /// Create iOS notification actions
  List<DarwinNotificationAction> createIosActions(String type, {String? id}) {
    switch (type) {
      case 'task':
        return [
          DarwinNotificationAction.plain(
            'mark_complete',
            'Mark Complete',
            options: {DarwinNotificationActionOption.foreground},
          ),
          DarwinNotificationAction.plain('snooze', 'Snooze'),
        ];
      case 'event':
        return [
          DarwinNotificationAction.plain(
            'view_details',
            'View Details',
            options: {DarwinNotificationActionOption.foreground},
          ),
          DarwinNotificationAction.plain('dismiss', 'Dismiss'),
        ];
      case 'habit':
        return [
          DarwinNotificationAction.plain(
            'mark_done',
            'Mark Done',
            options: {DarwinNotificationActionOption.foreground},
          ),
          DarwinNotificationAction.plain('skip', 'Skip Today'),
        ];
      default:
        return [
          DarwinNotificationAction.plain(
            'open',
            'Open',
            options: {DarwinNotificationActionOption.foreground},
          ),
        ];
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    appLogger.info(
      'Received foreground message: ${message.messageId}',
      'FirebaseMessagingService',
    );

    // Extract notification data
    final RemoteNotification? notification = message.notification;
    final Map<String, dynamic> data = message.data;

    // Determine notification type from data
    final String messageType = data['type'] ?? 'default';

    // Show local notification for foreground message
    if (notification != null) {
      // Create actions for Android and iOS
      final androidActions = createAndroidActions(messageType);
      final iosActions = createIosActions(messageType);
      final categoryId = 'category_$messageType';

      // Create notification details with actions
      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: '@mipmap/ic_launcher',
          actions: androidActions,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: true,
          presentBadge: true,
          presentAlert: true,
          categoryIdentifier: categoryId,
        ),
      );

      // Register the iOS category with actions
      if (Platform.isIOS && iosActions.isNotEmpty) {
        _localNotifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }

      // Show the notification
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
        payload: '{"type":"$messageType","data":${message.data.toString()}}',
      );
    }

    // Call the foreground message callback if set
    if (_foregroundMessageCallback != null) {
      _foregroundMessageCallback!(data);
    }
  }

  // Handle notification taps
  void _handleNotificationTap(NotificationResponse response) {
    if (_notificationTapCallback != null) {
      // Parse the payload if it exists
      final String? payload = response.payload;
      if (payload != null) {
        try {
          // Convert string payload to Map
          final Map<String, dynamic> data = {
            'payload': payload,
            'id': response.id,
            'actionId': response.actionId,
            'notificationResponseType':
                response.notificationResponseType.toString(),
          };
          _notificationTapCallback!(data);
        } catch (e) {
          appLogger.error(
            'Failed to parse notification payload: $e',
            'FirebaseMessagingService',
          );
        }
      }
    }
  }
}
