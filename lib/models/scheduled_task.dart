import 'package:hive/hive.dart';

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
  List<int> notificationIds;

  Task? get parentTask =>
      Hive.box<Task>('tasks').get(parentTaskId); // Avoid null check operator

  void addNotificationId(notificationId) {
    if (!notificationIds.contains(notificationId)) {
      notificationIds.add(notificationId);
    }
  }

  @override
  String toString() {
    return 'ScheduledTask{scheduledTaskId: $scheduledTaskId,'
        ' parentTaskId: $parentTaskId, startTime: $startTime,'
        ' endTime: $endTime, urgency: $urgency,'
        ' type: $type, travelingTime: $travelingTime'
        ', notificationIds: $notificationIds}';
  }

  ScheduledTask({
    required this.scheduledTaskId,
    required this.parentTaskId,
    required this.startTime,
    required this.endTime,
    this.urgency,
    required this.type,
    required this.travelingTime,
    List<int>? notificationIds,
  }) : notificationIds = notificationIds ?? [];
}
