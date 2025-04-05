import 'package:hive/hive.dart';
import 'notification_type.dart';
import 'scheduled_task_type.dart';
import 'task.dart';

part 'scheduled_task.g.dart';

@HiveType(typeId: 5)
class ScheduledTask extends HiveObject {
  @HiveField(0)
  String scheduledTaskId;

  @HiveField(1)
  String parentTaskId;

  @HiveField(2)
  DateTime startTime;

  @HiveField(3)
  DateTime endTime;

  @HiveField(4)
  double? urgency;

  @HiveField(5)
  ScheduledTaskType type;

  @HiveField(6)
  int travelingTime;

  @HiveField(7)
  int breakTime;

  @HiveField(8)
  NotificationType notification;

  Task? get parentTask =>
      Hive.box<Task>('tasks').get(parentTaskId); // Avoid null check operator

  ScheduledTask({
    required this.scheduledTaskId,
    required this.parentTaskId,
    required this.startTime,
    required this.endTime,
    this.urgency,
    required this.type,
    required this.travelingTime,
    required this.breakTime,
    required this.notification,
  });
}
