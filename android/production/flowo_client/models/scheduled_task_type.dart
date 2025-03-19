import 'package:hive/hive.dart';

part 'scheduled_task_type.g.dart';

@HiveType(typeId: 6) // Unique ID for the ScheduledTaskType enum
enum ScheduledTaskType {
  @HiveField(0)
  defaultType,
  @HiveField(1)
  timeSensitive,
  @HiveField(2)
  rest,
  @HiveField(3)
  mealBreak,
  @HiveField(4)
  sleep,
}
