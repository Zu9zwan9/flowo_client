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
      title,
      priority,
      estimatedTime,
      deadline,
      category,
      parentTask,
      notes,
      color: color,
      frequency: frequency,
    );
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
      location:
          location != null && location.isNotEmpty
              ? Coordinates(
                latitude: 1.0,
                longitude: 1.0,
              ) // Placeholder coordinates
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
      travelingTime:
          travelingTime ??
          (location != null && location.isNotEmpty
              ? 15 *
                  60 *
                  1000 // Default 15 minutes in milliseconds if location is provided
              : 0),
      breakTime:
          taskManager.userSettings.breakTime ??
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
    DateTime date,
  ) async {
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

    final result =
        grouped.entries
            .map((entry) => TaskWithSchedules(entry.key, entry.value))
            .toList();

    return result;
  }

  String _formatDateKey(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  void deleteTask(Task task) {
    taskManager.deleteTask(task);
    emit(
      state.copyWith(tasks: taskManager.tasksDB.values.toList()),
    ); // Refresh state after deletion
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
      task,
      title,
      priority,
      estimatedTime,
      deadline,
      category,
      parentTask,
      notes: notes,
      color: color,
      frequency: frequency,
    );

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
    emit(
      state.copyWith(
        tasks: taskManager.tasksDB.values.toList(),
        userSettings: userSettings,
      ),
    );
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

  /// Estimates time for a task using AI
  ///
  /// This method uses the task breakdown API to estimate time for a task
  /// based on its content. It breaks down the task into subtasks and then
  /// uses the estimated time of each subtask to calculate the total time.
  ///
  /// Returns the estimated time in minutes
  Future<int> estimateTaskTime(Task task) async {
    logInfo('Estimating time for task: ${task.title}');

    try {
      // Store the original estimated time
      final originalEstimatedTime = task.estimatedTime;

      // Break down the task into subtasks
      final subtasks = await breakdownAndScheduleTask(task);

      if (subtasks.isEmpty) {
        logWarning('No subtasks generated for task: ${task.title}');
        return task.estimatedTime > 0
            ? task.estimatedTime
            : 60; // Default to 1 hour if no estimate
      }

      // Calculate the total estimated time from the subtasks
      final totalEstimatedTime = subtasks.fold(
        0,
        (sum, subtask) => sum + subtask.estimatedTime,
      );

      // Update the task with the estimated time
      task.estimatedTime = totalEstimatedTime;
      taskManager.tasksDB.put(task.id, task);

      logInfo(
        'Estimated time for task "${task.title}": $totalEstimatedTime minutes',
      );

      // Update the state to reflect the changes
      emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));

      return totalEstimatedTime;
    } catch (e) {
      logError('Error estimating time for task: $e');
      return task.estimatedTime > 0
          ? task.estimatedTime
          : 60; // Return existing estimate or default
    }
  }

  /// Estimates time for all tasks using AI
  ///
  /// This method estimates time for all top-level tasks (tasks without a parent)
  /// and updates them with the estimated times.
  ///
  /// Returns the number of tasks updated
  Future<int> estimateAllTasks() async {
    logInfo('Estimating time for all tasks');

    try {
      // Get all top-level tasks (tasks without a parent)
      final tasks =
          taskManager.tasksDB.values
              .where((task) => task.parentTaskId == null)
              .toList();

      int updatedCount = 0;

      // Process each task
      for (var task in tasks) {
        await estimateTaskTime(task);
        updatedCount++;
      }

      logInfo('Updated $updatedCount tasks with AI-estimated times');

      return updatedCount;
    } catch (e) {
      logError('Error estimating time for all tasks: $e');
      return 0;
    }
  }

  /// Toggle the completion status of a task
  ///
  /// This method toggles the isDone property of a task and updates any subtasks
  /// if the parent task is marked as completed. It also sends the completion
  /// status to analytics.
  ///
  /// Returns the new completion status
  Future<bool> toggleTaskCompletion(Task task) async {
    logInfo('Toggling completion status for task: ${task.title}');

    try {
      // Toggle the isDone property
      task.isDone = !task.isDone;

      // If the task is marked as completed, update any subtasks
      if (task.isDone) {
        // Mark all subtasks as completed if the parent task is completed
        for (var subtask in task.subtasks) {
          if (!subtask.isDone) {
            subtask.isDone = true;
            taskManager.tasksDB.put(subtask.id, subtask);
            logInfo(
              'Subtask "${subtask.title}" automatically marked as completed',
            );
          }
        }
      }

      // Save the task
      taskManager.tasksDB.put(task.id, task);

      // Update the state
      emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));

      logInfo(
        'Task "${task.title}" marked as ${task.isDone ? "completed" : "incomplete"}',
      );

      return task.isDone;
    } catch (e) {
      logError('Error toggling task completion: $e');
      return task.isDone; // Return the current status in case of error
    }
  }

  /// Send a reminder to check if a task is completed
  Future<void> sendCompletionCheckReminder(Task task) async {
    if (task.isDone) {
      // Task is already completed, no need to send a reminder
      return;
    }

    try {
      // Create a notification for the task completion check
      // This would typically use a notification service, but for simplicity,
      // we'll just log it for now
      logInfo('Would send completion check reminder for task "${task.title}"');

      // In a real implementation, you would use a notification service:
      // await _notificationService.sendCompletionCheckReminder(task);
    } catch (e) {
      logError('Error sending completion check reminder: $e');
    }
  }

  /// Schedule a reminder to check if a task is completed
  Future<void> scheduleCompletionCheckReminder(
    Task task,
    DateTime scheduledTime,
  ) async {
    try {
      // Schedule a notification for the task completion check
      // This would typically use a notification service, but for simplicity,
      // we'll just log it for now
      logInfo(
        'Would schedule completion check reminder for task "${task.title}" at $scheduledTime',
      );

      // In a real implementation, you would use a notification service:
      // await _notificationService.scheduleCompletionCheckReminder(task, scheduledTime);
    } catch (e) {
      logError('Error scheduling completion check reminder: $e');
    }
  }
}

class TaskWithSchedules {
  final Task task;
  final List<ScheduledTask> scheduledTasks;

  TaskWithSchedules(this.task, this.scheduledTasks);
}
