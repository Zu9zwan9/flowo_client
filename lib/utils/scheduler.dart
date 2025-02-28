import 'dart:developer';

import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/models/coordinates.dart';
import 'package:flowo_client/models/day.dart';
import 'package:flowo_client/models/notification_type.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/scheduled_task_type.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/models/user_settings.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/time_frame.dart';

class Scheduler {
  final Box<Day> daysDB;
  final Box<Task> tasksDB;
  final UserSettings userSettings;
  final Task freeTimeManager;

  // Cache to avoid repeated DB lookups
  final Map<String, Day> _dayCache = {};

  Scheduler(this.daysDB, this.tasksDB, this.userSettings)
      : freeTimeManager = Task(
          id: UniqueKey().toString(),
          title: 'Free Time',
          priority: 0,
          estimatedTime: 0,
          deadline: 0,
          category: Category(name: 'Free Time Manager'),
        );

  /// Schedule a task, potentially displacing lower priority tasks
  ScheduledTask? scheduleTask(Task task, int minSessionDuration,
      {double? urgency, List<String>? availableDates}) {
    // Clear cache for new scheduling operation
    _dayCache.clear();

    if (urgency != null && urgency > 0) {
      _replaceTasksWithLowerPriority(task);
    }

    int remainingTime =
        task.estimatedTime; // Fixed: removed undefined partSession variable
    DateTime currentDate = DateTime.now();
    int dateIndex = 0;
    ScheduledTask? createdTask;

    // Remove previous scheduled instances of this task
    removePreviousScheduledTasks(task);

    while (remainingTime > 0) {
      String dateKey;
      if (availableDates != null && dateIndex < availableDates.length) {
        dateKey = availableDates[dateIndex++];
      } else {
        if (availableDates != null) {
          logDebug('All available dates exhausted for: ${task.title}');
          return null;
        }
        dateKey = _formatDateKey(currentDate);
      }

      Day day = _getOrCreateDay(dateKey);
      DateTime start = _parseStartTime(dateKey);

      // Find available time slot
      ScheduledTask? slot = _findAvailableTimeSlot(
          day, start, remainingTime, minSessionDuration, task.title);

      if (slot != null) {
        createdTask = _createScheduledTask(
            task: task,
            urgency: urgency,
            start: slot.startTime,
            end: slot.endTime,
            dateKey: dateKey);

        remainingTime -= _calculateDurationMs(slot.startTime, slot.endTime);
      } else if (urgency != null && urgency > 0) {
        // Try to displace lower priority tasks
        List<ScheduledTask> displacedTasks = _findDisplaceableSlots(
            day, start, remainingTime, minSessionDuration, urgency, task.title);

        for (var taskToDisplace in displacedTasks) {
          _removeScheduledTask(taskToDisplace);

          createdTask = _createScheduledTask(
              task: task,
              urgency: urgency,
              start: taskToDisplace.startTime,
              end: taskToDisplace.endTime,
              dateKey: dateKey);

          remainingTime -= _calculateDurationMs(
              taskToDisplace.startTime, taskToDisplace.endTime);

          if (remainingTime <= 0) break;
        }
      }

      // Move to next day if needed
      if (remainingTime > 0) {
        currentDate = currentDate.add(const Duration(days: 1));
      } else {
        break;
      }
    }

    // Save changes to task
    task.save();

    return createdTask;
  }

  void _replaceTasksWithLowerPriority(Task highPriorityTask) {
    List<ScheduledTask> tasksToRemove = [];

    // Find all scheduled tasks with lower priority
    for (Day day in daysDB.values) {
      for (ScheduledTask scheduledTask in day.scheduledTasks.toList()) {
        Task? parentTask = tasksDB.get(scheduledTask.parentTaskId);
        if (parentTask != null &&
            parentTask.priority < highPriorityTask.priority &&
            scheduledTask.type == ScheduledTaskType.defaultType) {
          tasksToRemove.add(scheduledTask);
        }
      }
    }

    // Remove the lower priority scheduled tasks
    for (ScheduledTask scheduledTask in tasksToRemove) {
      // Remove from days
      for (Day day in daysDB.values) {
        if (day.scheduledTasks.contains(scheduledTask)) {
          day.scheduledTasks.remove(scheduledTask);
          day.save();
        }
      }

      // Remove from parent task
      Task? parentTask = tasksDB.get(scheduledTask.parentTaskId);
      if (parentTask != null) {
        parentTask.scheduledTasks.remove(scheduledTask);
        parentTask.save();
      }
    }

    // Log the replacement
    if (tasksToRemove.isNotEmpty) {
      logInfo(
          'Removed ${tasksToRemove.length} lower priority tasks for scheduling higher priority task: ${highPriorityTask.title}');
    }
  }

  /// Finding available time slots
  ScheduledTask? _findAvailableTimeSlot(Day day, DateTime start,
      int requiredTime, int minSession, String taskTitle) {
    var sortedTasks = _sortScheduledTasksByTime(day.scheduledTasks);

    // Handle empty day case
    if (sortedTasks.isEmpty) {
      return _createSlotForEmptyDay(day, start, requiredTime, minSession);
    }

    // Check gap before first task
    ScheduledTask? beforeFirstTask = _checkGapBeforeFirstTask(
        sortedTasks.first, start, requiredTime, minSession);
    if (beforeFirstTask != null) return beforeFirstTask;

    // Check gaps between tasks
    ScheduledTask? betweenTasks =
        _checkGapsBetweenTasks(sortedTasks, requiredTime, minSession);
    if (betweenTasks != null) return betweenTasks;

    // Check gap after last task
    return _checkGapAfterLastTask(
        day, sortedTasks.last, requiredTime, minSession);
  }

  // Helper methods for _findAvailableTimeSlot
  ScheduledTask? _createSlotForEmptyDay(
      Day day, DateTime start, int requiredTime, int minSession) {
    DateTime end = _parseEndOfDayTime(day.day);
    int availableTime = _calculateDurationMs(start, end);

    if (availableTime >= minSession) {
      if (availableTime > requiredTime) {
        end = start.add(Duration(milliseconds: requiredTime));
      }
      return _createTempScheduledTask(start, end);
    }
    return null;
  }

  ScheduledTask? _checkGapBeforeFirstTask(ScheduledTask firstTask,
      DateTime start, int requiredTime, int minSession) {
    int gapSize = _calculateDurationMs(start, firstTask.startTime);

    if (gapSize >= minSession) {
      DateTime end = firstTask.startTime;
      if (gapSize > requiredTime) {
        end = start.add(Duration(milliseconds: requiredTime));
      }
      return _createTempScheduledTask(start, end);
    }
    return null;
  }

  ScheduledTask? _checkGapsBetweenTasks(
      List<ScheduledTask> tasks, int requiredTime, int minSession) {
    for (int i = 0; i < tasks.length - 1; i++) {
      DateTime gapStart = tasks[i].endTime;
      DateTime gapEnd = tasks[i + 1].startTime;
      int gapSize = _calculateDurationMs(gapStart, gapEnd);

      if (gapSize >= minSession) {
        if (gapSize > requiredTime) {
          gapEnd = gapStart.add(Duration(milliseconds: requiredTime));
        }
        return _createTempScheduledTask(gapStart, gapEnd);
      }
    }
    return null;
  }

  ScheduledTask? _checkGapAfterLastTask(
      Day day, ScheduledTask lastTask, int requiredTime, int minSession) {
    DateTime endOfDay = _parseEndOfDayTime(day.day);
    int gapSize = _calculateDurationMs(lastTask.endTime, endOfDay);

    if (gapSize >= minSession) {
      if (gapSize > requiredTime) {
        endOfDay = lastTask.endTime.add(Duration(milliseconds: requiredTime));
      }
      return _createTempScheduledTask(lastTask.endTime, endOfDay);
    }
    return null;
  }

  ScheduledTask _createTempScheduledTask(DateTime start, DateTime end) {
    return ScheduledTask(
      scheduledTaskId: 'temp',
      parentTaskId: 'temp',
      startTime: start,
      endTime: end,
      type: ScheduledTaskType.defaultType,
      travelingTime: 0,
      breakTime: 0,
      notification: NotificationType.none,
    );
  }

  List<ScheduledTask> _findDisplaceableSlots(Day day, DateTime start,
      int requiredTime, int minSession, double urgency, String taskTitle) {
    List<ScheduledTask> displaceable = [];
    int timeFound = 0;

    // Get displaceable tasks and sort by urgency
    var tasks = day.scheduledTasks
        .where((task) =>
            task.startTime.isAfter(start) &&
            task.type == ScheduledTaskType.defaultType &&
            (task.urgency == null || task.urgency! < urgency))
        .toList()
      ..sort((a, b) => (a.urgency ?? 0).compareTo(b.urgency ?? 0));

    for (var task in tasks) {
      int taskDuration = _calculateDurationMs(task.startTime, task.endTime);

      if (taskDuration >= minSession) {
        displaceable.add(task);
        timeFound += taskDuration;

        logDebug(
            'Displacing: ${task.parentTaskId} (${task.urgency}) for $taskTitle ($urgency)');

        if (timeFound >= requiredTime) break;
      }
    }

    return displaceable;
  }

  void _removeScheduledTask(ScheduledTask scheduledTask) {
    // Remove from parent task
    var task = tasksDB.get(scheduledTask.parentTaskId);
    if (task != null) {
      task.scheduledTasks.removeWhere(
          (st) => st.scheduledTaskId == scheduledTask.scheduledTaskId);
      task.save();
    }

    // More efficient day lookup using dateKey from the task's start time
    String dateKey = _formatDateKey(scheduledTask.startTime);
    Day? day = _dayCache[dateKey] ?? daysDB.get(dateKey);

    if (day != null) {
      day.scheduledTasks.removeWhere(
          (st) => st.scheduledTaskId == scheduledTask.scheduledTaskId);
      day.save();
    }
  }

  void removePreviousScheduledTasks(Task task) {
    logDebug('${task.title} - ${task.scheduledTasks.length} scheduled tasks');

    // Create a copy to avoid modification during iteration
    final scheduledTasksCopy = List<ScheduledTask>.from(task.scheduledTasks);

    // Clear task's scheduled tasks in one operation
    task.scheduledTasks = [];
    task.save();

    // Create a map to batch operations by day
    final Map<String, List<String>> taskIdsByDay = {};

    for (ScheduledTask scheduledTask in scheduledTasksCopy) {
      String dateKey = _formatDateKey(scheduledTask.startTime);
      taskIdsByDay
          .putIfAbsent(dateKey, () => [])
          .add(scheduledTask.scheduledTaskId);
    }

    // Batch remove by day
    for (var entry in taskIdsByDay.entries) {
      Day? day = daysDB.get(entry.key);
      if (day != null) {
        day.scheduledTasks
            .removeWhere((st) => entry.value.contains(st.scheduledTaskId));
        day.save();
      }
    }

    logDebug(
        'After clearing ${task.title} - ${task.scheduledTasks.length} tasks remain');
  }

  // Utility methods
  List<ScheduledTask> _sortScheduledTasksByTime(List<ScheduledTask> tasks) {
    return List<ScheduledTask>.from(tasks)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Day _getOrCreateDay(String dateKey) {
    if (_dayCache.containsKey(dateKey)) {
      return _dayCache[dateKey]!;
    }

    Day? day = daysDB.get(dateKey);
    if (day != null) {
      _dayCache[dateKey] = day;
      return day;
    }

    day = _createDay(dateKey);
    _dayCache[dateKey] = day;
    return day;
  }

  Day _createDay(String dateKey) {
    final day = Day(day: dateKey);
    daysDB.put(dateKey, day);

    logDebug('Creating day $dateKey with user settings:\n'
        '- Break time: ${userSettings.breakTime}\n'
        '- Free time slots: ${userSettings.freeTime.length}\n'
        '- Sleep time slots: ${userSettings.sleepTime.length}\n'
        '- Meal breaks: ${userSettings.mealBreaks.length}\n'
        '- Min session: ${userSettings.minSession}');

    // Add predefined time blocks
    _addPredefinedTimeBlocks(day);

    return day;
  }

  void _addPredefinedTimeBlocks(Day day) {
    // Add meal breaks
    for (TimeFrame timeFrame in userSettings.mealBreaks) {
      _addTimeBlock(day, timeFrame, ScheduledTaskType.mealBreak);
    }

    // Add sleep time
    for (TimeFrame timeFrame in userSettings.sleepTime) {
      _addTimeBlock(day, timeFrame, ScheduledTaskType.sleep);
    }

    // Add free time
    for (TimeFrame timeFrame in userSettings.freeTime) {
      _addTimeBlock(day, timeFrame, ScheduledTaskType.rest);
    }
  }

  void _addTimeBlock(Day day, TimeFrame timeFrame, ScheduledTaskType type) {
    DateTime start = _combineDateKeyAndTimeOfDay(day.day, timeFrame.startTime);
    DateTime end = _combineDateKeyAndTimeOfDay(day.day, timeFrame.endTime);

    _createScheduledTask(
      task: freeTimeManager,
      type: type,
      start: start,
      end: end,
      dateKey: day.day,
    );
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
      scheduledTaskId: UniqueKey().toString(),
      parentTaskId: task.id,
      startTime: start,
      endTime: end,
      urgency: urgency,
      type: type ?? ScheduledTaskType.defaultType,
      travelingTime: _getTravelTime(task.location),
      breakTime: userSettings.breakTime ?? 5 * 60 * 1000,
      notification: NotificationType.none,
    );

    // Add to task's scheduled tasks
    task.scheduledTasks.add(scheduledTask);
    task.save();

    // Add to day
    final day = _getOrCreateDay(dateKey);
    day.scheduledTasks.add(scheduledTask);
    day.save();

    log('Created scheduled task from ${scheduledTask.startTime} to ${scheduledTask.endTime} for $dateKey');

    return scheduledTask;
  }

  // Helper methods for time calculations
  int _calculateDurationMs(DateTime start, DateTime end) {
    return end.difference(start).inMilliseconds;
  }

  DateTime _parseStartTime(String dateKey) {
    DateTime start = DateTime.parse('$dateKey 00:00:00');
    DateTime now = DateTime.now();
    return start.isBefore(now) ? now : start;
  }

  DateTime _parseEndOfDayTime(String dateKey) {
    return DateTime.parse('$dateKey 23:59:59');
  }

  int _getTravelTime(Coordinates? location) {
    if (location == null ||
        (location.latitude == 0 && location.longitude == 0)) {
      return 0;
    }
    return ((location.latitude.abs() + location.longitude.abs()) * 10).toInt();
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _combineDateKeyAndTimeOfDay(String dateKey, TimeOfDay timeOfDay) {
    final year = int.parse(dateKey.substring(0, 4));
    final month = int.parse(dateKey.substring(4, 6));
    final day = int.parse(dateKey.substring(6, 8));
    return DateTime(year, month, day, timeOfDay.hour, timeOfDay.minute);
  }
}
