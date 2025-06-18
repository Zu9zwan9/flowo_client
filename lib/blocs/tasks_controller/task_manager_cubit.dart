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
      editTask(task: subtask, order: i + 1);
    }
    final subtaskIds = subtasks.map((subtask) => subtask.id).toList();
    parentTask.subtaskIds = subtaskIds;
    taskManager.tasksDB.put(parentTask.id, parentTask);
    taskManager.manageTasks();
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
    // Delete all days to ensure clean slate
    _deleteAllDays();

    // Update user settings in the task manager
    taskManager.updateUserSettings(userSettings);

    try {
      final settingsBox = Hive.box<UserSettings>('user_settings');
      settingsBox.put('current', userSettings);
      logInfo('User settings updated and saved');
    } catch (e) {
      logError('Failed to save user settings: $e');
    }

    // Force scheduler to recreate days with updated schedules
    taskManager.scheduler.createDaysUntil(
      DateTime(DateTime.now().year, DateTime.now().month + 3),
    );

    // These will force recreation of events and tasks
    taskManager.manageEvents();
    scheduleTasks();
    scheduleHabits();

    // Refresh the UI state
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

  /// Resumes a task that was previously paused
  /// Returns true if the task was resumed successfully, false otherwise
  bool resumeTask(Task task) {
    logInfo('Resuming task: ${task.title}');

    if (task.status != 'paused') {
      logInfo('Cannot resume task "${task.title}" as it is not paused');
      return false;
    }

    try {
      // Find the last session (which should be the paused one)
      if (task.sessions.isNotEmpty) {
        final lastSession = task.sessions.last;

        // Calculate duration accumulated so far
        final durationSoFar =
            lastSession.endTime != null
                ? lastSession.endTime!
                    .difference(lastSession.startTime)
                    .inMilliseconds
                : 0;

        // Set a new session with the same ID but adjusted times
        // to continue where we left off
        TaskSession continuedSession = TaskSession(
          id: lastSession.id,
          // Keep the same ID
          taskId: task.id,
          startTime: DateTime.now().subtract(
            Duration(milliseconds: durationSoFar),
          ),
          // Adjust start time
          endTime: null,
          // No end time since it's active
          notes: lastSession.notes, // Keep any notes
        );

        // Remove the old session and add the continued one
        task.sessions.removeLast();
        task.sessions.add(continuedSession);
      } else {
        // Just in case there's no session to resume, create a new one
        final session = TaskSession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          taskId: task.id,
          startTime: DateTime.now(),
        );
        task.sessions.add(session);
      }

      // Update status
      task.status = 'in_progress';
      task.save();

      emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
      logInfo('Task "${task.title}" resumed successfully');
      return true;
    } catch (e) {
      logError('Error resuming task: $e');
      return false;
    }
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

extension TrackingFunctions on TaskManagerCubit {
  /// Returns the current tracking state including the active task, elapsed time, and running status
  ({Task? task, Duration? elapsed, bool isRunning}) getCurrentTracking() {
    // Find any task that's currently in progress
    final activeTasks = getTasksInProgress();
    if (activeTasks.isEmpty) {
      // Check for paused tasks if no in-progress tasks
      final pausedTasks = getPausedTasks();
      if (pausedTasks.isEmpty) {
        return (task: null, elapsed: null, isRunning: false);
      }
      // Return the most recently paused task
      final activeTask = pausedTasks.first;
      return (
        task: activeTask,
        elapsed: _calculateElapsedTime(activeTask),
        isRunning: false,
      );
    }

    // Return the most recently started task if multiple are in progress
    final activeTask = activeTasks.first;
    return (
      task: activeTask,
      elapsed: _calculateElapsedTime(activeTask),
      isRunning: true,
    );
  }

  /// Pause the current tracking session
  void pauseTaskTracking() {
    // Find the active task and pause it
    final activeTasks = getTasksInProgress();
    if (activeTasks.isNotEmpty) {
      pauseTask(activeTasks.first);
    }
  }

  /// Resume the paused tracking session
  void resumeTaskTracking() {
    // Find the paused task and resume it
    final pausedTasks = getPausedTasks();
    if (pausedTasks.isNotEmpty) {
      resumeTask(pausedTasks.first);
    }
  }

  /// Stop and save the current tracking session
  void stopTaskTracking() {
    // Check for in-progress tasks first
    final activeTasks = getTasksInProgress();
    if (activeTasks.isNotEmpty) {
      stopTask(activeTasks.first);
      return;
    }

    // Check for paused tasks if no in-progress tasks
    final pausedTasks = getPausedTasks();
    if (pausedTasks.isNotEmpty) {
      stopTask(pausedTasks.first);
    }
  }

  /// Calculate the elapsed time for a task based on its sessions
  Duration _calculateElapsedTime(Task task) {
    int totalMs = 0;

    // Calculate total time from completed sessions
    for (final session in task.sessions) {
      if (session.endTime != null) {
        totalMs +=
            session.endTime!.difference(session.startTime).inMilliseconds;
      }
    }

    // Add time from active session if there is one
    if (task.status == 'in_progress' && task.sessions.isNotEmpty) {
      final lastSession = task.sessions.last;
      if (lastSession.endTime == null) {
        totalMs +=
            DateTime.now().difference(lastSession.startTime).inMilliseconds;
      }
    }

    return Duration(milliseconds: totalMs);
  }

  /// Start tracking a specified task
  void startTaskTracking(Task task) {
    // Stop any current tracking first
    final currentTracking = getCurrentTracking();
    if (currentTracking.task != null) {
      stopTaskTracking();
    }

    // Now start the new task
    startTask(task);
  }

  /// Get a list of recently tracked tasks
  List<Task> getRecentlyTrackedTasks({int limit = 5}) {
    final tasks = taskManager.tasksDB.values.toList();

    // Filter to tasks with sessions
    final trackedTasks =
        tasks.where((task) => task.sessions.isNotEmpty).toList();

    // Sort by most recent session
    trackedTasks.sort((a, b) {
      final aLastSession =
          a.sessions.isNotEmpty ? a.sessions.last.startTime : DateTime(1970);
      final bLastSession =
          b.sessions.isNotEmpty ? b.sessions.last.startTime : DateTime(1970);
      return bLastSession.compareTo(aLastSession); // Descending order
    });

    // Return limited number
    return trackedTasks.take(limit).toList();
  }

  /// Get the total tracked time for today
  Duration getTodayTrackedTime() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int totalMs = 0;

    for (final task in taskManager.tasksDB.values) {
      for (final session in task.sessions) {
        // Check if session is from today
        final sessionDate = DateTime(
          session.startTime.year,
          session.startTime.month,
          session.startTime.day,
        );

        if (sessionDate == today) {
          if (session.endTime != null) {
            totalMs +=
                session.endTime!.difference(session.startTime).inMilliseconds;
          } else if (task.status == 'in_progress') {
            // Active session
            totalMs += now.difference(session.startTime).inMilliseconds;
          }
        }
      }
    }

    return Duration(milliseconds: totalMs);
  }

  void refreshState() {
    emit(
      state.copyWith(
        tasks: taskManager.tasksDB.values.toList(),
        userSettings: taskManager.userSettings,
      ),
    );
  }
}
