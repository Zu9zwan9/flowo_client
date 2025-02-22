import 'package:flowo_client/models/scheduled_task.dart';
import 'package:hive/hive.dart';

part 'day.g.dart';

@HiveType(typeId: 4) // Unique ID for the Days class
class Day extends HiveObject {

  @HiveField(0)
  String day;

  @HiveField(1)
  List<ScheduledTask> scheduledTasks;

  // Constructor
  Day({
    required this.day,
  }) : scheduledTasks = [];
}
