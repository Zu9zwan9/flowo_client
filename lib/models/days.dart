import 'package:flowo_client/models/scheduled_task.dart';
import 'package:hive/hive.dart';

part 'days.g.dart';

@HiveType(typeId: 4) // Unique ID for the Days class
class Days extends HiveObject {
  @HiveField(0)
  String day;

  @HiveField(1)
  List<ScheduledTask> scheduledTasks;

  // Constructor
  Days({required this.day, required this.scheduledTasks});
}
