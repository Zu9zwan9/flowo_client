import 'package:bloc/bloc.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

import '../../models/category.dart';
import '../../models/day.dart';
import '../../models/repeat_rule.dart';
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
    int? optimisticTime,
    int? realisticTime,
    int? pessimisticTime,
    int? firstNotification,
    int? secondNotification,
  }) {
    final task = taskManager.createTask(
      title,
      priority,
      estimatedTime,
      deadline,
      category,
      parentTask: parentTask,
      notes: notes,
      color: color,
      frequency: frequency,
      optimisticTime: optimisticTime,
      realisticTime: realisticTime,
      pessimisticTime: pessimisticTime,
      firstNotification: firstNotification,
      secondNotification: secondNotification,
    );

    // Save the task with notification settings
    taskManager.tasksDB.put(task.id, task);

    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  Future<bool> createEvent({
    required String title,
    required DateTime start,
    required DateTime end,
    required BuildContext context,
    String? location,
    String? notes,
    int? color,
    int? travelingTime,
    int? firstNotification,
    int? secondNotification,
  }) async {
    logInfo('Creating event: title - $title, start - $start, end - $end');

    final priority = 0; // Not required, set to default
    final estimatedTime = end.difference(start).inMilliseconds;
    final deadline = end.millisecondsSinceEpoch; // Use end time as deadline
    final category = Category(
      name: 'Event',
    ); // Always use the 'Event' category for events

    final task = taskManager.createTask(
      title,
      priority,
      estimatedTime,
      deadline,
      category,
      notes: notes,
      color: color,
      firstNotification: firstNotification,
      secondNotification: secondNotification,
    );

    // Schedule the event with conflict resolution
    final success = await taskManager.scheduler.scheduleEvent(
      task: task,
      start: start,
      end: end,
      context: context,
    );

    if (!success) {
      // If scheduling failed (user canceled or chose to adjust), delete the task
      taskManager.deleteTask(task);
      logInfo('Event creation canceled due to conflicts: $title');
      return false;
    }

    // Update the state
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
    logInfo('Event created successfully: ${task.title}');
    return true;
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

    logInfo(
      'For date $dateKey, found ${scheduledTasks.length} scheduled tasks',
    );

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
    int? optimisticTime,
    int? realisticTime,
    int? pessimisticTime,
    int? firstNotification,
    int? secondNotification,
    BuildContext? context,
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
      optimisticTime: optimisticTime,
      realisticTime: realisticTime,
      pessimisticTime: pessimisticTime,
      firstNotification: firstNotification,
      secondNotification: secondNotification,
    );

    taskManager.tasksDB.put(task.id, task);

    // Recalculate scheduling after edit
    taskManager.removeScheduledTasksFor(task);

    // If context is provided and the task is a habit, schedule it with conflict resolution
    if (context != null && frequency != null) {
      scheduleHabits(context);
    } else if (frequency != null) {
      // Log a warning if context is not provided for a habit
      logWarning(
        'Cannot schedule habit without BuildContext. Habit scheduling skipped.',
      );
    }

    // Update state
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  Future<bool> editEvent({
    required Task task,
    required String title,
    required DateTime start,
    required DateTime end,
    required BuildContext context,
    String? location,
    String? notes,
    int? color,
    int? travelingTime,
    int? firstNotification,
    int? secondNotification,
  }) async {
    logInfo(
      'Editing event: ${task.title} to new title - $title, start - $start, end - $end',
    );

    if (task.scheduledTasks.isNotEmpty) {
      final scheduledTask = task.scheduledTasks.first;
      final dateKey = _formatDateKey(scheduledTask.startTime);
      final daysBox = Hive.box<Day>('scheduled_tasks');
      final day = daysBox.get(dateKey);

      if (day != null) {
        day.scheduledTasks.removeWhere(
          (st) => st.scheduledTaskId == scheduledTask.scheduledTaskId,
        );
        if (day.scheduledTasks.isEmpty) {
          daysBox.delete(dateKey);
        } else {
          daysBox.put(dateKey, day);
        }
        logInfo('Removed previous scheduled task for event: ${task.title}');
      }
      task.scheduledTasks.clear();
    }

    final estimatedTime = end.difference(start).inMilliseconds;
    final deadline = end.millisecondsSinceEpoch;

    taskManager.editTask(
      task,
      title,
      0,
      estimatedTime,
      deadline,
      task.category,
      null,
      notes: notes,
      color: color,
      firstNotification: firstNotification,
      secondNotification: secondNotification,
    );

    // Schedule the event with conflict resolution
    final success = await taskManager.scheduler.scheduleEvent(
      task: task,
      start: start,
      end: end,
      context: context,
    );

    if (!success) {
      // If scheduling failed (user canceled or chose to adjust), revert the task changes
      logInfo('Event update canceled due to conflicts: $title');
      return false;
    }

    taskManager.tasksDB.put(task.id, task);

    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
    logInfo('Event updated successfully: ${task.title}');
    return true;
  }

  void scheduleTasks() {
    taskManager.scheduleTasks();
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  // This method now requires a BuildContext for conflict resolution
  Future<void> scheduleHabits(BuildContext context) async {
    logDebug('Scheduling habits');

    // Since we can't modify the TaskManager.manageHabits method directly,
    // we'll handle the scheduling of habits here
    List<Task> habits =
        taskManager.tasksDB.values
            .where((task) => task.frequency != null)
            .toList();

    for (Task habit in habits) {
      switch (habit.frequency!.type) {
        case 'weekly':
          final repeatRule = habit.frequency!;
          final byDay = repeatRule.byDay!;

          for (var dayInstance in byDay) {
            final selectedWeekday = _dayNameToInt(dayInstance.selectedDay);
            final startDate = repeatRule.startRepeat;
            final daysUntilNextSelectedDay =
                (selectedWeekday - startDate.weekday + 7) % 7;

            var nextSelectedDate = startDate.add(
              Duration(days: daysUntilNextSelectedDay),
            );

            List<DateTime> habitDates = [];

            while (nextSelectedDate.isBefore(repeatRule.endRepeat!)) {
              habitDates.add(nextSelectedDate);
              nextSelectedDate = nextSelectedDate.add(
                Duration(days: 7 * habit.frequency!.interval),
              );
            }

            await taskManager.scheduler.scheduleHabit(
              task: habit,
              dates: habitDates,
              start: dayInstance.start,
              end: dayInstance.end,
              context: context,
            );
          }
          break;

        // Handle other frequency types similarly
        // For brevity, we'll just handle the weekly case in this example
        // In a real implementation, you would handle all cases
        default:
          logWarning(
            'Habit frequency type not handled in cubit: ${habit.frequency!.type}',
          );
          break;
      }
    }

    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  // Helper method to convert day names to integers
  int _dayNameToInt(String dayName) {
    const dayMap = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };
    return dayMap[dayName.toLowerCase()] ?? 1;
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
}

class TaskWithSchedules {
  final Task task;
  final List<ScheduledTask> scheduledTasks;

  TaskWithSchedules(this.task, this.scheduledTasks);
}
