import 'package:flowo_client/models/scheduled_task_type.dart';
import 'package:hive/hive.dart';

import 'notification_type.dart';
import 'task.dart';

part 'scheduled_task.g.dart';

@HiveType(typeId: 5) // Unique ID for the ScheduledTask class
class ScheduledTask extends HiveObject {
  // Attributes
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
  int travelingTime; // In milliseconds

  @HiveField(7)
  int breakTime; // In milliseconds

  @HiveField(8)
  NotificationType notification;

  // Add the parentTask property
  Task get parentTask => Hive.box<Task>('tasks').get(parentTaskId)!;

  // Constructor
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
