import 'package:hive/hive.dart';

import 'time_frame.dart';

part 'day_schedule.g.dart';

/// Represents a schedule for a specific day of the week
@HiveType(typeId: 22)
class DaySchedule {
  /// The day of the week (Monday, Tuesday, etc.)
  @HiveField(0)
  final String day;

  /// Whether this day is active (tasks can be scheduled on this day)
  @HiveField(1)
  bool isActive;

  /// Sleep time for this day
  @HiveField(2)
  TimeFrame sleepTime;

  /// Meal breaks for this day
  @HiveField(3)
  List<TimeFrame> mealBreaks;

  /// Free time periods for this day
  @HiveField(4)
  List<TimeFrame> freeTimes;

  DaySchedule({
    required this.day,
    this.isActive = true,
    required this.sleepTime,
    List<TimeFrame>? mealBreaks,
    List<TimeFrame>? freeTimes,
  }) : mealBreaks = mealBreaks ?? [],
       freeTimes = freeTimes ?? [];
}
