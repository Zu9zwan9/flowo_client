import 'package:hive/hive.dart';

part 'scheduled_task_type.g.dart';

@HiveType(typeId: 6)
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
  @HiveField(5)
  work,
  @HiveField(6)
  freeTime,
}
