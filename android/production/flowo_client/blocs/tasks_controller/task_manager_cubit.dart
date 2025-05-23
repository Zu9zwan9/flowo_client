import 'package:bloc/bloc.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:hive/hive.dart';

import '../../models/category.dart';
import '../../models/day.dart';
import '../../models/repeat_rule.dart';
import '../../models/task.dart';
import '../../models/task_session.dart';
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
    int? order,
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
      order: order,
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

  List<ScheduledTask> createEvent({
    required String title,
    required DateTime start,
    required DateTime end,
    String? location,
    String? notes,
    int? color,
    int? travelingTime,
    int? firstNotification,
    int? secondNotification,
    bool overrideOverlaps = false,
  }) {
    logInfo('Creating event: title - $title, start - $start, end - $end');

    final dateKey = _formatDateKey(start);

    // Check for overlaps first
    if (!overrideOverlaps) {
      final overlappingTasks = taskManager.scheduler.findOverlappingTasks(
        start: start,
        end: end,
        dateKey: dateKey,
      );

      if (overlappingTasks.isNotEmpty) {
        logInfo(
          'Event overlaps with ${overlappingTasks.length} existing tasks',
        );
        return overlappingTasks;
      }
    }

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

    taskManager.scheduler.scheduleEvent(
      task: task,
      start: start,
      end: end,
      overrideOverlaps: overrideOverlaps,
    );

    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
    logInfo('Event created successfully: $task.title');
    return [];
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

  List<Task> getSubtasksForTask(Task task) {
    final subtasks = <Task>[];
    for (var t in taskManager.tasksDB.values) {
      if (task.subtaskIds.contains(t.id)) {
        subtasks.add(t);
      }
    }

    // Sort subtasks by order field if available, otherwise maintain the order defined in subtaskIds
    subtasks.sort((a, b) {
      // If both tasks have an order, sort by order
      if (a.order != null && b.order != null) {
        return a.order!.compareTo(b.order!);
      }
      // If only one task has an order, prioritize the one with an order
      else if (a.order != null) {
        return -1;
      } else if (b.order != null) {
        return 1;
      }
      // If neither has an order, maintain the order in subtaskIds list
      else {
        return task.subtaskIds
            .indexOf(a.id)
            .compareTo(task.subtaskIds.indexOf(b.id));
      }
    });

    return subtasks;
  }

  Task? getParentTask(Task task) {
    if (task.parentTaskId == null) {
      return null;
    }
    return taskManager.tasksDB.get(task.parentTaskId);
  }

  Task? getTaskById(String taskId) {
    return taskManager.tasksDB.get(taskId);
  }

  String _formatDateKey(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  void deleteTask(Task task) {
    taskManager.deleteTaskById(task.id);
    emit(
      state.copyWith(tasks: taskManager.tasksDB.values.toList()),
    ); // Refresh state after deletion
  }

  void editTask({
    required Task task,
    String? title,
    int? priority,
    int? estimatedTime,
    int? deadline,
    Category? category,
    Task? parentTask,
    String? notes,
    int? color,
    int? order,
    RepeatRule? frequency,
    int? optimisticTime,
    int? realisticTime,
    int? pessimisticTime,
    int? firstNotification,
    int? secondNotification,
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
      order: order,
      frequency: frequency,
      optimisticTime: optimisticTime,
      realisticTime: realisticTime,
      pessimisticTime: pessimisticTime,
      firstNotification: firstNotification,
      secondNotification: secondNotification,
    );

    // Update state
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  void deleteScheduledTask(ScheduledTask scheduledTask) {
    taskManager.scheduler.removeScheduledTask(scheduledTask);
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  List<ScheduledTask> editEvent({
    required Task task,
    required String title,
    required DateTime start,
    required DateTime end,
    String? location,
    String? notes,
    int? color,
    int? travelingTime,
    int? firstNotification,
    int? secondNotification,
    bool overrideOverlaps = false,
  }) {
    logInfo(
      'Editing event: ${task.title} to new title - $title, start - $start, end - $end',
    );

    final dateKey = _formatDateKey(start);

    // Check for overlaps first, excluding the current task's scheduled tasks
    if (!overrideOverlaps) {
      final overlappingTasks =
          taskManager.scheduler
              .findOverlappingTasks(start: start, end: end, dateKey: dateKey)
              .where((st) => st.parentTaskId != task.id)
              .toList();

      if (overlappingTasks.isNotEmpty) {
        logInfo(
          'Event overlaps with ${overlappingTasks.length} existing tasks',
        );
        return overlappingTasks;
      }
    }

    if (task.scheduledTasks.isNotEmpty) {
      final scheduledTask = task.scheduledTasks.first;
      final oldDateKey = _formatDateKey(scheduledTask.startTime);
      final daysBox = Hive.box<Day>('scheduled_tasks');
      final day = daysBox.get(oldDateKey);

      if (day != null) {
        day.scheduledTasks.removeWhere(
          (st) => st.scheduledTaskId == scheduledTask.scheduledTaskId,
        );
        if (day.scheduledTasks.isEmpty) {
          daysBox.delete(oldDateKey);
        } else {
          daysBox.put(oldDateKey, day);
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

    taskManager.scheduler.scheduleEvent(
      task: task,
      start: start,
      end: end,
      overrideOverlaps: overrideOverlaps,
    );
    taskManager.tasksDB.put(task.id, task);

    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
    logInfo('Event updated successfully: ${task.title}');
    return [];
  }

  void updateTaskOrder(Task parentTask, List<Task> subtasks) {
    for (var i = 0; i < subtasks.length; i++) {
      final subtask = subtasks[i];
      editTask(
        task: subtask,
        title: subtask.title,
        priority: subtask.priority,
        estimatedTime: subtask.estimatedTime,
        deadline: subtask.deadline,
        category: subtask.category,
        parentTask: parentTask,
        notes: subtask.notes,
        color: subtask.color,
        order: i + 1,
        frequency: subtask.frequency,
        optimisticTime: subtask.optimisticTime,
        realisticTime: subtask.realisticTime,
        pessimisticTime: subtask.pessimisticTime,
        firstNotification: subtask.firstNotification,
        secondNotification: subtask.secondNotification,
      );
    }

    final subtaskIds = subtasks.map((subtask) => subtask.id).toList();
    parentTask.subtaskIds = subtaskIds;
    taskManager.tasksDB.put(parentTask.id, parentTask);

    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  void scheduleTasks() {
    taskManager.manageTasks();
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  void scheduleHabits() {
    logDebug('Scheduling habits');
    taskManager.manageHabits();
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  void updateUserSettings(UserSettings userSettings) {
    _deleteAllDays();
    taskManager.updateUserSettings(userSettings);
    try {
      final settingsBox = Hive.box<UserSettings>('user_settings');
      settingsBox.put('current', userSettings);
      logInfo('User settings updated and saved');
    } catch (e) {
      logError('Failed to save user settings: $e');
    }
    taskManager.manageEvents();
    scheduleTasks();
    scheduleHabits();

    emit(
      state.copyWith(
        tasks: taskManager.tasksDB.values.toList(),
        userSettings: userSettings,
      ),
    );
  }

  void updateScheduledTask(ScheduledTask scheduledTask) {
    taskManager.scheduler.updateScheduledTask(scheduledTask);
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  void _deleteAllDays() {
    final existingDayKeys = taskManager.daysDB.keys.cast<String>().toList();
    for (var dateKey in existingDayKeys) {
      taskManager.daysDB.delete(dateKey);
      logDebug('Deleted day: $dateKey');
    }
    logInfo('All days deleted');
  }

  int getBusyTime(int deadline) {
    return taskManager.taskUrgencyCalculator.busyTime(deadline, null);
  }

  /// Breaks down a task into subtasks using AI and schedules them
  ///
  /// Returns a list of the created subtasks
  Future<List<Task>> generateSubtasksFor(Task task) async {
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
      final subtasks = await generateSubtasksFor(task);

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
        var subtasks = getSubtasksForTask(task);
        for (var subtask in subtasks) {
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
      // TODO: Create a notification for the task completion check
      // TODO: This would typically use a notification service
      logInfo('Would send completion check reminder for task "${task.title}"');

      // await _notificationService.sendCompletionCheckReminder(task);
    } catch (e) {
      logError('Error sending completion check reminder: $e');
    }
  }

  /// Starts a task or subtask
  /// If the task has subtasks and they're not all completed, it can't be started
  /// Returns true if the task was started successfully, false otherwise
  bool startTask(Task task) {
    logInfo('Starting task: ${task.title}');
    final result = taskManager.startTask(task);
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
    return result;
  }

  /// Pauses a task that's in progress
  /// Returns true if the task was paused successfully, false otherwise
  bool pauseTask(Task task) {
    logInfo('Pausing task: ${task.title}');
    final result = taskManager.pauseTask(task);
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
    return result;
  }

  /// Stops a task that's in progress or paused
  /// Returns true if the task was stopped successfully, false otherwise
  bool stopTask(Task task) {
    logInfo('Stopping task: ${task.title}');
    final result = taskManager.stopTask(task);
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
    return result;
  }

  /// Completes a task
  /// If the task has a parent task, it checks if all siblings are completed
  /// and if so, it marks the parent task as completed too
  /// Returns true if the task was completed successfully, false otherwise
  bool completeTask(Task task) {
    logInfo('Completing task: ${task.title}');
    final result = taskManager.completeTask(task);
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
    return result;
  }

  /// Gets all task sessions for a task and its subtasks
  List<TaskSession> getTaskSessions(Task task) {
    return taskManager.getTaskSessions(task);
  }

  /// Gets the total duration for a task and its subtasks
  int getTotalDuration(Task task) {
    return taskManager.getTotalDuration(task);
  }

  /// Gets all tasks that are currently in progress
  List<Task> getTasksInProgress() {
    return taskManager.getTasksInProgress();
  }

  /// Gets all tasks that are currently paused
  List<Task> getPausedTasks() {
    return taskManager.getPausedTasks();
  }

  /// Schedule a reminder to check if a task is completed
  Future<void> scheduleCompletionCheckReminder(
    Task task,
    DateTime scheduledTime,
  ) async {
    try {
      // TODO: Schedule a notification for the task completion check
      // TODO: This would typically use a notification service
      logInfo(
        'Would schedule completion check reminder for task "${task.title}" at $scheduledTime',
      );

      //TODO:  await _notificationService.scheduleCompletionCheckReminder(task, scheduledTime);
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
