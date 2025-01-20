import 'dart:developer';

import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/days.dart';
import 'package:flowo_client/models/notification_type.dart';
import 'package:flowo_client/models/scheduled_task_type.dart';
import 'package:flowo_client/models/coordinates.dart';
import 'package:hive/hive.dart';

class Scheduler {
  final Box<Days> daysDB;
  final Box<Task> tasksDB;

  Scheduler(this.daysDB, this.tasksDB);

  void scheduleTask(Task task, int minSession,
      {double? urgency, int? partSession, List<String>? availableDates}) {
    int remainingTime = partSession ?? task.estimatedTime;
    DateTime currentDate = DateTime.now();
    int dateIndex = 0;
    bool isFirstIteration = true;

    while (remainingTime > 0) {
      String dateKey;
      if (availableDates != null && dateIndex < availableDates.length) {
        dateKey = availableDates[dateIndex];
        dateIndex++;
      } else {
        if (availableDates != null) {
          // Signal that all available dates are exhausted
          log('Not enough available dates to schedule the task.'); // TODO: make this a proper error message
          return;
        }
        dateKey = _formatDateKey(currentDate);
        if (!isFirstIteration) {
          currentDate = currentDate.add(Duration(days: 1));
        }
        isFirstIteration = false;
      }

      Days day = _getOrCreateDay(dateKey);
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

          _createScheduledTask(task, urgency, start, end);
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

          _createScheduledTask(task, urgency, start, end);
          remainingTime -= sessionTime;
        }
      }

      currentDate = currentDate.add(Duration(days: 1));
    }
  }

  List<ScheduledTask> _sortScheduledTasksByTime(
      List<ScheduledTask> scheduledTasks) {
    scheduledTasks.sort((a, b) => a.startTime.compareTo(b.startTime));
    return scheduledTasks;
  }

  Days _getOrCreateDay(String dateKey) {
    return daysDB.get(dateKey) ?? _createDay(dateKey);
  }

  Days _createDay(String dateKey) {
    final day = Days(day: dateKey, scheduledTasks: []);
    // TODO: Add connection to FreeTimeManager, and create pinned tasks
    daysDB.put(dateKey, day);
    return day;
  }

  void _createScheduledTask(
    Task task,
    double? urgency,
    DateTime start,
    DateTime end,
  ) {
    final scheduledTask = ScheduledTask(
      parentTask: task,
      startTime: start,
      endTime: end,
      urgency: urgency,
      type: ScheduledTaskType.defaultType,
      travelingTime: _getTravelTime(task.location),
      breakTime: _getBreakTime(),
      notification: NotificationType.none,
    );
    task.scheduledTask.add(scheduledTask);
    tasksDB.put(task.key, task);
  }

  int _getTravelTime(Coordinates? location) {
    if (location == null) {
      return 0;
    }
    // Example logic: calculate travel time based on coordinates
    return (location.latitude.abs() + location.longitude.abs()).toInt() * 10;
  }

  int _getBreakTime() {
    // Example logic: retrieve break time from user settings or a default value
    return 30 * 60 * 1000; // 30 minutes in milliseconds
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}
