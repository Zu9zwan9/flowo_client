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
import '../models/repeat_rule_instance.dart';
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
    List<Task> habits =
    tasksDB.values.where((task) => task.frequency != null).toList();

    for (Task habit in habits) {
      List<DateTime> scheduledDates = _calculateHabitDates(habit);
      List<String> daysKeys = scheduledDates.map(_formatDateKey).toList();
      scheduler.scheduleTask(
        habit,
        userSettings.minSession,
        availableDates: daysKeys,
      );
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

  /// Calculates the dates for a habit based on its RepeatRule, now handling RepeatRuleInstance.
  List<DateTime> _calculateHabitDates(Task habit) {
    final dates = <DateTime>[];
    var currentDate = DateTime(
      habit.startDate.year,
      habit.startDate.month,
      habit.startDate.day,
    ); // Ensure we start from midnight
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
        // For daily, byDay contains one RepeatRuleInstance with selectedDay as 'daily'
          if (repeatRule.byDay != null && repeatRule.byDay!.isNotEmpty) {
            dates.add(currentDate);
          }
          currentDate = currentDate.add(Duration(days: repeatRule.interval));
          break;

        case 'weekly':
          if (repeatRule.byDay != null && repeatRule.byDay!.isNotEmpty) {
            final weekdays = repeatRule.byDay!
                .map((instance) => _dayNameToInt(instance.selectedDay))
                .toSet();
            // Check each day of the week starting from currentDate
            for (int i = 0; i < 7; i++) {
              final checkDate = currentDate.add(Duration(days: i));
              if (weekdays.contains(checkDate.weekday)) {
                dates.add(checkDate);
              }
            }
            // Move to the next week
            currentDate = currentDate.add(Duration(days: 7 * repeatRule.interval));
          } else {
            currentDate = currentDate.add(Duration(days: 7 * repeatRule.interval));
          }
          break;

        case 'monthly':
          if (repeatRule.byMonthDay != null && repeatRule.byMonthDay!.isNotEmpty) {
            final monthDays = repeatRule.byMonthDay!
                .map((instance) => int.parse(instance.selectedDay))
                .toSet();
            final lastDayOfMonth = DateTime(currentDate.year, currentDate.month + 1, 0).day;
            for (var day in monthDays) {
              int actualDay = day;
              if (day < 0) {
                // Negative days count from the end
                actualDay = lastDayOfMonth + day + 1;
              }
              if (actualDay >= 1 && actualDay <= lastDayOfMonth && actualDay == currentDate.day) {
                dates.add(currentDate);
              }
            }
          } else if (repeatRule.bySetPos != null &&
              repeatRule.byDay != null &&
              repeatRule.byDay!.isNotEmpty) {
            final weekday = _dayNameToInt(repeatRule.byDay!.first.selectedDay);
            final monthStart = DateTime(currentDate.year, currentDate.month, 1);
            final daysInMonth = DateTime(currentDate.year, currentDate.month + 1, 0).day;
            int occurrence = 0;
            for (int day = 1; day <= daysInMonth; day++) {
              final checkDate = DateTime(currentDate.year, currentDate.month, day);
              if (checkDate.weekday == weekday) {
                occurrence++;
                if (repeatRule.bySetPos! > 0 && occurrence == repeatRule.bySetPos!) {
                  dates.add(checkDate);
                  break;
                } else if (repeatRule.bySetPos! < 0) {
                  // Handle negative bySetPos (e.g., last Monday)
                  final lastOccurrence = _findLastOccurrence(monthStart, weekday);
                  if (checkDate.day == lastOccurrence.day) {
                    dates.add(checkDate);
                  }
                }
              }
            }
          }
          currentDate = DateTime(
            currentDate.year,
            currentDate.month + repeatRule.interval,
            1,
          );
          break;

        case 'yearly':
          if (repeatRule.byDay != null && repeatRule.byDay!.isNotEmpty) {
            // For yearly, byDay contains one RepeatRuleInstance with selectedDay as 'yearly'
            dates.add(currentDate);
          }
          if (repeatRule.byMonth != null && repeatRule.byMonth!.isNotEmpty) {
            final months = repeatRule.byMonth!
                .map((instance) => int.parse(instance.selectedDay))
                .toSet();
            for (var month in months) {
              final daysInMonth = DateTime(currentDate.year, month + 1, 0).day;
              final day = currentDate.day > daysInMonth ? daysInMonth : currentDate.day;
              final newDate = DateTime(currentDate.year, month, day);
              if (newDate.isAfter(currentDate) || newDate == currentDate) {
                dates.add(newDate);
              }
            }
          }
          currentDate = DateTime(
            currentDate.year + repeatRule.interval,
            currentDate.month,
            currentDate.day,
          );
          break;

        default:
          throw ArgumentError('Invalid frequency: ${repeatRule.frequency}');
      }
    }
    return dates;
  }

  /// Converts day names to weekday integers (1 = Monday, ..., 7 = Sunday).
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
    return dayMap[dayName.toLowerCase()] ?? 1; // Default to Monday if invalid
  }

  /// Finds the last occurrence of a weekday in a month.
  DateTime _findLastOccurrence(DateTime monthStart, int weekday) {
    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    DateTime lastDate = monthStart;
    for (int day = 1; day <= daysInMonth; day++) {
      final checkDate = DateTime(monthStart.year, monthStart.month, day);
      if (checkDate.weekday == weekday) {
        lastDate = checkDate;
      }
    }
    return lastDate;
  }

  String _formatDateKey(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  Future<List<Task>> breakdownAndScheduleTask(Task task) async {
    logInfo('Breaking down task: ${task.title}');

    final subtaskTitles = await taskBreakdownAPI.breakdownTask(task.title);

    if (subtaskTitles.isEmpty) {
      logWarning('No subtasks generated for task: ${task.title}');
      logInfo('Scheduling parent task: ${task.title}');
      scheduler.scheduleTask(task, userSettings.minSession, urgency: null);
      return [];
    }

    logInfo('Generated ${subtaskTitles.length} subtasks for: ${task.title}');

    final subtasks = <Task>[];
    int order = 1;

    for (var subtaskTitle in subtaskTitles) {
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
      task.subtasks.add(subtask);
    }

    tasksDB.put(task.id, task);
    scheduleSubtasks(subtasks);

    return subtasks;
  }

  void scheduleSubtasks(List<Task> subtasks) {
    logInfo('Scheduling ${subtasks.length} subtasks');
    subtasks.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    for (var subtask in subtasks) {
      scheduler.scheduleTask(
        subtask,
        userSettings.minSession,
        urgency: null,
      );
      logInfo('Scheduled subtask: ${subtask.title}');
    }
  }
}