import 'package:flowo_client/models/scheduled_task.dart';
import 'package:hive/hive.dart';
part 'day.g.dart';

@HiveType(typeId: 4) // Unique ID for the Days class
class Day extends HiveObject {
  @HiveField(0)
  String day;

  @HiveField(1)
  List<ScheduledTask> scheduledTasks;

  Day({
    required this.day,
    List<ScheduledTask>? scheduledTasks, // Optional named parameter
  }) : scheduledTasks = scheduledTasks ?? []; // Default to empty list

  @override
  String toString() => 'Day(day: $day, scheduledTasks: ${scheduledTasks.length})';
}
