import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'app_theme.dart';
import 'day_schedule.dart';
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

  /// Day-specific schedules
  @HiveField(18)
  Map<String, DaySchedule> daySchedules;

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
    Map<String, DaySchedule>? daySchedules,
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
  }) : daySchedules = daySchedules ?? {} {
    activeDays ??= {
      'Monday': true,
      'Tuesday': true,
      'Wednesday': true,
      'Thursday': true,
      'Friday': true,
      'Saturday': true,
      'Sunday': true,
    };

    // Initialize day schedules if empty
    if (this.daySchedules.isEmpty) {
      _initializeDefaultDaySchedules();
    }
  }

  /// Initializes default day schedules based on the existing settings
  void _initializeDefaultDaySchedules() {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    // Default sleep time (use the first one from sleepTime list or create a default)
    final defaultSleepTime =
        sleepTime.isNotEmpty
            ? sleepTime.first
            : TimeFrame(
              startTime: const TimeOfDay(hour: 22, minute: 0),
              endTime: const TimeOfDay(hour: 7, minute: 0),
            );

    // Create a schedule for each day
    for (final day in days) {
      daySchedules[day] = DaySchedule(
        day: day,
        isActive: activeDays?[day] ?? true,
        sleepTime: defaultSleepTime,
        mealBreaks: List.from(mealBreaks),
        freeTimes: List.from(freeTime),
      );
    }
  }
}
