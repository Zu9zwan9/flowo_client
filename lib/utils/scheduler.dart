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
  UserSettings userSettings;
  late final Task freeTimeManager;
  final Map<String, Day> _dayCache = {};

  Scheduler(this.daysDB, this.tasksDB, this.userSettings) {
    _initializeFreeTimeManager();
  }

  void updateUserSettings(UserSettings userSettings) {
    logInfo('Previous user settings in scheduler:'
        '- Break time: ${userSettings.breakTime}\n'
        '- Free time slots: ${userSettings.freeTime.length}\n'
        '- Sleep time slots: ${userSettings.sleepTime.length}\n'
        '- Meal breaks: ${userSettings.mealBreaks.length}\n'
        '- Min session: ${userSettings.minSession}');

    this.userSettings = userSettings;

    logInfo('Updated user settings in scheduler:'
        '- Break time: ${userSettings.breakTime}\n'
        '- Free time slots: ${userSettings.freeTime.length}\n'
        '- Sleep time slots: ${userSettings.sleepTime.length}\n'
        '- Meal breaks: ${userSettings.mealBreaks.length}\n'
        '- Min session: ${userSettings.minSession}');
  }

  void _initializeFreeTimeManager() {
    const freeTimeManagerId = 'free_time_manager';
    Task? existingTask = tasksDB.get(freeTimeManagerId);

    if (existingTask == null) {
      freeTimeManager = Task(
        id: freeTimeManagerId,
        title: 'Free Time',
        priority: 0,
        estimatedTime: 0,
        deadline: 0,
        category: Category(name: 'Free Time Manager'),
        scheduledTasks: [], // Ensure initialized
      );
      tasksDB.put(freeTimeManagerId, freeTimeManager);
      logger.i('Persisted new freeTimeManager to tasksDB with ID: $freeTimeManagerId');
    } else {
      freeTimeManager = existingTask;
      logger.i('Loaded existing freeTimeManager from tasksDB with ID: $freeTimeManagerId');
    }

    // Verify box state
    if (!tasksDB.isOpen) {
      logger.e('tasksDB is not open during initialization');
      throw HiveError('tasksDB must be open to initialize Scheduler');
    }
  }

  ScheduledTask? scheduleTask(Task task, int minSessionDuration,
      {double? urgency, List<String>? availableDates}) {
    _dayCache.clear();

    if (urgency != null && urgency > 0) {
      _replaceTasksWithLowerPriority(task);
    }

    int remainingTime = task.estimatedTime;
    DateTime currentDate = DateTime.now();
    int dateIndex = 0;
    ScheduledTask? createdTask;

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

      ScheduledTask? slot = _findAvailableTimeSlot(day, start, remainingTime, minSessionDuration, task.title);

      if (slot != null) {
        createdTask = _createScheduledTask(
          task: task,
          urgency: urgency,
          start: slot.startTime,
          end: slot.endTime,
          dateKey: dateKey,
        );
        remainingTime -= _calculateDurationMs(slot.startTime, slot.endTime);
      } else if (urgency != null && urgency > 0) {
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
          createdTask = _createScheduledTask(
            task: task,
            urgency: urgency,
            start: taskToDisplace.startTime,
            end: taskToDisplace.endTime,
            dateKey: dateKey,
          );
          remainingTime -= _calculateDurationMs(taskToDisplace.startTime, taskToDisplace.endTime);
          if (remainingTime <= 0) break;
        }
      }

      if (remainingTime > 0) {
        currentDate = currentDate.add(const Duration(days: 1));
      } else {
        break;
      }
    }

    task.save();
    return createdTask;
  }

  void _replaceTasksWithLowerPriority(Task highPriorityTask) {
    List<ScheduledTask> tasksToRemove = [];
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

    for (ScheduledTask scheduledTask in tasksToRemove) {
      for (Day day in daysDB.values) {
        if (day.scheduledTasks.contains(scheduledTask)) {
          day.scheduledTasks = List.from(day.scheduledTasks)..remove(scheduledTask);
          day.save();
        }
      }
      Task? parentTask = tasksDB.get(scheduledTask.parentTaskId);
      if (parentTask != null) {
        parentTask.scheduledTasks = List.from(parentTask.scheduledTasks)..remove(scheduledTask);
        parentTask.save();
      }
    }

    if (tasksToRemove.isNotEmpty) {
      logInfo('Removed ${tasksToRemove.length} lower priority tasks for scheduling higher priority task: ${highPriorityTask.title}');
    }
  }

  ScheduledTask? _findAvailableTimeSlot(Day day, DateTime start, int requiredTime, int minSession, String taskTitle) {
    var sortedTasks = _sortScheduledTasksByTime(day.scheduledTasks);
    if (sortedTasks.isEmpty) return _createSlotForEmptyDay(day, start, requiredTime, minSession);

    ScheduledTask? beforeFirstTask = _checkGapBeforeFirstTask(sortedTasks.first, start, requiredTime, minSession);
    if (beforeFirstTask != null) return beforeFirstTask;

    ScheduledTask? betweenTasks = _checkGapsBetweenTasks(sortedTasks, requiredTime, minSession);
    if (betweenTasks != null) return betweenTasks;

    return _checkGapAfterLastTask(day, sortedTasks.last, requiredTime, minSession);
  }

  ScheduledTask? _createSlotForEmptyDay(Day day, DateTime start, int requiredTime, int minSession) {
    DateTime end = _parseEndOfDayTime(day.day);
    int availableTime = _calculateDurationMs(start, end);
    if (availableTime >= minSession) {
      if (availableTime > requiredTime) end = start.add(Duration(milliseconds: requiredTime));
      return _createTempScheduledTask(start, end);
    }
    return null;
  }

  ScheduledTask? _checkGapBeforeFirstTask(ScheduledTask firstTask, DateTime start, int requiredTime, int minSession) {
    int gapSize = _calculateDurationMs(start, firstTask.startTime);
    if (gapSize >= minSession) {
      DateTime end = firstTask.startTime;
      if (gapSize > requiredTime) end = start.add(Duration(milliseconds: requiredTime));
      return _createTempScheduledTask(start, end);
    }
    return null;
  }

  ScheduledTask? _checkGapsBetweenTasks(List<ScheduledTask> tasks, int requiredTime, int minSession) {
    for (int i = 0; i < tasks.length - 1; i++) {
      DateTime gapStart = tasks[i].endTime;
      DateTime gapEnd = tasks[i + 1].startTime;
      int gapSize = _calculateDurationMs(gapStart, gapEnd);
      if (gapSize >= minSession) {
        if (gapSize > requiredTime) gapEnd = gapStart.add(Duration(milliseconds: requiredTime));
        return _createTempScheduledTask(gapStart, gapEnd);
      }
    }
    return null;
  }

  ScheduledTask? _checkGapAfterLastTask(Day day, ScheduledTask lastTask, int requiredTime, int minSession) {
    DateTime endOfDay = _parseEndOfDayTime(day.day);
    int gapSize = _calculateDurationMs(lastTask.endTime, endOfDay);
    if (gapSize >= minSession) {
      DateTime end = gapSize > requiredTime ? lastTask.endTime.add(Duration(milliseconds: requiredTime)) : endOfDay;
      return _createTempScheduledTask(lastTask.endTime, end);
    }
    return null;
  }

  ScheduledTask _createTempScheduledTask(DateTime start, DateTime end) => ScheduledTask(
    scheduledTaskId: 'temp',
    parentTaskId: 'temp',
    startTime: start,
    endTime: end,
    type: ScheduledTaskType.defaultType,
    travelingTime: 0,
    breakTime: 0,
    notification: NotificationType.none,
  );

  List<ScheduledTask> _findDisplaceableSlots(Day day, DateTime start, int requiredTime, int minSession, double urgency, String taskTitle) {
    List<ScheduledTask> displaceable = [];
    int timeFound = 0;
    var tasks = day.scheduledTasks
        .where((task) => task.startTime.isAfter(start) && task.type == ScheduledTaskType.defaultType && (task.urgency == null || task.urgency! < urgency))
        .toList()
      ..sort((a, b) => (a.urgency ?? 0).compareTo(b.urgency ?? 0));

    for (var task in tasks) {
      int taskDuration = _calculateDurationMs(task.startTime, task.endTime);
      if (taskDuration >= minSession) {
        displaceable.add(task);
        timeFound += taskDuration;
        logDebug('Displacing: ${task.parentTaskId} (${task.urgency}) for $taskTitle ($urgency)');
        if (timeFound >= requiredTime) break;
      }
    }
    return displaceable;
  }

  void _removeScheduledTask(ScheduledTask scheduledTask) {
    var task = tasksDB.get(scheduledTask.parentTaskId);
    if (task != null) {
      task.scheduledTasks = List.from(task.scheduledTasks)..removeWhere((st) => st.scheduledTaskId == scheduledTask.scheduledTaskId);
      task.save();
    }

    String dateKey = _formatDateKey(scheduledTask.startTime);
    Day? day = _dayCache[dateKey] ?? daysDB.get(dateKey);
    if (day != null) {
      day.scheduledTasks = List.from(day.scheduledTasks)..removeWhere((st) => st.scheduledTaskId == scheduledTask.scheduledTaskId);
      day.save();
    }
  }

  void removePreviousScheduledTasks(Task task) {
    final scheduledTasksCopy = List<ScheduledTask>.from(task.scheduledTasks);
    task.scheduledTasks = [];
    task.save();

    final Map<String, List<String>> taskIdsByDay = {};
    for (ScheduledTask scheduledTask in scheduledTasksCopy) {
      String dateKey = _formatDateKey(scheduledTask.startTime);
      taskIdsByDay.putIfAbsent(dateKey, () => []).add(scheduledTask.scheduledTaskId);
    }

    for (var entry in taskIdsByDay.entries) {
      Day? day = daysDB.get(entry.key);
      if (day != null) {
        day.scheduledTasks = List.from(day.scheduledTasks)..removeWhere((st) => entry.value.contains(st.scheduledTaskId));
        day.save();
      }
    }

    logDebug('After clearing ${task.title} - ${task.scheduledTasks.length} tasks remain');
  }

  List<ScheduledTask> _sortScheduledTasksByTime(List<ScheduledTask> tasks) => List<ScheduledTask>.from(tasks)..sort((a, b) => a.startTime.compareTo(b.startTime));

  Day _getOrCreateDay(String dateKey) {
    if (_dayCache.containsKey(dateKey)) return _dayCache[dateKey]!;
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
    logInfo('Day $dateKey not found, creating new day');
    final day = Day(day: dateKey, scheduledTasks: []);
    daysDB.put(dateKey, day);
    _addPredefinedTimeBlocks(day);
    return day;
  }

  void _addPredefinedTimeBlocks(Day day) {
    logDebug('Adding predefined time blocks for day: ${day.day} with user settings:\n'
        '- Break time: ${userSettings.breakTime}\n'
        '- Free time slots: ${userSettings.freeTime.length}\n'
        '- Sleep time slots: ${userSettings.sleepTime.length}\n'
        '- Meal breaks: ${userSettings.mealBreaks.length}\n'
        '- Min session: ${userSettings.minSession}');

    for (TimeFrame timeFrame in userSettings.mealBreaks) {
      logInfo('Adding meal break for ${timeFrame.startTime} - ${timeFrame.endTime}');
      _addTimeBlock(day, timeFrame, ScheduledTaskType.mealBreak);
    }
    for (TimeFrame timeFrame in userSettings.sleepTime) {
      logInfo('Adding sleep time for ${timeFrame.startTime} - ${timeFrame.endTime}');
      _addTimeBlock(day, timeFrame, ScheduledTaskType.sleep);
    }
    for (TimeFrame timeFrame in userSettings.freeTime) {
      logInfo('Adding free time for ${timeFrame.startTime} - ${timeFrame.endTime}');
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
    // Ensure task is in the box before modification
    if (!tasksDB.containsKey(task.id)) {
      tasksDB.put(task.id, task);
      logger.w('Task ${task.id} was not in box; persisted it');
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

    task.scheduledTasks = List.from(task.scheduledTasks)..add(scheduledTask);
    tasksDB.put(task.id, task); // Use put instead of save to ensure persistence

    final day = _getOrCreateDay(dateKey);
    day.scheduledTasks = List.from(day.scheduledTasks)..add(scheduledTask);
    daysDB.put(dateKey, day); // Use put instead of save for consistency

    log('Created scheduled task from ${scheduledTask.startTime} to ${scheduledTask.endTime} for $dateKey');
    return scheduledTask;
  }

  int _calculateDurationMs(DateTime start, DateTime end) => end.difference(start).inMilliseconds;

  DateTime _parseStartTime(String dateKey) {
    DateTime start = DateTime.parse('$dateKey 00:00:00');
    DateTime now = DateTime.now();
    return start.isBefore(now) ? now : start;
  }

  DateTime _parseEndOfDayTime(String dateKey) => DateTime.parse('$dateKey 23:59:59');

  int _getTravelTime(Coordinates? location) {
    if (location == null || (location.latitude == 0 && location.longitude == 0)) return 0;
    return ((location.latitude.abs() + location.longitude.abs()) * 10).toInt();
  }

  String _formatDateKey(DateTime date) => '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  DateTime _combineDateKeyAndTimeOfDay(String dateKey, TimeOfDay timeOfDay) {
    final year = int.parse(dateKey.substring(0, 4));
    final month = int.parse(dateKey.substring(4, 6));
    final day = int.parse(dateKey.substring(6, 8));
    return DateTime(year, month, day, timeOfDay.hour, timeOfDay.minute);
  }
}

// TODO: check free time scheduled tasks adding to daysDB
