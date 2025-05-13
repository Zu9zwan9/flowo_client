import 'package:hive/hive.dart';

import 'category.dart';
import 'coordinates.dart';
import 'repeat_rule.dart';
import 'scheduled_task.dart';
import 'task_session.dart';

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
  List<String> subtaskIds;

  @HiveField(11)
  String? parentTaskId;

  @HiveField(12)
  List<ScheduledTask> scheduledTasks;

  @HiveField(13)
  bool isDone;

  @HiveField(14)
  int? order;

  @HiveField(15)
  bool overdue;

  @HiveField(16)
  int? color;

  @HiveField(20)
  int? firstNotification; //time in minutes before scheduled task

  @HiveField(21)
  int? secondNotification;

  /// Task execution status
  @HiveField(22)
  String status = 'not_started'; // not_started, in_progress, paused, completed

  /// Total duration spent on this task in milliseconds
  @HiveField(23)
  int totalDuration = 0;

  /// List of sessions for this task
  @HiveField(24)
  List<TaskSession> sessions = [];

  /// Current active session (null if no active session)
  TaskSession? get activeSession {
    if (sessions.isEmpty) return null;
    for (var session in sessions) {
      if (session.isActive) return session;
    }
    return null;
  }

  /// Whether the task is currently in progress
  bool get isInProgress => status == 'in_progress';

  /// Whether the task is currently paused
  bool get isPaused => status == 'paused';

  /// Whether the task can be started (either it has no subtasks or all subtasks are completed)
  bool get canStart => subtaskIds.isEmpty;
  // subtasks.isEmpty || subtasks.every((subtask) => subtask.isDone);

  Task? get parentTask =>
      parentTaskId != null ? Hive.box<Task>('tasks').get(parentTaskId) : null;

  set parentTask(Task? value) {
    parentTaskId = value?.id;
  }

  DateTime get startDate => DateTime.now();

  DateTime get endDate => DateTime.now().add(Duration(days: 1));

  List<DateTime> get exceptions => [];

  @override
  String toString() {
    return 'Task: {id: $id, title: $title, priority: $priority, '
        'deadline: $deadline, estimatedTime: $estimatedTime, category: $category, '
        'optimisticTime: $optimisticTime, realisticTime: $realisticTime, pessimisticTime: $pessimisticTime, '
        'notes: $notes, location: $location, image: $image, frequency: ${frequency.toString()}, '
        'subtasks: $subtaskIds, parentTaskId: $parentTaskId, scheduledTasks: $scheduledTasks, '
        'isDone: $isDone, order: $order, overdue: $overdue, color: $color}';
  }

  /// Starts the task
  /// Creates a new session and updates the task status
  void start() {
    if (isDone) return; // Can't start a completed task

    // If there's an active session, end it first
    final currentSession = activeSession;
    if (currentSession != null) {
      currentSession.end();
    }

    // Create a new session
    final session = TaskSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskId: id,
      startTime: DateTime.now(),
    );
    sessions.add(session);

    // Update status
    status = 'in_progress';
    save();
  }

  /// Pauses the task
  /// Ends the current session and updates the task status
  void pause() {
    if (!isInProgress) return; // Can only pause a task that's in progress

    // End the current session
    final currentSession = activeSession;
    if (currentSession != null) {
      currentSession.end();
      totalDuration += currentSession.duration;
    }

    // Update status
    status = 'paused';
    save();
  }

  /// Stops the task
  /// Ends the current session and updates the task status
  void stop() {
    if (!isInProgress && !isPaused) {
      return; // Can only stop a task that's in progress or paused
    }

    // End the current session if in progress
    final currentSession = activeSession;
    if (currentSession != null) {
      currentSession.end();
      totalDuration += currentSession.duration;
    }

    // Update status
    status = 'not_started';
    save();
  }

  /// Completes the task
  /// Ends the current session, updates the task status, and marks the task as done
  void complete() {
    // End the current session if in progress
    final currentSession = activeSession;
    if (currentSession != null) {
      currentSession.end();
      totalDuration += currentSession.duration;
    }

    // Update status
    status = 'completed';
    isDone = true;
    save();
  }

  /// Gets the total duration of all sessions for this task
  int getTotalDuration() {
    int total = totalDuration;

    // Add duration of active session if there is one
    final currentSession = activeSession;
    if (currentSession != null) {
      total += currentSession.duration;
    }

    return total;
  }

  /// Calculates the time efficiency ratio for this task
  ///
  /// This ratio represents how well the estimated time matches the actual time spent.
  /// A ratio of 1.0 means the task took exactly as long as estimated.
  /// A ratio less than 1.0 means the task took longer than estimated.
  /// A ratio greater than 1.0 means the task took less time than estimated.
  ///
  /// Returns null if the task has no estimated time or has not been worked on.
  double? getTimeEfficiencyRatio() {
    if (estimatedTime <= 0) return null;

    final actualDuration = getTotalDuration();
    if (actualDuration <= 0) return null;

    return estimatedTime / actualDuration;
  }

  /// Gets a human-readable description of the time efficiency
  String getTimeEfficiencyDescription() {
    final ratio = getTimeEfficiencyRatio();
    if (ratio == null) return 'No data';

    if (ratio >= 0.9 && ratio <= 1.1) {
      return 'Excellent estimation';
    } else if (ratio >= 0.7 && ratio < 0.9) {
      return 'Good estimation';
    } else if (ratio > 1.1 && ratio <= 1.5) {
      return 'Faster than estimated';
    } else if (ratio > 1.5) {
      return 'Much faster than estimated';
    } else if (ratio >= 0.5 && ratio < 0.7) {
      return 'Slower than estimated';
    } else {
      return 'Much slower than estimated';
    }
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
    List<String>? subtaskIds,
    List<ScheduledTask>? scheduledTasks,
    this.isDone = false,
    this.order,
    this.overdue = false,
    this.color,
    this.optimisticTime,
    this.realisticTime,
    this.pessimisticTime,
    this.firstNotification,
    this.secondNotification,
    this.status = 'not_started',
    this.totalDuration = 0,
    List<TaskSession>? sessions,
  }) : parentTaskId = parentTask?.id,
       subtaskIds = subtaskIds ?? [],
       scheduledTasks = scheduledTasks ?? [],
       sessions = sessions ?? [];
}
