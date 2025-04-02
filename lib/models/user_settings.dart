import 'package:hive/hive.dart';

import 'notification_type.dart';
import 'time_frame.dart';

part 'user_settings.g.dart';

/// Represents notification preferences for different event types
@HiveType(typeId: 12)
class NotificationPreferences extends HiveObject {
  /// Whether to show notifications for task starts
  @HiveField(0)
  bool enableTaskStartNotifications;

  /// Whether to show notifications for task reminders
  @HiveField(1)
  bool enableTaskReminderNotifications;

  /// Whether to show notifications for task completions
  @HiveField(2)
  bool enableTaskCompletionNotifications;

  /// How many minutes before a task to show a reminder
  @HiveField(3)
  int reminderTimeMinutes;

  /// The notification sound to use (filename)
  @HiveField(4)
  String? notificationSound;

  /// The vibration pattern to use
  @HiveField(5)
  String vibrationPattern; // "default", "short", "long", "none"

  /// Whether to use system accent color for notifications
  @HiveField(6)
  bool useSystemColor;

  NotificationPreferences({
    this.enableTaskStartNotifications = true,
    this.enableTaskReminderNotifications = true,
    this.enableTaskCompletionNotifications = true,
    this.reminderTimeMinutes = 5,
    this.notificationSound = 'default',
    this.vibrationPattern = 'default',
    this.useSystemColor = true,
  });
}

@HiveType(typeId: 11)
class UserSettings extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int minSession;

  @HiveField(2)
  int? breakTime;

  @HiveField(3)
  List<TimeFrame> mealBreaks;

  @HiveField(4)
  List<TimeFrame> sleepTime;

  @HiveField(5)
  List<TimeFrame> freeTime;

  @HiveField(6)
  Map<String, bool>? activeDays;

  @HiveField(7)
  NotificationType defaultNotificationType;

  @HiveField(8)
  String dateFormat; // "DD-MM-YYYY" or "MM-DD-YYYY"

  @HiveField(9)
  String monthFormat; // "numeric", "short", "full"

  @HiveField(10)
  bool is24HourFormat;

  @HiveField(11)
  NotificationPreferences? notificationPreferences;

  UserSettings({
    required this.name,
    required this.minSession,
    this.breakTime,
    this.mealBreaks = const [],
    this.sleepTime = const [],
    this.freeTime = const [],
    this.activeDays,
    this.defaultNotificationType = NotificationType.sound,
    this.dateFormat = "DD-MM-YYYY",
    this.monthFormat = "numeric",
    this.is24HourFormat = true,
    NotificationPreferences? notificationPreferences,
  }) : notificationPreferences = NotificationPreferences() {
    activeDays ??= {
      'Monday': true,
      'Tuesday': true,
      'Wednesday': true,
      'Thursday': true,
      'Friday': true,
      'Saturday': true,
      'Sunday': true,
    };
  }
}
