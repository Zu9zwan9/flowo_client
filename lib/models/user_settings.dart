import 'package:hive/hive.dart';

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
