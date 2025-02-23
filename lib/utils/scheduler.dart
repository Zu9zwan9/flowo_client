import 'dart:developer';

import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/models/coordinates.dart';
import 'package:flowo_client/models/day.dart';
import 'package:flowo_client/models/notification_type.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/scheduled_task_type.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/models/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/time_frame.dart';

class Scheduler {
  final Box<Day> daysDB;
  final Box<Task> tasksDB;
  final UserSettings userSettings;
  final Task freeTimeManager;

  Scheduler(this.daysDB, this.tasksDB, this.userSettings)
      : freeTimeManager = Task(
          id: UniqueKey().toString(),
          title: 'Free Time',
          priority: 0,
          estimatedTime: 0,
          deadline: 0,
          category: Category(name: 'Free Time Manager'),
        );

  ScheduledTask? scheduleTask(Task task, int minSession,
      {double? urgency, int? partSession, List<String>? availableDates}) {
    int remainingTime = partSession ?? task.estimatedTime;
    DateTime currentDate = DateTime.now();
    int dateIndex = 0;
    bool isFirstIteration = true;
    ScheduledTask? createdTask;

    while (remainingTime > 0) {
      String dateKey;
      if (availableDates != null && dateIndex < availableDates.length) {
        dateKey = availableDates[dateIndex];
        dateIndex++;
      } else {
        if (availableDates != null) {
          log('All available dates are exhausted for task: ${task.title}');
          return null;
        }
        dateKey = _formatDateKey(currentDate);
        if (!isFirstIteration) {
          currentDate = currentDate.add(Duration(days: 1));
        }
        isFirstIteration = false;
      }

      Day day = _getOrCreateDay(dateKey);
      DateTime start = DateTime.parse('$dateKey 00:00:00');
      if (start.isBefore(DateTime.now())) {
        start = DateTime.now();
      }
      DateTime end = start;
      var sortedScheduledTasks = _sortScheduledTasksByTime(day.scheduledTasks);

      for (ScheduledTask scheduledTask in sortedScheduledTasks) {
        end = scheduledTask.startTime;
        int possibleSessionTime = end.difference(start).inMilliseconds;
        if (possibleSessionTime >= minSession) {
          if (possibleSessionTime > remainingTime) {
            end = start.add(Duration(milliseconds: remainingTime));
            possibleSessionTime = remainingTime;
          }

          createdTask = _createScheduledTask(
              task: task,
              urgency: urgency,
              start: start,
              end: end,
              dateKey: dateKey);

          remainingTime -= possibleSessionTime;
          start = end;
        } else {
          start = scheduledTask.endTime;
        }
      }

      if (remainingTime > 0) {
        end = DateTime.parse('$dateKey 23:59:59');
        if (end.difference(start).inMilliseconds >= minSession) {
          int sessionTime = end.difference(start).inMilliseconds;
          if (sessionTime > remainingTime) {
            end = start.add(Duration(milliseconds: remainingTime));
            sessionTime = remainingTime;
          }

          createdTask = _createScheduledTask(
              task: task,
              urgency: urgency,
              start: start,
              end: end,
              dateKey: dateKey);
          remainingTime -= sessionTime;
        }
      }

      currentDate = currentDate.add(Duration(days: 1));
    }
    return createdTask;
  }

  List<ScheduledTask> _sortScheduledTasksByTime(
      List<ScheduledTask> scheduledTasks) {
    scheduledTasks.sort((a, b) => a.startTime.compareTo(b.startTime));
    return scheduledTasks;
  }

  Day _getOrCreateDay(String dateKey) {
    return daysDB.get(dateKey) ?? _createDay(dateKey);
  }

  Day _createDay(String dateKey) {
    final day = Day(day: dateKey);
    daysDB.put(dateKey, day);

    // Add meal breaks
    for (TimeFrame timeFrame in userSettings.mealBreaks) {
      DateTime start =
          _combineDateKeyAndTimeOfDay(dateKey, timeFrame.startTime);
      DateTime end = _combineDateKeyAndTimeOfDay(dateKey, timeFrame.endTime);

      _createScheduledTask(
        task: freeTimeManager,
        type: ScheduledTaskType.mealBreak,
        start: start,
        end: end,
        dateKey: dateKey,
      );
    }

    // Add sleep time
    for (TimeFrame timeFrame in userSettings.sleepTime) {
      DateTime start =
          _combineDateKeyAndTimeOfDay(dateKey, timeFrame.startTime);
      DateTime end = _combineDateKeyAndTimeOfDay(dateKey, timeFrame.endTime);

      _createScheduledTask(
          task: freeTimeManager,
          type: ScheduledTaskType.sleep,
          start: start,
          end: end,
          dateKey: dateKey);
    }

    // Add free time
    for (TimeFrame timeFrame in userSettings.freeTime) {
      DateTime start =
          _combineDateKeyAndTimeOfDay(dateKey, timeFrame.startTime);
      DateTime end = _combineDateKeyAndTimeOfDay(dateKey, timeFrame.endTime);

      _createScheduledTask(
        task: freeTimeManager,
        type: ScheduledTaskType.rest,
        start: start,
        end: end,
        dateKey: dateKey,
      );
    }

    return day;
  }

  ScheduledTask _createScheduledTask({
    required Task task,
    required DateTime start,
    required DateTime end,
    required String dateKey,
    double? urgency,
    ScheduledTaskType? type,
  }) {
    final scheduledTask = ScheduledTask(
      parentTask: task,
      startTime: start,
      endTime: end,
      urgency: urgency,
      type: type ?? ScheduledTaskType.defaultType,
      travelingTime: _getTravelTime(task.location),
      breakTime: userSettings.breakTime ?? 5 * 60 * 1000,
      notification: NotificationType.none,
    );
    task.scheduledTasks.add(scheduledTask);

    // Use the same day key for consistency.
    final day = daysDB.get(dateKey) ?? _createDay(dateKey);
    day.scheduledTasks.add(scheduledTask);

    // Verify that the scheduled task falls on the expected day.
    log('Created scheduled task from ${scheduledTask.startTime} to ${scheduledTask.endTime} for dateKey: $dateKey');

    return scheduledTask;
  }

  int _getTravelTime(Coordinates? location) {
    if (location == null) {
      return 0;
    }
    if (location.latitude == 0 && location.longitude == 0) {
      return 0;
    }
    return ((location.latitude.abs() + location.longitude.abs()) * 10).toInt();
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _combineDateKeyAndTimeOfDay(String dateKey, TimeOfDay timeOfDay) {
    final year = int.parse(dateKey.substring(0, 4));
    final month = int.parse(dateKey.substring(4, 6));
    final day = int.parse(dateKey.substring(6, 8));
    return DateTime(year, month, day, timeOfDay.hour, timeOfDay.minute);
  }
}
