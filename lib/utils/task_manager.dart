import 'dart:developer';

import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/user_settings.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flowo_client/utils/scheduler.dart';
import 'package:flowo_client/utils/task_urgency_calculator.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

import '../models/day.dart';
import '../models/scheduled_task_type.dart';
import '../models/task.dart';

class TaskManager {
  final Scheduler scheduler;
  final TaskUrgencyCalculator taskUrgencyCalculator;
  UserSettings userSettings;
  final Box<Day> daysDB;
  final Box<Task> tasksDB;

  TaskManager({
    required this.daysDB,
    required this.tasksDB,
    required this.userSettings,
  })  : scheduler = Scheduler(daysDB, tasksDB, userSettings),
        taskUrgencyCalculator = TaskUrgencyCalculator(daysDB);

  void updateUserSettings(UserSettings userSettings) {
    logInfo('Updating TaskManager user settings');
    this.userSettings = userSettings;
    scheduler.updateUserSettings(userSettings);
  }

  void createTask(String title, int priority, int estimatedTime, int deadline,
      Category category, Task? parentTask, String? notes) {
    final task = Task(
      id: UniqueKey().toString(),
      title: title,
      priority: priority,
      estimatedTime: estimatedTime,
      deadline: deadline,
      category: category,
      notes: notes,
    );
    tasksDB.put(task.id, task);
    if (parentTask != null) {
      task.parentTask = parentTask;
      parentTask.subtasks.add(task);
      tasksDB.put(parentTask.id, parentTask);
    }
    logInfo('Created task: ${task.title}');
  }

  void deleteTask(Task task) {
    tasksDB.delete(task.key);
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

  void editTask(Task task, String title, int priority, int estimatedTime,
      int deadline, Category category, Task? parentTask) {
    task.title = title;
    task.priority = priority;
    task.estimatedTime = estimatedTime;
    task.deadline = deadline;
    task.category = category;
    task.parentTask = parentTask;
    tasksDB.put(task.id, task);
    logInfo('Edited task: ${task.title}');
  }

  void scheduleTasks() {
    final tasks = tasksDB.values.toList();
    tasks.removeWhere((task) => task.id == 'free_time_manager');
    final justScheduledTasks = <ScheduledTask>[];

    while (tasks.isNotEmpty) {
      final taskUrgencyMap =
          taskUrgencyCalculator.calculateUrgency(tasks, justScheduledTasks);
      if (taskUrgencyMap.isEmpty) {
        log('No tasks left to schedule');
        break;
      }

      final mostUrgentEntry = taskUrgencyMap.entries
          .where((entry) => _isOrderCorrect(entry.key))
          .reduce((a, b) => a.value > b.value ? a : b);
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

  bool _isOrderCorrect(Task task) {
    if (task.order != null && task.order! > 0 && task.parentTask != null) {
      return !task.parentTask!.subtasks.any((subtask) =>
          subtask.order != null &&
          subtask.order! < task.order! &&
          subtask.scheduledTasks.isEmpty);
    }
    return true;
  }

  void removeScheduledTasks() {
    final now = DateTime.now();
    for (var day in daysDB.values) {
      final dayDate = DateTime.parse(day.day);
      if (dayDate.isBefore(now)) continue;

      final toRemove = day.scheduledTasks
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
    while (
        (repeatRule.until != null && currentDate.isBefore(repeatRule.until!)) ||
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
              final lastDay =
                  DateTime(currentDate.year, currentDate.month + 1, 0);
              final dayFromEnd = lastDay.day +
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
          currentDate = DateTime(currentDate.year,
              currentDate.month + repeatRule.interval, currentDate.day);
          break;
        case 'yearly':
          dates.add(currentDate);
          if (repeatRule.byMonth != null && repeatRule.byMonth!.isNotEmpty) {
            for (var month in repeatRule.byMonth!) {
              var day = currentDate.day;
              if (day > DateTime(currentDate.year, month + 1, 0).day) {
                day = DateTime(currentDate.year, month + 1, 0).day;
              }
              final newDate =
                  DateTime(currentDate.year + repeatRule.interval, month, day);
              if (newDate.isAfter(currentDate)) dates.add(newDate);
            }
          } else {
            currentDate = DateTime(currentDate.year + repeatRule.interval,
                currentDate.month, currentDate.day);
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
}
