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
  List<TimeFrame> mealBreaks;

  @HiveField(3)
  List<TimeFrame> sleepTime;

  @HiveField(4)
  List<TimeFrame> freeTime;

  @HiveField(5)
  Map<String, bool>? activeDays;

  /// Day-specific schedules
  @HiveField(6)
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

  @HiveField(18)
  double? textSizeAdjustment;

  @HiveField(19)
  bool? reduceMotion;

  @HiveField(20)
  bool? highContrastMode;

  @HiveField(21)
  String? gradientStartAlignment;

  @HiveField(22)
  String? gradientEndAlignment;

  @HiveField(23)
  bool usePertMethod = true;

  @HiveField(24) // Use the next available HiveField index
  List<DaySchedule> schedules = [];

  // And update the constructor:
  UserSettings({
    required this.name,
    required this.minSession,
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
    this.textSizeAdjustment = 0.0,
    this.reduceMotion = false,
    this.highContrastMode = false,
    this.gradientStartAlignment = "topLeft",
    this.gradientEndAlignment = "bottomRight",
    this.usePertMethod = true,
    List<DaySchedule>? schedules,
  }) : daySchedules = daySchedules ?? {},
       schedules = schedules ?? [] {
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

  // Add a copyWith method
  UserSettings copyWith({
    String? name,
    int? minSession,
    List<TimeFrame>? mealBreaks,
    List<TimeFrame>? sleepTime,
    List<TimeFrame>? freeTime,
    Map<String, bool>? activeDays,
    Map<String, DaySchedule>? daySchedules,
    NotificationType? defaultNotificationType,
    String? dateFormat,
    String? monthFormat,
    bool? is24HourFormat,
    AppTheme? themeMode,
    int? customColorValue,
    double? colorIntensity,
    double? noiseLevel,
    bool? useGradient,
    int? secondaryColorValue,
    bool? useDynamicColors,
    double? textSizeAdjustment,
    bool? reduceMotion,
    bool? highContrastMode,
    String? gradientStartAlignment,
    String? gradientEndAlignment,
    bool? usePertMethod,
    List<DaySchedule>? schedules,
  }) {
    return UserSettings(
      name: name ?? this.name,
      minSession: minSession ?? this.minSession,
      mealBreaks: mealBreaks ?? this.mealBreaks,
      sleepTime: sleepTime ?? this.sleepTime,
      freeTime: freeTime ?? this.freeTime,
      activeDays: activeDays ?? this.activeDays,
      daySchedules: daySchedules ?? this.daySchedules,
      defaultNotificationType:
          defaultNotificationType ?? this.defaultNotificationType,
      dateFormat: dateFormat ?? this.dateFormat,
      monthFormat: monthFormat ?? this.monthFormat,
      is24HourFormat: is24HourFormat ?? this.is24HourFormat,
      themeMode: themeMode ?? this.themeMode,
      customColorValue: customColorValue ?? this.customColorValue,
      colorIntensity: colorIntensity ?? this.colorIntensity,
      noiseLevel: noiseLevel ?? this.noiseLevel,
      useGradient: useGradient ?? this.useGradient,
      secondaryColorValue: secondaryColorValue ?? this.secondaryColorValue,
      useDynamicColors: useDynamicColors ?? this.useDynamicColors,
      textSizeAdjustment: textSizeAdjustment ?? this.textSizeAdjustment,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      highContrastMode: highContrastMode ?? this.highContrastMode,
      gradientStartAlignment:
          gradientStartAlignment ?? this.gradientStartAlignment,
      gradientEndAlignment: gradientEndAlignment ?? this.gradientEndAlignment,
      usePertMethod: usePertMethod ?? this.usePertMethod,
      schedules: schedules ?? this.schedules,
    );
  }
}
