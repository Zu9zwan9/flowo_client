import 'dart:developer';

import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/models/coordinates.dart';
import 'package:flowo_client/models/day.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/scheduled_task_type.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/models/user_settings.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/day_schedule.dart';
import '../models/time_frame.dart';
import '../services/notification/notification_service.dart';

class Scheduler {
  final Box<Day> daysDB;
  final Box<Task> tasksDB;
  UserSettings userSettings;
  late final Task freeTimeManager;
  final NotiService notiService = NotiService();

  Scheduler(this.daysDB, this.tasksDB, this.userSettings) {
    _initializeFreeTimeManager();
  }

  void updateUserSettings(UserSettings userSettings) {
    logInfo('Days in database: ${daysDB.keys.length}');
    logInfo('Updating user settings in Scheduler');
    this.userSettings = userSettings;
    createDaysUntil(DateTime(DateTime.now().year, DateTime.now().month + 3));
    logInfo('Days in database: ${daysDB.keys.length}');
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
    int remainingTime = task.remainingWorkTime();
    DateTime currentDate = DateTime.now();
    int dateIndex = 0;
    ScheduledTask? lastScheduledTask;

    while (remainingTime > 0 ||
        (availableDates != null && availableDates.isNotEmpty)) {
      String dateKey = formatDateKey(currentDate);

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
        lastScheduledTask = createScheduledTask(
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

      currentDate = currentDate.add(const Duration(days: 1));
      if (remainingTime > 0 && dateIndex >= 30) {
        logDebug('Exceeded 30 days for: ${task.title}');
        break;
      }
    }

    tasksDB.put(task.id, task);
    return lastScheduledTask;
  }

  List<ScheduledTask> findOverlappingTasks({
    required DateTime start,
    required DateTime end,
    required String dateKey,
  }) {
    final day = _getOrCreateDay(dateKey);
    final sortedTasks = _sortScheduledTasksByTime(day.scheduledTasks);
    final overlappingTasks = <ScheduledTask>[];

    for (ScheduledTask scheduledTask in sortedTasks) {
      if (scheduledTask.startTime.isBefore(end) &&
          scheduledTask.endTime.isAfter(start)) {
        overlappingTasks.add(scheduledTask);
      }
    }

    return overlappingTasks;
  }

  void scheduleEvent({
    required Task task,
    required DateTime start,
    required DateTime end,
    bool overrideOverlaps = false,
  }) {
    final dateKey = formatDateKey(start);

    if (!overrideOverlaps) {
      final overlappingTasks = findOverlappingTasks(
        start: start,
        end: end,
        dateKey: dateKey,
      );

      if (overlappingTasks.isNotEmpty) {
        logDebug(
          'Event overlaps with ${overlappingTasks.length} existing tasks',
        );
        // Return the overlapping tasks without scheduling
        // The caller will handle showing the modal dialog
        return;
      }
    }

    logDebug('Scheduling event: ${task.title} from $start to $end');
    createScheduledTask(
      task: task,
      start: start,
      end: end,
      dateKey: dateKey,
      type: ScheduledTaskType.timeSensitive,
    );
  }

  void scheduleHabit(
    Task task,
    List<DateTime> dates,
    TimeOfDay start,
    TimeOfDay end,
  ) {
    for (DateTime date in dates) {
      final dateKey = formatDateKey(date);
      final day = _getOrCreateDay(dateKey);
      final startTime = _combineDateKeyAndTimeOfDay(dateKey, start);
      final endTime = _combineDateKeyAndTimeOfDay(dateKey, end);

      final sortedTasks = _sortScheduledTasksByTime(day.scheduledTasks);
      for (ScheduledTask scheduledTask in sortedTasks) {
        if (scheduledTask.startTime.isBefore(endTime) &&
            scheduledTask.endTime.isAfter(startTime)) {
          logDebug(
            'Habit overlaps with existing task: ${scheduledTask.parentTaskId}',
          );
          return;
        }
      }

      createScheduledTask(
        task: task,
        start: startTime,
        end: endTime,
        dateKey: dateKey,
        type: ScheduledTaskType.timeSensitive,
      );
    }
  }

  // Update these methods in the Scheduler class

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

    // First look in the new schedules list
    for (final schedule in userSettings.schedules) {
      if (schedule.day.contains(dayName)) {
        return schedule.isActive;
      }
    }

    // Fall back to the old daySchedules map
    final daySchedule = userSettings.daySchedules[dayName];
    if (daySchedule != null) {
      return daySchedule.isActive;
    }

    // Finally fall back to global active days
    return userSettings.activeDays?[dayName] ?? true;
  }

  void _addPredefinedTimeBlocks(Day day) {
    logDebug('Adding predefined blocks for ${day.day}');
    final date = DateTime.parse('${day.day} 00:00:00');

    // Get the day of the week (Monday, Tuesday, etc.)
    final weekdayNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final dayName = weekdayNames[date.weekday - 1];

    // First, check if this day is assigned to any schedule in the new model
    DaySchedule? scheduleForDay;
    for (final schedule in userSettings.schedules) {
      if (schedule.day.any((d) => d.toLowerCase() == dayName.toLowerCase())) {
        scheduleForDay = schedule;
        break;
      }
    }

    if (scheduleForDay != null) {
      // Found a schedule in the new model
      logDebug('Using schedule "${scheduleForDay.name}" for $dayName');

      // Add meal breaks
      for (var timeFrame in scheduleForDay.mealBreaks) {
        if (timeFrame.endTime.hour * 60 + timeFrame.endTime.minute <
            timeFrame.startTime.hour * 60 + timeFrame.startTime.minute) {
          _addTimeBlock(
            day,
            TimeFrame(
              startTime: timeFrame.startTime,
              endTime: const TimeOfDay(hour: 23, minute: 59),
            ),
            ScheduledTaskType.mealBreak,
            date,
          );
          _addTimeBlock(
            day,
            TimeFrame(
              startTime: const TimeOfDay(hour: 0, minute: 0),
              endTime: timeFrame.endTime,
            ),
            ScheduledTaskType.mealBreak,
            date,
          );
        } else {
          _addTimeBlock(day, timeFrame, ScheduledTaskType.mealBreak, date);
        }
      }

      // Add free times
      for (var timeFrame in scheduleForDay.freeTimes) {
        if (timeFrame.endTime.hour * 60 + timeFrame.endTime.minute <
            timeFrame.startTime.hour * 60 + timeFrame.startTime.minute) {
          _addTimeBlock(
            day,
            TimeFrame(
              startTime: timeFrame.startTime,
              endTime: const TimeOfDay(hour: 23, minute: 59),
            ),
            ScheduledTaskType.rest,
            date,
          );
          _addTimeBlock(
            day,
            TimeFrame(
              startTime: const TimeOfDay(hour: 0, minute: 0),
              endTime: timeFrame.endTime,
            ),
            ScheduledTaskType.rest,
            date,
          );
        } else {
          _addTimeBlock(day, timeFrame, ScheduledTaskType.rest, date);
        }
      }

      // Add sleep time
      final sleepTime = scheduleForDay.sleepTime;
      if (sleepTime.endTime.hour * 60 + sleepTime.endTime.minute <
          sleepTime.startTime.hour * 60 + sleepTime.startTime.minute) {
        _addTimeBlock(
          day,
          TimeFrame(
            startTime: sleepTime.startTime,
            endTime: const TimeOfDay(hour: 23, minute: 59),
          ),
          ScheduledTaskType.sleep,
          date,
        );
        _addTimeBlock(
          day,
          TimeFrame(
            startTime: const TimeOfDay(hour: 0, minute: 0),
            endTime: sleepTime.endTime,
          ),
          ScheduledTaskType.sleep,
          date,
        );
      } else {
        _addTimeBlock(day, sleepTime, ScheduledTaskType.sleep, date);
      }

      return; // Exit early if we found a schedule
    }

    // If no schedule found in the new model, continue with the fallback to old model
    final daySchedule = userSettings.daySchedules[dayName];

    if (daySchedule != null && daySchedule.isActive) {
      logDebug('Using legacy day-specific schedule for $dayName');
    } else {
      // Use global schedule
      logDebug('Using global schedule for $dayName');
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
      );

  void updateScheduledTask(ScheduledTask newScheduledTask) {
    // only tasks with unchanged IDs
    final task = tasksDB.get(newScheduledTask.parentTaskId);
    if (task != null) {
      task.scheduledTasks.removeWhere(
        (st) => st.scheduledTaskId == newScheduledTask.scheduledTaskId,
      );
      task.scheduledTasks.add(newScheduledTask);
      tasksDB.put(task.id, task);
    }

    final dateKey = formatDateKey(newScheduledTask.startTime);
    final day = daysDB.get(dateKey);
    if (day != null) {
      day.scheduledTasks.removeWhere(
        (st) => st.scheduledTaskId == newScheduledTask.scheduledTaskId,
      );
      day.scheduledTasks.add(newScheduledTask);
      daysDB.put(dateKey, day);
    }
  }

  void removeScheduledTask(ScheduledTask scheduledTask) {
    final task = tasksDB.get(scheduledTask.parentTaskId);
    if (task != null) {
      task.scheduledTasks.removeWhere(
        (st) => st.scheduledTaskId == scheduledTask.scheduledTaskId,
      );
      tasksDB.put(task.id, task);
    }

    final dateKey = formatDateKey(scheduledTask.startTime);
    final day = daysDB.get(dateKey);
    if (day != null) {
      day.scheduledTasks.removeWhere(
        (st) => st.scheduledTaskId == scheduledTask.scheduledTaskId,
      );
      daysDB.put(dateKey, day);
    }
  }

  List<ScheduledTask> _sortScheduledTasksByTime(List<ScheduledTask> tasks) =>
      List<ScheduledTask>.from(tasks)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

  Day _getOrCreateDay(String dateKey) {
    return daysDB.get(dateKey) ?? _createDay(dateKey);
  }

  Day _createDay(String dateKey) {
    logInfo('Creating new day: $dateKey');
    final day = Day(day: dateKey);
    daysDB.put(dateKey, day);
    _addPredefinedTimeBlocks(day);
    return day;
  }

  void createDaysUntil(DateTime date) {
    logInfo('Creating days until: ${date.toIso8601String()}');
    final now = DateTime.now();
    final endDate = date.isBefore(now) ? now : date;
    final daysToCreate = endDate.difference(now).inDays;

    for (int i = 0; i <= daysToCreate; i++) {
      final dateKey = formatDateKey(now.add(Duration(days: i)));
      if (!daysDB.containsKey(dateKey)) {
        _getOrCreateDay(dateKey);
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

      createScheduledTask(
        task: freeTimeManager,
        type: type,
        start: firstDayStart,
        end: firstDayEnd,
        dateKey: day.day,
      );

      final nextDay = formatDateKey(baseDate.add(const Duration(days: 1)));
      final nextDayStart = _combineDateKeyAndTimeOfDay(
        nextDay,
        const TimeOfDay(hour: 0, minute: 0),
      );
      final nextDayEnd = _combineDateKeyAndTimeOfDay(
        nextDay,
        timeFrame.endTime,
      );

      createScheduledTask(
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
      createScheduledTask(
        task: freeTimeManager,
        type: type,
        start: start,
        end: end,
        dateKey: day.day,
      );
    }
  }

  ScheduledTask createScheduledTask({
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
    );

    task.scheduledTasks.add(scheduledTask);
    tasksDB.put(task.id, task);

    if (task.firstNotification != null) {
      scheduleNotification(task.firstNotification!, scheduledTask, task);
    }

    if (task.secondNotification != null) {
      scheduleNotification(task.secondNotification!, scheduledTask, task);
    }

    final day = _getOrCreateDay(dateKey);
    day.scheduledTasks.add(scheduledTask);
    daysDB.put(dateKey, day);

    log('Scheduled task ${task.title} from $start to $end on $dateKey');
    return scheduledTask;
  }

  void scheduleNotification(
    int notificationTime,
    ScheduledTask scheduledTask,
    Task task,
  ) {
    DateTime notificationDate = scheduledTask.startTime.subtract(
      Duration(minutes: notificationTime),
    );

    var notificationKey = UniqueKey().hashCode;

    notiService.scheduleNotification(
      id: notificationKey,
      title: task.title,
      body:
          notificationTime != 0
              ? (notificationTime == 1
                  ? 'Will start in 1 minute'
                  : notificationTime == 5
                  ? 'Will start in 5 minutes'
                  : notificationTime == 15
                  ? 'Will start in 15 minutes'
                  : notificationTime == 30
                  ? 'Will start in 30 minutes'
                  : notificationTime == 60
                  ? 'Will start in 1 hour'
                  : notificationTime == 120
                  ? 'Will start in 2 hours'
                  : notificationTime == 1440
                  ? 'Will start in 1 day'
                  : notificationTime == 2880
                  ? 'Will start in 2 days'
                  : notificationTime == 10080
                  ? 'Will start in 1 week'
                  : 'Will start in $notificationTime minutes')
              : 'Will start now',
      year: notificationDate.year,
      month: notificationDate.month,
      day: notificationDate.day,
      hour: notificationDate.hour,
      minute: notificationDate.minute,
    );

    scheduledTask.addNotificationId(notificationKey);
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

  String formatDateKey(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  DateTime _combineDateKeyAndTimeOfDay(String dateKey, TimeOfDay timeOfDay) {
    final year = int.parse(dateKey.substring(0, 4));
    final month = int.parse(dateKey.substring(4, 6));
    final day = int.parse(dateKey.substring(6, 8));
    return DateTime(year, month, day, timeOfDay.hour, timeOfDay.minute);
  }
}
