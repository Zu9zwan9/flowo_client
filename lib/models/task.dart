// lib/models/task.dart

import 'package:flowo_client/models/scheduled_task.dart';
import 'package:hive/hive.dart';
import 'category.dart';
import 'coordinates.dart';
import 'days.dart';
import 'repeat_rule.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  int priority;

  @HiveField(2)
  int deadline;

  @HiveField(3)
  int estimatedTime;

  @HiveField(4)
  Category category;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  Coordinates? location;

  @HiveField(7)
  String? image;

  @HiveField(8)
  List<Days>? frequency;

  @HiveField(9)
  List<Task> subtasks;

  @HiveField(10)
  List<ScheduledTask> scheduledTask;

  @HiveField(11)
  bool isDone;

  @HiveField(12)
  int order;

  @HiveField(13)
  bool overdue;

  // Add the missing getters
  DateTime get startDate => DateTime.now(); // Example getter
  DateTime get endDate =>
      DateTime.now().add(Duration(days: 1)); // Example getter
  RepeatRule get repeatRule =>
      RepeatRule(frequency: 'daily', interval: 1); // Example getter
  List<DateTime> get exceptions => []; // Example getter

  Task({
    required this.title,
    required this.priority,
    required this.deadline,
    required this.estimatedTime,
    required this.category,
    this.notes,
    this.location,
    this.image,
    this.frequency,
    this.subtasks = const [],
    this.scheduledTask = const [],
    this.isDone = false,
    this.order = 0,
    this.overdue = false
  });
}
