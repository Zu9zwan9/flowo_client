import 'package:hive/hive.dart';

import 'app_theme.dart';
import 'notification_type.dart';
import 'time_frame.dart';

part 'user_settings.g.dart';

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
  AppTheme themeMode;

  @HiveField(12)
  int customColorValue;

  @HiveField(13)
  double colorIntensity;

  @HiveField(14)
  double noiseLevel;

  @HiveField(15)
  bool useGradient;

  @HiveField(16)
  int? secondaryColorValue;

  @HiveField(17)
  bool useDynamicColors;

  UserSettings({
    required this.name,
    required this.minSession,
    this.breakTime,
    this.mealBreaks = const [],
    this.sleepTime = const [],
    this.freeTime = const [],
    this.activeDays,
    this.defaultNotificationType = NotificationType.push,
    this.dateFormat = "DD-MM-YYYY",
    this.monthFormat = "numeric",
    this.is24HourFormat = true,
    this.themeMode = AppTheme.system,
    this.customColorValue = 0xFF0A84FF, // Default iOS blue
    this.colorIntensity = 1.0,
    this.noiseLevel = 0.0,
    this.useGradient = false,
    this.secondaryColorValue = 0xFF34C759, // Default iOS green
    this.useDynamicColors = false,
  }) {
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
