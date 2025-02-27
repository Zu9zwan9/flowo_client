import 'dart:developer';

import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/user_settings.dart';
import 'package:flowo_client/utils/scheduler.dart';
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
  final UserSettings userSettings;
  final Box<Day> daysDB;
  final Box<Task> tasksDB;

  TaskManager({
    required this.daysDB,
    required this.tasksDB,
    required this.userSettings,
  })  : scheduler = Scheduler(daysDB, tasksDB, userSettings),
        taskUrgencyCalculator = TaskUrgencyCalculator(daysDB);

  createTask(String title, int priority, int estimatedTime, int deadline,
      Category category, Task? parentTask) {
    Task task = Task(
      id: UniqueKey().toString(),
      title: title,
      priority: priority,
      estimatedTime: estimatedTime,
      deadline: deadline,
      category: category,
    );
    tasksDB.put(task.key, task);
    if (parentTask != null) {
      task.parentTask = parentTask;
      parentTask.subtasks.add(task);
    }
  }

  deleteTask(Task task) {
    tasksDB.delete(task.key);
    final parentTask = task.parentTask;
    if (parentTask != null) {
      parentTask.subtasks.remove(task);
    }
    for (Task subtask in task.subtasks) {
      deleteTask(subtask);
    }
    for (ScheduledTask scheduledTask in task.scheduledTasks) {
      for (var day in daysDB.values) {
        day.scheduledTasks.remove(scheduledTask);
      }
    }
  }

  editTask(Task task, String title, int priority, int estimatedTime,
      int deadline, Category category, Task? parentTask) {
    task.title = title;
    task.priority = priority;
    task.estimatedTime = estimatedTime;
    task.deadline = deadline;
    task.category = category;
    task.parentTask = parentTask;
  }

  void manageTasks() {
    List<Task> tasks = tasksDB.values
        .where((task) =>
            (task.frequency == null || task.frequency!.isEmpty) &&
            task.subtasks.isEmpty)
        .toList();

    List<ScheduledTask> justScheduledTasks = [];

    while (tasks.isNotEmpty) {
      final taskUrgencyMap =
          taskUrgencyCalculator.calculateUrgency(tasks, justScheduledTasks);

      if (taskUrgencyMap.isEmpty) {
        log('No tasks to schedule');
        break;
      }
      log('Task Urgency Map: $taskUrgencyMap');

      Task mostUrgentTask = taskUrgencyMap.entries
          .where((entry) => _isOrderCorrect(entry.key))
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      ScheduledTask? scheduledTask = scheduler.scheduleTask(
          mostUrgentTask, userSettings.minSession,
          urgency: taskUrgencyMap[mostUrgentTask]);
      if (scheduledTask != null) {
        justScheduledTasks.add(scheduledTask);
      }
      tasks.remove(mostUrgentTask);
    }
  }

  _isOrderCorrect(Task task) {
    if (task.order != null && task.order! > 0) {
      Task? parentTask = task.parentTask;
      if (parentTask != null) {
        if (parentTask.subtasks.any((subtask) =>
            subtask.order != null &&
            subtask.order != 0 &&
            subtask.order! < task.order! &&
            subtask.scheduledTasks.isEmpty)) {
          return false;
        }
      }
    }
    return true;
  }

  void manageHabits() {
    List<Task> habits = tasksDB.values
        .where((task) => task.frequency != null && task.frequency!.isNotEmpty)
        .toList();

    for (Task habit in habits) {
      List<DateTime> scheduledDates = _calculateHabitDates(habit);

      for (DateTime date in scheduledDates) {
        scheduler.scheduleTask(
          habit,
          userSettings.minSession,
          availableDates: [date.toIso8601String().split('T').first],
        );
      }
    }
  }

  void removeScheduledTasks() {
    final now = DateTime.now();

    for (Day day in daysDB.values) {
      final dayDate = DateTime.parse(day.day);
      if (dayDate.isBefore(now)) continue;

      day.scheduledTasks.removeWhere((scheduledTask) {
        if (scheduledTask.type == ScheduledTaskType.defaultType) {
          scheduledTask.parentTask.scheduledTasks.remove(scheduledTask);
          return true;
        }
        return false;
      });
    }
  }

  bool _isLeapYear(int year) {
    if (year % 4 != 0) return false;
    if (year % 100 != 0) return true;
    if (year % 400 != 0) return false;
    return true;
  }

  List<DateTime> _calculateHabitDates(Task habit) {
    List<DateTime> dates = [];
    DateTime currentDate = habit.startDate;
    RepeatRule repeatRule = habit.repeatRule;

    while (
        (repeatRule.until != null && currentDate.isBefore(repeatRule.until!)) ||
            (repeatRule.count != null && dates.length < repeatRule.count!) ||
            (repeatRule.until == null &&
                repeatRule.count == null &&
                currentDate
                    .isBefore(DateTime.now().add(Duration(days: 365 * 3))))) {
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
          currentDate = currentDate.add(Duration(days: 1));
          break;
        case 'monthly':
          if (repeatRule.byMonthDay != null) {
            if (repeatRule.byMonthDay!.contains(currentDate.day)) {
              dates.add(currentDate);
            } else if (repeatRule.byMonthDay!.contains(-currentDate.day)) {
              DateTime lastDayOfMonth =
                  DateTime(currentDate.year, currentDate.month + 1, 0);
              int dayFromEnd = lastDayOfMonth.day +
                  repeatRule.byMonthDay!.firstWhere((day) => day < 0) +
                  1;
              if (currentDate.day == dayFromEnd) {
                dates.add(currentDate);
              }
            }
          }
          if (repeatRule.bySetPos != null &&
              (currentDate.day - 1) ~/ 7 + 1 == repeatRule.bySetPos) {
            dates.add(currentDate); //To review (31-1 ~/7 + 1 = 5)
          }
          currentDate = DateTime(currentDate.year,
              currentDate.month + repeatRule.interval, currentDate.day);
          break;
        case 'yearly':
          dates.add(currentDate);
          if (repeatRule.byMonth != null && repeatRule.byMonth!.isNotEmpty) {
            for (int month in repeatRule.byMonth!) {
              int day = currentDate.day;
              if (day > DateTime(currentDate.year, month + 1, 0).day) {
                day = DateTime(currentDate.year, month + 1, 0).day;
              }
              DateTime newDate =
                  DateTime(currentDate.year + repeatRule.interval, month, day);
              if (newDate.isAfter(currentDate)) {
                dates.add(newDate);
              }
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
}
