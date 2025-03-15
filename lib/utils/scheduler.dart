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
import '../services/notification_manager.dart';

class Scheduler {
  final Box<Day> daysDB;
  final Box<Task> tasksDB;
  UserSettings userSettings;
  late final Task freeTimeManager;
  final Map<String, Day> _dayCache = {};
  final NotificationManager? notificationManager;

  Scheduler(
    this.daysDB,
    this.tasksDB,
    this.userSettings, {
    this.notificationManager,
  }) {
    _initializeFreeTimeManager();
  }

  void updateUserSettings(UserSettings userSettings) {
    logInfo('Updating user settings in Scheduler');
    this.userSettings = userSettings;
  }

  void _initializeFreeTimeManager() {
    const freeTimeManagerId = 'free_time_manager';
    freeTimeManager =
        tasksDB.get(freeTimeManagerId) ??
        Task(
          id: freeTimeManagerId,
          title: 'Free Time',
          priority: 0,
          estimatedTime: 0,
          deadline: 0,
          category: Category(name: 'Free Time Manager'),
          scheduledTasks: [],
        );

    if (!tasksDB.containsKey(freeTimeManagerId)) {
      tasksDB.put(freeTimeManagerId, freeTimeManager);
      appLogger.info('Persisted new freeTimeManager to tasksDB', 'Scheduler', {
        'id': freeTimeManagerId,
      });
    } else {
      appLogger.info(
        'Loaded existing freeTimeManager from tasksDB',
        'Scheduler',
        {'id': freeTimeManagerId},
      );
    }
  }

  ScheduledTask? scheduleTask(
    Task task,
    int minSessionDuration, {
    double? urgency,
    List<String>? availableDates,
  }) {
    _dayCache.clear();

    if (urgency != null && urgency > 0) {
      _replaceTasksWithLowerPriority(task);
    }

    int remainingTime = task.estimatedTime;
    DateTime currentDate = DateTime.now();
    int dateIndex = 0;
    ScheduledTask? lastScheduledTask;

    removePreviousScheduledTasks(task);

    while (remainingTime > 0) {
      String dateKey;
      if (availableDates != null && dateIndex < availableDates.length) {
        dateKey = availableDates[dateIndex++];
      } else if (availableDates != null) {
        logDebug('All available dates exhausted for: ${task.title}');
        return lastScheduledTask;
      } else {
        dateKey = _formatDateKey(currentDate);
      }

      if (!_isActiveDay(dateKey)) {
        logDebug('Skipping inactive day: $dateKey');
        currentDate = currentDate.add(const Duration(days: 1));
        continue;
      }

      Day day = _getOrCreateDay(dateKey);
      DateTime start = _parseStartTime(dateKey);

      // Find all available slots in the current day
      List<ScheduledTask> availableSlots = _findAllAvailableTimeSlots(
        day,
        start,
        remainingTime,
        minSessionDuration,
        task.title,
        dateKey,
      );

      for (ScheduledTask slot in availableSlots) {
        lastScheduledTask = _createScheduledTask(
          task: task,
          urgency: urgency,
          start: slot.startTime,
          end: slot.endTime,
          dateKey: dateKey,
        );

        int slotDuration = _calculateDurationMs(slot.startTime, slot.endTime);
        remainingTime -= slotDuration;

        if (remainingTime <= 0) {
          break;
        }
      }

      // If we still have remaining time and sufficient urgency, try to displace existing tasks
      if (remainingTime > 0 && urgency != null && urgency > 0) {
        List<ScheduledTask> displacedTasks = _findDisplaceableSlots(
          day,
          start,
          remainingTime,
          minSessionDuration,
          urgency,
          task.title,
        );

        for (var taskToDisplace in displacedTasks) {
          _removeScheduledTask(taskToDisplace);
          lastScheduledTask = _createScheduledTask(
            task: task,
            urgency: urgency,
            start: taskToDisplace.startTime,
            end: taskToDisplace.endTime,
            dateKey: dateKey,
          );

          remainingTime -= _calculateDurationMs(
            taskToDisplace.startTime,
            taskToDisplace.endTime,
          );

          if (remainingTime <= 0) break;
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
      if (remainingTime > 0 && availableDates == null && dateIndex >= 30) {
        logDebug('Exceeded 30 days for: ${task.title}');
        break;
      }
    }

    tasksDB.put(task.id, task);
    return lastScheduledTask;
  }

  bool _isActiveDay(String dateKey) {
    final date = DateTime.parse('$dateKey 00:00:00');
    final weekdayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final dayName = weekdayNames[date.weekday - 1];
    return userSettings.activeDays?[dayName] ?? true;
  }

  void _replaceTasksWithLowerPriority(Task highPriorityTask) {
    List<ScheduledTask> tasksToRemove = [];
    for (Day day in daysDB.values) {
      for (ScheduledTask scheduledTask in List.from(day.scheduledTasks)) {
        Task? parentTask = tasksDB.get(scheduledTask.parentTaskId);
        if (parentTask != null &&
            parentTask.priority < highPriorityTask.priority &&
            scheduledTask.type == ScheduledTaskType.defaultType) {
          tasksToRemove.add(scheduledTask);
        }
      }
    }

    for (ScheduledTask scheduledTask in tasksToRemove) {
      for (Day day in daysDB.values) {
        if (day.scheduledTasks.contains(scheduledTask)) {
          day.scheduledTasks.remove(scheduledTask);
          daysDB.put(day.day, day);
        }
      }
      Task? parentTask = tasksDB.get(scheduledTask.parentTaskId);
      if (parentTask != null) {
        parentTask.scheduledTasks.remove(scheduledTask);
        tasksDB.put(parentTask.id, parentTask);
      }
    }

    if (tasksToRemove.isNotEmpty) {
      logInfo(
        'Displaced ${tasksToRemove.length} lower priority tasks for ${highPriorityTask.title}',
      );
    }
  }

  List<ScheduledTask> _findAllAvailableTimeSlots(
    Day day,
    DateTime start,
    int requiredTime,
    int minSession,
    String taskTitle,
    String dateKey,
  ) {
    final List<ScheduledTask> availableSlots = [];
    final sortedTasks = _sortScheduledTasksByTime(day.scheduledTasks);
    final dayStart = _parseStartTime(dateKey);
    final dayEnd = _parseEndOfDayTime(dateKey);
    int remainingTimeForSlots = requiredTime;

    // If no tasks in the day, use the entire day
    if (sortedTasks.isEmpty) {
      final slot = _tryCreateSlot(
        dayStart,
        dayEnd,
        remainingTimeForSlots,
        minSession,
        dateKey,
      );
      if (slot != null) {
        availableSlots.add(slot);
        remainingTimeForSlots -= _calculateDurationMs(
          slot.startTime,
          slot.endTime,
        );
      }
      return availableSlots;
    }

    // Check if there's space before the first task
    ScheduledTask? slot = _tryCreateSlot(
      dayStart,
      sortedTasks.first.startTime,
      remainingTimeForSlots,
      minSession,
      dateKey,
    );
    if (slot != null) {
      availableSlots.add(slot);
      remainingTimeForSlots -= _calculateDurationMs(
        slot.startTime,
        slot.endTime,
      );
    }

    // Check spaces between tasks
    for (int i = 0; i < sortedTasks.length - 1; i++) {
      if (remainingTimeForSlots <= 0) break;

      slot = _tryCreateSlot(
        sortedTasks[i].endTime,
        sortedTasks[i + 1].startTime,
        remainingTimeForSlots,
        minSession,
        dateKey,
      );

      if (slot != null) {
        availableSlots.add(slot);
        remainingTimeForSlots -= _calculateDurationMs(
          slot.startTime,
          slot.endTime,
        );
      }
    }

    // Check if there's space after the last task
    if (remainingTimeForSlots > 0) {
      slot = _tryCreateSlot(
        sortedTasks.last.endTime,
        dayEnd,
        remainingTimeForSlots,
        minSession,
        dateKey,
      );
      if (slot != null) {
        availableSlots.add(slot);
      }
    }

    return availableSlots;
  }

  ScheduledTask? _tryCreateSlot(
    DateTime start,
    DateTime end,
    int requiredTime,
    int minSession,
    String dateKey,
  ) {
    // Ensure start time is not before current time
    final now = DateTime.now();
    if (start.isBefore(now)) {
      start = now;
    }

    // If start time is after end time after adjustment, no slot is available
    if (start.isAfter(end)) return null;

    final availableTime = _calculateDurationMs(start, end);
    if (availableTime < minSession) return null;

    DateTime slotEnd = start.add(
      Duration(
        milliseconds:
            requiredTime > availableTime ? availableTime : requiredTime,
      ),
    );

    return _createTempScheduledTask(start, slotEnd);
  }

  ScheduledTask _createTempScheduledTask(DateTime start, DateTime end) =>
      ScheduledTask(
        scheduledTaskId: 'temp',
        parentTaskId: 'temp',
        startTime: start,
        endTime: end,
        type: ScheduledTaskType.defaultType,
        travelingTime: 0,
        breakTime: 0,
        notification: NotificationType.none,
      );

  List<ScheduledTask> _findDisplaceableSlots(
    Day day,
    DateTime start,
    int requiredTime,
    int minSession,
    double urgency,
    String taskTitle,
  ) {
    final displaceable = <ScheduledTask>[];
    int timeFound = 0;
    final tasks =
        day.scheduledTasks
            .where(
              (task) =>
                  task.startTime.isAfter(start) &&
                  task.type == ScheduledTaskType.defaultType &&
                  (task.urgency ?? 0) < urgency,
            )
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (var task in tasks) {
      final duration = _calculateDurationMs(task.startTime, task.endTime);
      if (duration >= minSession) {
        displaceable.add(task);
        timeFound += duration;
        logDebug(
          'Displacing task ${task.parentTaskId} (${task.urgency}) for $taskTitle ($urgency)',
        );
        if (timeFound >= requiredTime) break;
      }
    }
    return displaceable;
  }

  void _removeScheduledTask(ScheduledTask scheduledTask) {
    final task = tasksDB.get(scheduledTask.parentTaskId);
    if (task != null) {
      task.scheduledTasks.removeWhere(
        (st) => st.scheduledTaskId == scheduledTask.scheduledTaskId,
      );
      tasksDB.put(task.id, task);
    }

    final dateKey = _formatDateKey(scheduledTask.startTime);
    final day = _dayCache[dateKey] ?? daysDB.get(dateKey);
    if (day != null) {
      day.scheduledTasks.removeWhere(
        (st) => st.scheduledTaskId == scheduledTask.scheduledTaskId,
      );
      daysDB.put(dateKey, day);
    }
  }

  void removePreviousScheduledTasks(Task task) {
    final scheduledTasksCopy = List<ScheduledTask>.from(task.scheduledTasks);
    task.scheduledTasks.clear();
    tasksDB.put(task.id, task);

    final taskIdsByDay = <String, List<String>>{};
    for (var scheduledTask in scheduledTasksCopy) {
      final dateKey = _formatDateKey(scheduledTask.startTime);
      taskIdsByDay
          .putIfAbsent(dateKey, () => [])
          .add(scheduledTask.scheduledTaskId);
    }

    for (var entry in taskIdsByDay.entries) {
      final day = daysDB.get(entry.key);
      if (day != null) {
        day.scheduledTasks.removeWhere(
          (st) => entry.value.contains(st.scheduledTaskId),
        );
        daysDB.put(entry.key, day);
      }
    }

    logDebug(
      'Cleared ${scheduledTasksCopy.length} previous tasks for ${task.title}',
    );
  }

  List<ScheduledTask> _sortScheduledTasksByTime(List<ScheduledTask> tasks) =>
      List<ScheduledTask>.from(tasks)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

  Day _getOrCreateDay(String dateKey) {
    return _dayCache[dateKey] ??= daysDB.get(dateKey) ?? _createDay(dateKey);
  }

  Day _createDay(String dateKey) {
    logInfo('Creating new day: $dateKey');
    final day = Day(day: dateKey);
    daysDB.put(dateKey, day);
    _addPredefinedTimeBlocks(day);
    return day;
  }

  void _addPredefinedTimeBlocks(Day day) {
    logDebug('Adding predefined blocks for ${day.day}');
    final date = DateTime.parse('${day.day} 00:00:00');

    for (var timeFrame in userSettings.mealBreaks) {
      _addTimeBlock(day, timeFrame, ScheduledTaskType.mealBreak, date);
    }
    for (var timeFrame in userSettings.freeTime) {
      _addTimeBlock(day, timeFrame, ScheduledTaskType.rest, date);
    }
    for (var timeFrame in userSettings.sleepTime) {
      if (timeFrame.endTime.hour * 60 + timeFrame.endTime.minute <
          timeFrame.startTime.hour * 60 + timeFrame.startTime.minute) {
        // Split overnight sleep
        _addTimeBlock(
          day,
          TimeFrame(
            startTime: timeFrame.startTime,
            endTime: const TimeOfDay(hour: 23, minute: 59),
          ),
          ScheduledTaskType.sleep,
          date,
        );
        _addTimeBlock(
          day,
          TimeFrame(
            startTime: const TimeOfDay(hour: 0, minute: 0),
            endTime: timeFrame.endTime,
          ),
          ScheduledTaskType.sleep,
          date,
        );
      } else {
        _addTimeBlock(day, timeFrame, ScheduledTaskType.sleep, date);
      }
    }
  }

  void _addTimeBlock(
    Day day,
    TimeFrame timeFrame,
    ScheduledTaskType type,
    DateTime baseDate,
  ) {
    if (timeFrame.endTime.hour * 60 + timeFrame.endTime.minute <
        timeFrame.startTime.hour * 60 + timeFrame.startTime.minute) {
      // Split overnight task
      final firstDayStart = _combineDateKeyAndTimeOfDay(
        day.day,
        timeFrame.startTime,
      );
      final firstDayEnd = _combineDateKeyAndTimeOfDay(
        day.day,
        const TimeOfDay(hour: 23, minute: 59),
      );

      _createScheduledTask(
        task: freeTimeManager,
        type: type,
        start: firstDayStart,
        end: firstDayEnd,
        dateKey: day.day,
      );

      final nextDay = _formatDateKey(baseDate.add(const Duration(days: 1)));
      final nextDayStart = _combineDateKeyAndTimeOfDay(
        nextDay,
        const TimeOfDay(hour: 0, minute: 0),
      );
      final nextDayEnd = _combineDateKeyAndTimeOfDay(
        nextDay,
        timeFrame.endTime,
      );

      _createScheduledTask(
        task: freeTimeManager,
        type: type,
        start: nextDayStart,
        end: nextDayEnd,
        dateKey: nextDay,
      );
    } else {
      final start = _combineDateKeyAndTimeOfDay(day.day, timeFrame.startTime);
      final end = _combineDateKeyAndTimeOfDay(day.day, timeFrame.endTime);
      if (start.isBefore(baseDate) ||
          end.isAfter(baseDate.add(const Duration(days: 1)))) {
        return; // Skip if outside day bounds
      }
      _createScheduledTask(
        task: freeTimeManager,
        type: type,
        start: start,
        end: end,
        dateKey: day.day,
      );
    }
  }

  ScheduledTask _createScheduledTask({
    required Task task,
    required DateTime start,
    required DateTime end,
    required String dateKey,
    double? urgency,
    ScheduledTaskType? type,
  }) {
    if (!tasksDB.containsKey(task.id)) {
      tasksDB.put(task.id, task);
      appLogger.warning('Persisted unsaved task', 'Scheduler', {'id': task.id});
    }

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

    task.scheduledTasks.add(scheduledTask);
    tasksDB.put(task.id, task);

    final day = _getOrCreateDay(dateKey);
    day.scheduledTasks.add(scheduledTask);
    daysDB.put(dateKey, day);

    log('Scheduled task ${task.title} from $start to $end on $dateKey');
    return scheduledTask;
  }

  int _calculateDurationMs(DateTime start, DateTime end) =>
      end.difference(start).inMilliseconds;

  DateTime _parseStartTime(String dateKey) {
    final start = DateTime.parse('$dateKey 00:00:00');
    final now = DateTime.now();
    return start.isBefore(now) ? now : start;
  }

  DateTime _parseEndOfDayTime(String dateKey) =>
      DateTime.parse('$dateKey 23:59:59');

  int _getTravelTime(Coordinates? location) =>
      location != null && (location.latitude != 0 || location.longitude != 0)
          ? ((location.latitude.abs() + location.longitude.abs()) * 10).toInt()
          : 0;

  String _formatDateKey(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  DateTime _combineDateKeyAndTimeOfDay(String dateKey, TimeOfDay timeOfDay) {
    final year = int.parse(dateKey.substring(0, 4));
    final month = int.parse(dateKey.substring(4, 6));
    final day = int.parse(dateKey.substring(6, 8));
    return DateTime(year, month, day, timeOfDay.hour, timeOfDay.minute);
  }
}
