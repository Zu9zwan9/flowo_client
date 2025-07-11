import 'package:hive/hive.dart';

import 'time_frame.dart';

part 'day_schedule.g.dart';

/// Represents a schedule for a specific day of the week
@HiveType(typeId: 22)
class DaySchedule {
  /// Schedule name
  @HiveField(0)
  String name;

  /// Day of the week (e.g., "Monday", "Tuesday")
  @HiveField(1)
  List<String> day;

  /// Whether this day is active (tasks can be scheduled on this day)
  @HiveField(2)
  bool isActive;

  /// Sleep time for this day
  @HiveField(3)
  TimeFrame sleepTime;

  /// Meal breaks for this day
  @HiveField(4)
  List<TimeFrame> mealBreaks;

  /// Free time periods for this day
  @HiveField(5)
  List<TimeFrame> freeTimes;

  DaySchedule copyWith({
    List<String>? day,
    bool? isActive,
    TimeFrame? sleepTime,
    List<TimeFrame>? mealBreaks,
    List<TimeFrame>? freeTimes,
    String? name,
  }) {
    return DaySchedule(
      name: name ?? this.name,
      day: day ?? this.day,
      isActive: isActive ?? this.isActive,
      sleepTime: sleepTime ?? this.sleepTime,
      mealBreaks: mealBreaks ?? this.mealBreaks,
      freeTimes: freeTimes ?? this.freeTimes,
    );
  }

  DaySchedule({
    required this.name,
    required this.day,
    this.isActive = true,
    required this.sleepTime,
    List<TimeFrame>? mealBreaks,
    List<TimeFrame>? freeTimes,
  }) : mealBreaks = mealBreaks ?? [],
       freeTimes = freeTimes ?? [];
}
