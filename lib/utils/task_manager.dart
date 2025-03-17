import 'dart:developer';

import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/user_settings.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flowo_client/utils/scheduler.dart';
import 'package:flowo_client/utils/task_breakdown_api.dart';
import 'package:flowo_client/utils/task_estimator_api.dart';
import 'package:flowo_client/utils/task_urgency_calculator.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

import '../models/day.dart';
import '../models/repeat_rule.dart';
import '../models/scheduled_task_type.dart';
import '../models/task.dart';

class TaskManager {
  final Scheduler scheduler;
  final TaskUrgencyCalculator taskUrgencyCalculator;
  final TaskBreakdownAPI taskBreakdownAPI;
  final TaskEstimatorAPI taskEstimatorAPI;
  UserSettings userSettings;
  final Box<Day> daysDB;
  final Box<Task> tasksDB;

  TaskManager({
    required this.daysDB,
    required this.tasksDB,
    required this.userSettings,
    String? huggingFaceApiKey,
  }) : scheduler = Scheduler(daysDB, tasksDB, userSettings),
       taskUrgencyCalculator = TaskUrgencyCalculator(daysDB),
       taskBreakdownAPI = TaskBreakdownAPI(
         apiKey: huggingFaceApiKey ?? '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',
       ),
       taskEstimatorAPI = TaskEstimatorAPI(
         apiKey: huggingFaceApiKey ?? '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',
       );

  void updateUserSettings(UserSettings userSettings) {
    logInfo('Updating TaskManager user settings');
    this.userSettings = userSettings;
    scheduler.updateUserSettings(userSettings);
  }

  Task createTask(
    String title,
    int priority,
    int estimatedTime,
    int deadline,
    Category category, {
    Task? parentTask,
    String? notes,
    int? color,
    RepeatRule? frequency,
  }) {
    final task = Task(
      id: UniqueKey().toString(),
      title: title,
      priority: priority,
      estimatedTime: estimatedTime,
      deadline: deadline,
      category: category,
      notes: notes,
      color: color,
      frequency: frequency,
    );
    tasksDB.put(task.id, task);
    if (parentTask != null) {
      task.parentTask = parentTask;
      parentTask.subtasks.add(task);
      tasksDB.put(parentTask.id, parentTask);
    }
    logInfo('Created task: ${task.title}');
    return task;
  }

  // Fixed issue where task.key could be null causing "type 'Null' is not a subtype of type 'String'" error
  // We use task.id instead of task.key because tasks are stored with their id as the key
  void deleteTask(Task task) {
    tasksDB.delete(task.id);
    final parentTask = task.parentTask;
    if (parentTask != null) {
      parentTask.subtasks.remove(task);
      tasksDB.put(parentTask.id, parentTask);
    }
    for (var subtask in List.from(task.subtasks)) {
      deleteTask(subtask);
    }
    for (var scheduledTask in List.from(task.scheduledTasks)) {
      for (var day in daysDB.values) {
        if (day.scheduledTasks.contains(scheduledTask)) {
          day.scheduledTasks.remove(scheduledTask);
          daysDB.put(day.day, day); // Ensure day is saved
        }
      }
    }
    logInfo('Deleted task: ${task.title}');
  }

  void editTask(
    Task task,
    String title,
    int priority,
    int estimatedTime,
    int deadline,
    Category category,
    Task? parentTask, {
    String? notes,
    int? color,
    RepeatRule? frequency,
  }) {
    task.title = title;
    task.priority = priority;
    task.estimatedTime = estimatedTime;
    task.deadline = deadline;
    task.category = category;
    task.parentTask = parentTask;
    if (notes != null) {
      task.notes = notes;
    }
    if (color != null) {
      task.color = color;
    }
    if (frequency != null) {
      task.frequency = frequency;
    }
    tasksDB.put(task.id, task);
    logInfo('Edited task: ${task.title}');
  }

  void scheduleTasks() {
    final tasks =
        tasksDB.values
            .where((task) => (task.frequency == null) && task.subtasks.isEmpty)
            .toList();

    tasks.removeWhere((task) => task.id == 'free_time_manager');
    final justScheduledTasks = <ScheduledTask>[];

    while (tasks.isNotEmpty) {
      final taskUrgencyMap = taskUrgencyCalculator.calculateUrgency(
        tasks,
        justScheduledTasks,
      );
      if (taskUrgencyMap.isEmpty) {
        log('No tasks left to schedule');
        break;
      }

      final filteredEntries =
          taskUrgencyMap.entries
              .where((entry) => _isOrderCorrect(entry.key))
              .toList();

      if (filteredEntries.isEmpty) {
        log('No tasks with correct order to schedule');
        break;
      }

      final mostUrgentEntry = filteredEntries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      final mostUrgentTask = mostUrgentEntry.key;

      List<String>? availableDates;
      if (mostUrgentTask.frequency != null) {
        availableDates =
            _calculateHabitDates(mostUrgentTask).map(_formatDateKey).toList();
      }

      final scheduledTask = scheduler.scheduleTask(
        mostUrgentTask,
        userSettings.minSession,
        urgency:
            mostUrgentTask.frequency == null ? mostUrgentEntry.value : null,
        availableDates: availableDates,
      );

      if (scheduledTask != null) {
        justScheduledTasks.add(scheduledTask);
      }
      tasks.remove(mostUrgentTask);
    }
    logInfo('Scheduled ${justScheduledTasks.length} tasks');
  }

  void manageHabits() {
    // TODO: remake this method
    List<Task> habits =
        tasksDB.values.where((task) => task.frequency != null).toList();

    if (daysDB.values.isNotEmpty){
      logDebug(daysDB.values.first.toString() );
    }

    for (Task habit in habits) {
      List<DateTime> scheduledDates = _calculateHabitDates(habit);

      logDebug('Scheduled dates: $scheduledDates');

      for (DateTime date in scheduledDates) {
        logDebug(date.toIso8601String().split('T').first);

        scheduler.scheduleTask(
          habit,
          userSettings.minSession,
          availableDates: [date.toIso8601String().split('T').first],
        );
      }
    }
  }

  bool _isOrderCorrect(Task task) {
    if (task.order != null && task.order! > 0 && task.parentTask != null) {
      return !task.parentTask!.subtasks.any(
        (subtask) =>
            subtask.order != null &&
            subtask.order! < task.order! &&
            subtask.scheduledTasks.isEmpty,
      );
    }
    return true;
  }

  void removeScheduledTasks() {
    final now = DateTime.now();
    for (var day in daysDB.values) {
      final dayDate = DateTime.parse(day.day);
      if (dayDate.isBefore(now)) continue;

      final toRemove =
          day.scheduledTasks
              .where((st) => st.type == ScheduledTaskType.defaultType)
              .toList();
      for (var scheduledTask in toRemove) {
        day.scheduledTasks.remove(scheduledTask);
        final task = tasksDB.get(scheduledTask.parentTaskId);
        if (task != null) {
          task.scheduledTasks.remove(scheduledTask);
          tasksDB.put(task.id, task);
        }
      }
      daysDB.put(day.day, day);
    }
    logInfo('Removed scheduled tasks after ${now.toIso8601String()}');
  }

  List<DateTime> _calculateHabitDates(Task habit) {
    final dates = <DateTime>[];
    var currentDate = habit.startDate;
    final repeatRule = habit.frequency;

    if (repeatRule == null) {
      dates.add(currentDate);
      return dates;
    }

    final maxDate = DateTime.now().add(const Duration(days: 365 * 3));
    while ((repeatRule.until != null &&
            currentDate.isBefore(repeatRule.until!)) ||
        (repeatRule.count != null && dates.length < repeatRule.count!) ||
        (repeatRule.until == null &&
            repeatRule.count == null &&
            currentDate.isBefore(maxDate))) {
      switch (repeatRule.frequency) {
        case 'daily':
          dates.add(currentDate);
          currentDate = currentDate.add(Duration(days: repeatRule.interval));
          break;
        case 'weekly':
          if (repeatRule.byDay != null &&
              repeatRule.byDay!.contains(currentDate.weekday % 7)) {
            dates.add(currentDate);
          }
          currentDate = currentDate.add(const Duration(days: 1));
          break;
        case 'monthly':
          if (repeatRule.byMonthDay != null) {
            if (repeatRule.byMonthDay!.contains(currentDate.day)) {
              dates.add(currentDate);
            } else if (repeatRule.byMonthDay!.any((d) => d < 0)) {
              final lastDay = DateTime(
                currentDate.year,
                currentDate.month + 1,
                0,
              );
              final dayFromEnd =
                  lastDay.day +
                  (repeatRule.byMonthDay!.firstWhere((d) => d < 0) + 1);
              if (currentDate.day == dayFromEnd) {
                dates.add(currentDate);
              }
            }
          }
          if (repeatRule.bySetPos != null &&
              (currentDate.day - 1) ~/ 7 + 1 == repeatRule.bySetPos) {
            dates.add(currentDate);
          }
          currentDate = DateTime(
            currentDate.year,
            currentDate.month + repeatRule.interval,
            currentDate.day,
          );
          break;
        case 'yearly':
          dates.add(currentDate);
          if (repeatRule.byMonth != null && repeatRule.byMonth!.isNotEmpty) {
            for (var month in repeatRule.byMonth!) {
              var day = currentDate.day;
              if (day > DateTime(currentDate.year, month + 1, 0).day) {
                day = DateTime(currentDate.year, month + 1, 0).day;
              }
              final newDate = DateTime(
                currentDate.year + repeatRule.interval,
                month,
                day,
              );
              if (newDate.isAfter(currentDate)) dates.add(newDate);
            }
          } else {
            currentDate = DateTime(
              currentDate.year + repeatRule.interval,
              currentDate.month,
              currentDate.day,
            );
          }
          break;
        default:
          throw ArgumentError('Invalid frequency: ${repeatRule.frequency}');
      }
    }
    return dates;
  }

  String _formatDateKey(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  /// Breaks down a task into subtasks using AI and schedules them
  ///
  /// Returns a list of the created subtasks
  Future<List<Task>> breakdownAndScheduleTask(Task task) async {
    logInfo('Breaking down task: ${task.title}');

    // Use the API to break down the task into subtasks
    final subtaskTitles = await taskBreakdownAPI.breakdownTask(task.title);

    if (subtaskTitles.isEmpty) {
      logWarning('No subtasks generated for task: ${task.title}');

      // If no subtasks were generated, schedule the parent task itself
      logInfo('Scheduling parent task: ${task.title}');
      scheduler.scheduleTask(task, userSettings.minSession, urgency: null);

      return [];
    }

    logInfo('Generated ${subtaskTitles.length} subtasks for: ${task.title}');

    // Create subtask objects
    final subtasks = <Task>[];
    int order = 1;

    for (var subtaskTitle in subtaskTitles) {
      // Calculate estimated time based on parent task's estimated time
      // Distribute time proportionally among subtasks
      final estimatedTime = (task.estimatedTime / subtaskTitles.length).round();

      final subtask = Task(
        id: UniqueKey().toString(),
        title: subtaskTitle,
        priority: task.priority,
        estimatedTime: estimatedTime,
        deadline: task.deadline,
        category: task.category,
        parentTask: task,
        order: order++,
      );

      tasksDB.put(subtask.id, subtask);
      subtasks.add(subtask);

      // Add subtask to parent task's subtasks list
      task.subtasks.add(subtask);
    }

    // Update the parent task in the database
    tasksDB.put(task.id, task);

    // Schedule the subtasks
    scheduleSubtasks(subtasks);

    return subtasks;
  }

  /// Schedules a list of subtasks in order
  ///
  /// This method is protected (not private) to allow subclasses to access it.
  void scheduleSubtasks(List<Task> subtasks) {
    logInfo('Scheduling ${subtasks.length} subtasks');

    // Sort subtasks by order
    subtasks.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

    // Schedule each subtask
    for (var subtask in subtasks) {
      scheduler.scheduleTask(
        subtask,
        userSettings.minSession,
        urgency:
            null, // Let the scheduler determine urgency based on task properties
      );
      logInfo('Scheduled subtask: ${subtask.title}');
    }
  }
}
