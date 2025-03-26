import 'package:hive/hive.dart';

import 'category.dart';
import 'coordinates.dart';
import 'repeat_rule.dart';
import 'scheduled_task.dart';

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

  @HiveField(17)
  int? optimisticTime;

  @HiveField(18)
  int? realisticTime;

  @HiveField(19)
  int? pessimisticTime;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  Coordinates? location;

  @HiveField(8)
  String? image;

  @HiveField(9)
  RepeatRule? frequency;

  @HiveField(10)
  List<Task> subtasks;

  @HiveField(11)
  String? parentTaskId;

  Task? get parentTask =>
      parentTaskId != null ? Hive.box<Task>('tasks').get(parentTaskId) : null;

  set parentTask(Task? value) {
    parentTaskId = value?.id;
  }

  @HiveField(12)
  List<ScheduledTask> scheduledTasks; // Changed from const [] to mutable

  @HiveField(13)
  bool isDone;

  @HiveField(14)
  int? order;

  @HiveField(15)
  bool overdue;

  @HiveField(16)
  int? color;

  DateTime get startDate => DateTime.now();

  DateTime get endDate => DateTime.now().add(Duration(days: 1));

  List<DateTime> get exceptions => [];

  @override
  String toString() {
    return 'Task: {id: $id, title: $title, priority: $priority, '
        'deadline: $deadline, estimatedTime: $estimatedTime, category: $category, '
        'optimisticTime: $optimisticTime, realisticTime: $realisticTime, pessimisticTime: $pessimisticTime, '
        'notes: $notes, location: $location, image: $image, frequency: ${frequency.toString()}, '
        'subtasks: $subtasks, parentTaskId: $parentTaskId, scheduledTasks: $scheduledTasks, '
        'isDone: $isDone, order: $order, overdue: $overdue, color: $color}';
  }

  Task({
    required this.id,
    required this.title,
    required this.priority,
    required this.deadline,
    required this.estimatedTime,
    required this.category,
    Task? parentTask,
    this.notes,
    this.location,
    this.image,
    this.frequency,
    List<Task>? subtasks,
    List<ScheduledTask>? scheduledTasks,
    this.isDone = false,
    this.order,
    this.overdue = false,
    this.color,
    this.optimisticTime,
    this.realisticTime,
    this.pessimisticTime,
  }) : parentTaskId = parentTask?.id,
       subtasks = subtasks ?? [],
       scheduledTasks = scheduledTasks ?? [];
}
