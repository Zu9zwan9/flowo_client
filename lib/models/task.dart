// lib/models/task.dart

import 'package:flowo_client/models/scheduled_task.dart';
import 'package:hive/hive.dart';
import 'category.dart';
import 'coordinates.dart';
import 'day.dart';
import 'repeat_rule.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  int priority;

  @HiveField(3)
  int deadline;

  @HiveField(4)
  int estimatedTime;

  @HiveField(5)
  Category category;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  Coordinates? location;

  @HiveField(8)
  String? image;

  @HiveField(9)
  List<Day>? frequency;

  @HiveField(10)
  List<Task> subtasks;

  @HiveField(11)
  Task? parentTask;

  @HiveField(12)
  List<ScheduledTask> scheduledTasks;

  @HiveField(13)
  bool isDone;

  @HiveField(14)
  int? order;

  @HiveField(15)
  bool overdue;

  // Add the missing getters
  DateTime get startDate => DateTime.now(); // Example getter
  DateTime get endDate =>
      DateTime.now().add(Duration(days: 1)); // Example getter
  RepeatRule get repeatRule =>
      RepeatRule(frequency: 'daily', interval: 1); // Example getter
  List<DateTime> get exceptions => []; // Example getter

  Task(
      {required this.id,
      required this.title,
      required this.priority,
      required this.deadline,
      required this.estimatedTime,
      required this.category,
      this.parentTask,
      this.notes,
      this.location,
      this.image,
      this.frequency,
      this.subtasks = const [],
      this.scheduledTasks = const [],
      this.isDone = false,
      this.order, // 1,2,3 - is order of subtask, if 0 - order is not important
      this.overdue = false});
}
