import 'package:bloc/bloc.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../models/category.dart';
import '../../models/coordinates.dart';
import '../../models/day.dart';
import '../../models/notification_type.dart';
import '../../models/repeat_rule.dart';
import '../../models/scheduled_task_type.dart';
import '../../models/task.dart';
import '../../models/user_settings.dart';
import '../../utils/task_manager.dart';
import 'task_manager_state.dart';

class TaskManagerCubit extends Cubit<TaskManagerState> {
  final TaskManager taskManager;

  TaskManagerCubit(this.taskManager) : super(TaskManagerState.initial()) {
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  void createTask({
    required String title,
    required int priority,
    required int estimatedTime,
    required int deadline,
    required Category category,
    Task? parentTask,
    String? notes,
    int? color,
    RepeatRule? frequency,
  }) {
    taskManager.createTask(
        title, priority, estimatedTime, deadline, category, parentTask, notes,
        color: color, frequency: frequency);
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  void createEvent({
    required String title,
    required DateTime start,
    required DateTime end,
    String? location,
    String? notes,
    int? color,
    int? travelingTime,
  }) {
    logInfo('Creating event: title - $title, start - $start, end - $end');

    // Calculate estimated time in milliseconds
    final estimatedTime = end.difference(start).inMilliseconds;

    // Always use the 'Event' category for events
    final category = Category(name: 'Event');

    // Create the task with required fields
    final task = Task(
      id: UniqueKey().toString(),
      title: title,
      priority: 0, // Not required, set to default
      estimatedTime: estimatedTime,
      deadline: end.millisecondsSinceEpoch, // Use end time as deadline
      category: category,
      notes: notes,
      color: color,
      location: location != null && location.isNotEmpty
          ? Coordinates(
              latitude: 1.0, longitude: 1.0) // Placeholder coordinates
          : null,
    );

    // Save the task
    taskManager.tasksDB.put(task.id, task);

    // Create the scheduled task
    final scheduledTask = ScheduledTask(
      scheduledTaskId: UniqueKey().toString(),
      parentTaskId: task.id,
      startTime: start,
      endTime: end,
      urgency: null, // Not required
      type: ScheduledTaskType.timeSensitive,
      travelingTime: travelingTime ??
          (location != null && location.isNotEmpty
              ? 15 *
                  60 *
                  1000 // Default 15 minutes in milliseconds if location is provided
              : 0),
      breakTime: taskManager.userSettings.breakTime ??
          5 * 60 * 1000, // From user settings
      notification: NotificationType.none,
    );

    // Add the scheduled task to the task
    task.scheduledTasks.add(scheduledTask);
    taskManager.tasksDB.put(task.id, task);

    // Add the scheduled task to the day
    final dateKey = _formatDateKey(start);
    final day = taskManager.daysDB.get(dateKey) ?? Day(day: dateKey);
    day.scheduledTasks.add(scheduledTask);
    taskManager.daysDB.put(dateKey, day);

    // Update the state
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
    logInfo('Event created successfully: $task.title');
  }

  List<ScheduledTask> getScheduledTasks() {
    final scheduledTasks = <ScheduledTask>[];
    for (var day in taskManager.daysDB.values) {
      scheduledTasks.addAll(day.scheduledTasks);
    }
    return scheduledTasks;
  }

  Future<List<TaskWithSchedules>> getScheduledTasksForDate(
      DateTime date) async {
    final dateKey = _formatDateKey(date);

    final scheduledTasks = taskManager.daysDB.values
        .where((day) => day.day == dateKey)
        .expand((day) => day.scheduledTasks);

    final grouped = <Task, List<ScheduledTask>>{};
    for (var scheduledTask in scheduledTasks) {
      final task = taskManager.tasksDB.get(scheduledTask.parentTaskId);
      if (task != null) {
        grouped.putIfAbsent(task, () => []).add(scheduledTask);
      }
    }

    final result = grouped.entries
        .map((entry) => TaskWithSchedules(entry.key, entry.value))
        .toList();

    return result;
  }

  String _formatDateKey(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  void deleteTask(Task task) {
    taskManager.deleteTask(task);
    emit(state.copyWith(
        tasks: taskManager.tasksDB.values
            .toList())); // Refresh state after deletion
  }

  void editTask({
    required Task task,
    required String title,
    required int priority,
    required int estimatedTime,
    required int deadline,
    required Category category,
    Task? parentTask,
    String? notes,
    int? color,
    RepeatRule? frequency,
  }) {
    // Update task properties
    taskManager.editTask(
        task, title, priority, estimatedTime, deadline, category, parentTask,
        notes: notes, color: color, frequency: frequency);

    // No need to update notes, color, and frequency separately as they're now part of the TaskManager.editTask method
    taskManager.tasksDB.put(task.id, task);

    // Recalculate scheduling after edit
    taskManager.removeScheduledTasks();
    taskManager.scheduleTasks();

    // Update state
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  void scheduleTasks() {
    taskManager.scheduleTasks();
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  void scheduleTask(Task task) {
    final minSession = state.userSettings?.minSession ?? 15 * 60 * 1000;
    taskManager.scheduler.scheduleTask(task, minSession);
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  void removeScheduledTasks() {
    taskManager.removeScheduledTasks();
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  void updateUserSettings(UserSettings userSettings) {
    taskManager.updateUserSettings(userSettings);
    try {
      final settingsBox = Hive.box<UserSettings>('user_settings');
      settingsBox.put('current', userSettings);
      logInfo('User settings updated and saved');
    } catch (e) {
      logError('Failed to save user settings: $e');
    }
    _deleteAllDays();
    // removeScheduledTasks();
    scheduleTasks();
    emit(state.copyWith(
        tasks: taskManager.tasksDB.values.toList(),
        userSettings: userSettings));
  }

  void _deleteAllDays() {
    final existingDayKeys = taskManager.daysDB.keys.cast<String>().toList();
    for (var dateKey in existingDayKeys) {
      taskManager.daysDB.delete(dateKey);
      logDebug('Deleted day: $dateKey');
    }
    logInfo('All days deleted');
  }

  /// Breaks down a task into subtasks using AI and schedules them
  ///
  /// Returns a list of the created subtasks
  Future<List<Task>> breakdownAndScheduleTask(Task task) async {
    logInfo('Breaking down task using AI: ${task.title}');
    final subtasks = await taskManager.breakdownAndScheduleTask(task);
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
    return subtasks;
  }
}

class TaskWithSchedules {
  final Task task;
  final List<ScheduledTask> scheduledTasks;

  TaskWithSchedules(this.task, this.scheduledTasks);
}
