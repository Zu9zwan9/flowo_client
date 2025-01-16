import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/days.dart';
import 'package:flowo_client/models/notification_type.dart';
import 'package:flowo_client/models/scheduled_task_type.dart';
import 'package:flowo_client/models/coordinates.dart';
import 'package:hive/hive.dart';

import '../models/repeat_rule.dart';

class Scheduler {
  final Box<Days> daysDB;
  final Box<Task> tasksDB;

  Scheduler(this.daysDB, this.tasksDB);

  void scheduleHabitTasks(List<Task> habitTasks) {
    for (var habitTask in habitTasks) {
      List<DateTime> dates = _calculateHabitDates(habitTask);
      for (var date in dates) {
        _createScheduledTaskForHabit(habitTask, date);
      }
    }
  }

  List<DateTime> _calculateHabitDates(Task habitTask) {
    List<DateTime> dates = [];
    DateTime currentDate = habitTask.startDate;
    DateTime? endDate = habitTask.endDate;

    while (currentDate.isBefore(endDate)) {
      if (!_isExceptionDate(habitTask, currentDate)) {
        dates.add(currentDate);
      }
      currentDate = _getNextDate(currentDate, habitTask.repeatRule);
    }

    return dates;
  }

  bool _isExceptionDate(Task habitTask, DateTime date) {
    return habitTask.exceptions.contains(date);
  }

  DateTime _getNextDate(DateTime currentDate, RepeatRule repeatRule) {
    switch (repeatRule.frequency) {
      case 'daily':
        return currentDate.add(Duration(days: repeatRule.interval));
      case 'weekly':
        return currentDate.add(Duration(days: 7 * repeatRule.interval));
      case 'monthly':
        return DateTime(currentDate.year,
            (currentDate.month + repeatRule.interval), currentDate.day);
      case 'yearly':
        return DateTime((currentDate.year + repeatRule.interval),
            currentDate.month, currentDate.day);
      default:
        throw Exception('Invalid frequency');
    }
  }

  void _createScheduledTaskForHabit(Task task, DateTime date) {
    final scheduledTask = ScheduledTask(
      parentTask: task,
      startTime: date,
      endTime: date.add(Duration(hours: 1)), // Example duration
      urgency: 0,
      type: ScheduledTaskType.defaultType,
      travelingTime: 0,
      breakTime: 0,
      notification: NotificationType.none,
    );
    task.scheduledTask.add(scheduledTask);
    tasksDB.put(task.key, task); // Store the task in the tasksDB
  }

  void scheduleTask(Task task,
      {List<String>? availableDates, int? partSession}) {
    int remainingTime = partSession ?? task.estimatedTime;
    DateTime start = DateTime.now();
    DateTime end = start.add(Duration(milliseconds: remainingTime));

    while (remainingTime > 0) {
      for (String dateKey in _getAllDates(availableDates)) {
        Days day = _getOrCreateDay(dateKey);
        for (TimeRange timeRange in day.timeRanges) {
          if (end.difference(start).inMilliseconds >= task.minSession) {
            _createScheduledTask(task, start, end);
            remainingTime -= end.difference(start).inMilliseconds;
            start = end;
            end = start.add(Duration(milliseconds: remainingTime));
          } else {
            start = timeRange.end;
            end = start.add(Duration(milliseconds: remainingTime));
          }
        }
      }
    }
  }

  Days _getOrCreateDay(String dateKey) {
    return daysDB.get(dateKey) ?? _createDay(dateKey);
  }

  Days _createDay(String dateKey) {
    final day = Days(day: dateKey, timeRanges: []);
    daysDB.put(dateKey, day);
    return day;
  }

  void _createScheduledTask(Task task, DateTime start, DateTime end) {
    final scheduledTask = ScheduledTask(
      parentTask: task,
      startTime: start,
      endTime: end,
      urgency: task.priority,
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

  List<String> _getAllDates(List<String>? availableDates) {
    if (availableDates != null && availableDates.isNotEmpty) {
      return availableDates;
    }
    // Example logic: generate a list of dates
    return List.generate(7,
        (index) => _formatDateKey(DateTime.now().add(Duration(days: index))));
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}
