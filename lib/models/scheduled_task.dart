import 'package:flowo_client/models/scheduled_task_type.dart';
import 'package:hive/hive.dart';

import 'notification_type.dart';
import 'task.dart';

part 'scheduled_task.g.dart';

@HiveType(typeId: 5) // Unique ID for the ScheduledTask class
class ScheduledTask extends HiveObject {
  // Attributes
  @HiveField(0)
  Task parentTask;

  @HiveField(1)
  DateTime startTime;

  @HiveField(2)
  DateTime endTime;

  @HiveField(3)
  double? urgency;

  @HiveField(4)
  ScheduledTaskType type;

  @HiveField(5)
  int travelingTime; // In milliseconds

  @HiveField(6)
  int breakTime; // In milliseconds

  @HiveField(7)
  NotificationType notification;

  // Constructor
  ScheduledTask({
    required this.parentTask,
    required this.startTime,
    required this.endTime,
    this.urgency,
    required this.type,
    required this.travelingTime,
    required this.breakTime,
    required this.notification,
  });
}
