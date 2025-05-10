import 'dart:developer';

import 'package:flowo_client/models/user_settings.dart';
import 'package:flowo_client/utils/ai_model/task_breakdown_api.dart';
import 'package:flowo_client/utils/ai_model/task_estimator_api.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flowo_client/utils/scheduler.dart';
import 'package:flowo_client/utils/task_urgency_calculator.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

import '../models/category.dart';
import '../models/day.dart';
import '../models/repeat_rule.dart';
import '../models/repeat_rule_instance.dart';
import '../models/scheduled_task.dart';
import '../models/scheduled_task_type.dart';
import '../models/task.dart';
import '../models/task_session.dart';

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
         apiKey:
             huggingFaceApiKey ??
             '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',
       ),
       taskEstimatorAPI = TaskEstimatorAPI(
         apiKey:
             huggingFaceApiKey ??
             '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',
       );

  void updateUserSettings(UserSettings userSettings) {
    logInfo('Updating TaskManager user settings');
    this.userSettings = userSettings;
    scheduler.updateUserSettings(userSettings);
    scheduler.createDaysUntil(
      DateTime(DateTime.now().year, DateTime.now().month + 3),
    );
    logDebug('User settings updated');
  }

  Task createTask(
    String title,
    int priority,
    int estimatedTime,
    int deadline,
    Category category, {
    Task? parentTask,
    String? notes,
    int? order,
    int? color,
    RepeatRule? frequency,
    int? optimisticTime,
    int? realisticTime,
    int? pessimisticTime,
    int? firstNotification,
    int? secondNotification,
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
      optimisticTime: optimisticTime,
      realisticTime: realisticTime,
      pessimisticTime: pessimisticTime,
      firstNotification: firstNotification,
      secondNotification: secondNotification,
    );

    tasksDB.put(task.id, task);
    if (parentTask != null) {
      task.parentTask = parentTask;
      parentTask.subtaskIds.add(task.id);
      tasksDB.put(parentTask.id, parentTask);
    }
    logInfo('Created task: ${task.title}');

    if (task.frequency != null) {
      logInfo('Created habit: ${task.toString()}');
    }

    scheduler.createDaysUntil(DateTime.fromMillisecondsSinceEpoch(deadline));

    return task;
  }

  void deleteTaskById(String taskId) {
    final task = tasksDB.get(taskId);
    if (task == null) {
      logWarning('Task with id $taskId not found');
      return;
    }

    tasksDB.delete(task.id);
    final parentTask = task.parentTask;
    if (parentTask != null) {
      parentTask.subtaskIds.remove(task.id);
      tasksDB.put(parentTask.id, parentTask);
    }
    for (var subtaskId in task.subtaskIds) {
      deleteTaskById(subtaskId);
    }
    for (var scheduledTask in List.from(task.scheduledTasks)) {
      for (var day in daysDB.values) {
        if (day.scheduledTasks.contains(scheduledTask)) {
          day.scheduledTasks.remove(scheduledTask);
          daysDB.put(day.day, day);
        }
      }

      for (var notificationId in scheduledTask.notificationIds) {
        scheduler.notiService.cancelNotification(notificationId);
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
    int? order,
    RepeatRule? frequency,
    int? optimisticTime,
    int? realisticTime,
    int? pessimisticTime,
    int? firstNotification,
    int? secondNotification,
  }) {
    task.title = title;
    task.priority = priority;
    task.estimatedTime = estimatedTime;
    task.deadline = deadline;
    task.category = category;
    task.parentTask = parentTask;
    if (order != null) {
      task.order = order;
    }
    if (notes != null) {
      task.notes = notes;
    }
    if (color != null) {
      task.color = color;
    }
    if (frequency != null) {
      task.frequency = frequency;
    }
    if (optimisticTime != null) {
      task.optimisticTime = optimisticTime;
    }
    if (realisticTime != null) {
      task.realisticTime = realisticTime;
    }
    if (pessimisticTime != null) {
      task.pessimisticTime = pessimisticTime;
    }
    task.firstNotification = firstNotification;
    task.secondNotification = secondNotification;
    tasksDB.put(task.id, task);
    logInfo('Edited task: ${task.title}');
  }

  void manageTasks() {
    removeScheduledTasks(); // TODO: check if this works correctly
    final tasks =
        tasksDB.values
            .where((task) => task.frequency == null && task.subtaskIds.isEmpty)
            .where((task) => task.id != 'free_time_manager')
            .where(
              (task) => !task.category.name.toLowerCase().contains('event'),
            )
            .toList();

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

  void manageEvents() {
    // restoring events if they deleted from daysDB
    final events =
        tasksDB.values
            .where((task) => task.category.name.toLowerCase().contains('event'))
            .toList();

    for (Task event in events) {
      if (event.scheduledTasks.isNotEmpty) {
        for (var scheduledTask in event.scheduledTasks) {
          final day = daysDB.get(
            scheduler.formatDateKey(scheduledTask.startTime),
          );
          if (day != null) {
            day.scheduledTasks.add(scheduledTask);
            daysDB.put(day.day, day);
          } else {
            logWarning('Day $day not found');
          }
        }
      } else {
        logWarning('Event ${event.title} has no scheduled tasks');
      }
    }
  }

  void manageHabits() {
    List<Task> habits =
        tasksDB.values.where((task) => task.frequency != null).toList();

    for (Task habit in habits) {
      switch (habit.frequency!.type) {
        case 'weekly':
          RepeatRule repeatRule = habit.frequency!;
          List<RepeatRuleInstance> byDay = repeatRule.byDay!;

          for (var dayInstance in byDay) {
            final selectedWeekday = _dayNameToInt(dayInstance.selectedDay);
            final startDate = repeatRule.startRepeat;
            final daysUntilNextSelectedDay =
                (selectedWeekday - startDate.weekday + 7) % 7;

            var nextSelectedDate = startDate.add(
              Duration(days: daysUntilNextSelectedDay),
            );

            List<DateTime> habitDates = [];

            while (nextSelectedDate.isBefore(repeatRule.endRepeat!)) {
              habitDates.add(nextSelectedDate);
              nextSelectedDate = nextSelectedDate.add(
                Duration(days: 7 * habit.frequency!.interval),
              );
            }

            scheduler.scheduleHabit(
              habit,
              habitDates,
              dayInstance.start,
              dayInstance.end,
            );
          }
          break;

        case 'monthly':
          RepeatRule repeatRule = habit.frequency!;

          // Проверяем, есть ли byMonthDay (specific days) или bySetPos (pattern)
          if (repeatRule.byMonthDay != null) {
            // Обработка для "specific days"
            List<RepeatRuleInstance> byMonthDay = repeatRule.byMonthDay!;

            for (var monthDayInstance in byMonthDay) {
              final selectedMonthDay = int.parse(monthDayInstance.selectedDay);
              final startDate = repeatRule.startRepeat;
              final daysUntilNextSelectedDay =
                  (selectedMonthDay -
                      startDate.day +
                      DateTime(startDate.year, startDate.month + 1, 0).day) %
                  DateTime(startDate.year, startDate.month + 1, 0).day;
              var nextSelectedDate = startDate.add(
                Duration(days: daysUntilNextSelectedDay),
              );

              List<DateTime> habitDates = [];

              while (nextSelectedDate.isBefore(repeatRule.endRepeat!)) {
                habitDates.add(nextSelectedDate);
                nextSelectedDate = DateTime(
                  nextSelectedDate.year,
                  nextSelectedDate.month + habit.frequency!.interval,
                  selectedMonthDay,
                );
              }

              scheduler.scheduleHabit(
                habit,
                habitDates,
                monthDayInstance.start,
                monthDayInstance.end,
              );
            }
          } else if (repeatRule.bySetPos != null) {
            // Обработка для "pattern"
            final bySetPos = repeatRule.bySetPos!;
            final byDay = repeatRule.byDay!;
            final interval = repeatRule.interval;
            final startDate = repeatRule.startRepeat;
            final endDate = repeatRule.endRepeat!;

            for (var dayInstance in byDay) {
              final selectedWeekday = _dayNameToInt(dayInstance.selectedDay);
              List<DateTime> habitDates = [];

              var currentDate = DateTime(startDate.year, startDate.month, 1);

              while (currentDate.isBefore(endDate)) {
                DateTime? patternDate = _findPatternDateInMonth(
                  currentDate.year,
                  currentDate.month,
                  selectedWeekday,
                  bySetPos,
                );

                if (patternDate != null &&
                    !patternDate.isBefore(startDate) &&
                    patternDate.isBefore(endDate)) {
                  habitDates.add(patternDate);
                }

                currentDate = DateTime(
                  currentDate.year,
                  currentDate.month + interval,
                  1,
                );
              }

              scheduler.scheduleHabit(
                habit,
                habitDates,
                dayInstance.start,
                dayInstance.end,
              );
            }
          }
          break;

        case 'daily':
          List<DateTime> habitDates = [];
          DateTime startDate = habit.frequency!.startRepeat;

          while (startDate.isBefore(habit.frequency!.endRepeat!)) {
            habitDates.add(startDate);
            startDate = startDate.add(
              Duration(days: habit.frequency!.interval),
            );
          }

          scheduler.scheduleHabit(
            habit,
            habitDates,
            habit.frequency!.byDay!.first.start,
            habit.frequency!.byDay!.first.end,
          );
          break;

        case 'yearly':
          List<DateTime> habitDates = [];
          DateTime startDate = habit.frequency!.startRepeat;

          while (startDate.isBefore(habit.frequency!.endRepeat!)) {
            habitDates.add(startDate);
            startDate = DateTime(
              startDate.year + habit.frequency!.interval,
              startDate.month,
              startDate.day,
            );
          }

          scheduler.scheduleHabit(
            habit,
            habitDates,
            habit.frequency!.byDay!.first.start,
            habit.frequency!.byDay!.first.end,
          );
          break;

        default:
          logWarning('Invalid habit frequency type: ${habit.frequency!.type}');
          break;
      }
    }
  }

  DateTime? _findPatternDateInMonth(
    int year,
    int month,
    int targetWeekday,
    int bySetPos,
  ) {
    DateTime firstDayOfMonth = DateTime(year, month, 1);
    DateTime lastDayOfMonth = DateTime(year, month + 1, 0);

    int daysUntilFirstTargetDay =
        (targetWeekday - firstDayOfMonth.weekday + 7) % 7;
    DateTime firstTargetDay = firstDayOfMonth.add(
      Duration(days: daysUntilFirstTargetDay),
    );

    if (bySetPos == -1) {
      DateTime lastTargetDay = firstTargetDay;
      while (lastTargetDay.month == month) {
        DateTime nextTargetDay = lastTargetDay.add(Duration(days: 7));
        if (nextTargetDay.month != month) break;
        lastTargetDay = nextTargetDay;
      }
      return lastTargetDay;
    } else {
      int targetWeek = bySetPos - 1;
      DateTime targetDate = firstTargetDay.add(Duration(days: 7 * targetWeek));

      if (targetDate.month == month && targetDate.day <= lastDayOfMonth.day) {
        return targetDate;
      }
      return null;
    }
  }

  bool _isOrderCorrect(Task task) {
    if (task.order == null || task.order! <= 1 || task.parentTask == null) {
      return true;
    }

    final parentTask = tasksDB.get(task.parentTaskId);
    final parentSubtasks =
        tasksDB.values
            .where((t) => parentTask?.subtaskIds.contains(t.id) ?? false)
            .toList();

    for (var subtask in parentSubtasks) {
      if (subtask.order! < task.order! && subtask.scheduledTasks.isEmpty) {
        return false;
      }
    }

    return true;
  }

  void removeScheduledTasks() {
    for (var day in daysDB.values) {
      // final dayDate = DateTime.parse(day.day); //TODO: update this later
      // if (dayDate.isBefore(now)) continue;

      final toRemove =
          day.scheduledTasks
              .where((st) => st.type == ScheduledTaskType.defaultType)
              .toList();

      if (toRemove.isEmpty) continue;

      logInfo(
        'Removing ${toRemove.length} scheduled tasks from day ${day.day}',
      );
      for (var scheduledTask in toRemove) {
        day.scheduledTasks.removeWhere(
          (st) => st.scheduledTaskId == scheduledTask.scheduledTaskId,
        );

        final task = tasksDB.get(scheduledTask.parentTaskId);
        if (task != null) {
          task.scheduledTasks.removeWhere(
            (st) => st.scheduledTaskId == scheduledTask.scheduledTaskId,
          );

          tasksDB.put(task.id, task);
        } else {
          logWarning('Task with id ${scheduledTask.scheduledTaskId} not found');
        }

        for (var notificationId in scheduledTask.notificationIds) {
          scheduler.notiService.cancelNotification(notificationId);
        }
      }
      daysDB.put(day.day, day);
    }
    logInfo('Removed all scheduled tasks');
  }

  void removeScheduledTasksFor(Task task) {
    for (var day in daysDB.values) {
      final toRemove =
          day.scheduledTasks.where((st) => st.parentTaskId == task.id).toList();
      for (var scheduledTask in toRemove) {
        day.scheduledTasks.remove(scheduledTask);
        task.scheduledTasks.remove(scheduledTask);
      }
      daysDB.put(day.day, day);
    }
    tasksDB.put(task.id, task);
    logInfo('Removed scheduled tasks for ${task.title}');
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
    return dayMap[dayName.toLowerCase()] ?? 1;
  }

  Future<List<Task>> breakdownAndScheduleTask(Task task) async {
    logInfo('Breaking down task: ${task.title} ${task.estimatedTime}');

    final subtaskDataList = await taskBreakdownAPI.breakdownTask(
      task.title,
      task.estimatedTime.toString(),
    );

    if (subtaskDataList.isEmpty) {
      logWarning('No subtasks generated for task: ${task.title}');
      return [];
    }

    logInfo('Generated ${subtaskDataList.length} subtasks for: ${task.title}');

    final subtasks = <Task>[];
    int order = 1;

    for (var subtaskData in subtaskDataList) {
      final subtaskTitle = subtaskData['title'] as String;
      final estimatedTime = subtaskData['estimatedTime'] as int;

      final subtask = Task(
        id: UniqueKey().toString(),
        title: subtaskTitle,
        priority: task.priority,
        estimatedTime: estimatedTime,
        deadline: task.deadline,
        category: task.category,
        color: task.color,
        parentTask: task,
        order: order++,
        firstNotification: task.firstNotification,
        secondNotification: task.secondNotification,
      );
      tasksDB.put(subtask.id, subtask);
      subtasks.add(subtask);
      task.subtaskIds.add(subtask.id);
    }

    manageTasks();

    return subtasks;
  }

  /// Starts a task or subtask
  /// If the task has subtasks and they're not all completed, it can't be started
  /// Returns true if the task was started successfully, false otherwise
  bool startTask(Task task) {
    if (!task.canStart) {
      logWarning(
        'Cannot start task ${task.title} because it has incomplete subtasks',
      );
      return false;
    }

    task.start();
    tasksDB.put(task.id, task);
    logInfo('Started task: ${task.title}');
    return true;
  }

  /// Pauses a task that's in progress
  /// Returns true if the task was paused successfully, false otherwise
  bool pauseTask(Task task) {
    if (!task.isInProgress) {
      logWarning(
        'Cannot pause task ${task.title} because it is not in progress',
      );
      return false;
    }

    task.pause();
    tasksDB.put(task.id, task);
    logInfo('Paused task: ${task.title}');
    return true;
  }

  /// Stops a task that's in progress or paused
  /// Returns true if the task was stopped successfully, false otherwise
  bool stopTask(Task task) {
    if (!task.isInProgress && !task.isPaused) {
      logWarning(
        'Cannot stop task ${task.title} because it is not in progress or paused',
      );
      return false;
    }

    task.stop();
    tasksDB.put(task.id, task);
    logInfo('Stopped task: ${task.title}');
    return true;
  }

  /// Completes a task
  /// If the task has a parent task, it checks if all siblings are completed
  /// and if so, it marks the parent task as completed too
  /// Returns true if the task was completed successfully, false otherwise
  bool completeTask(Task task) {
    task.complete();
    tasksDB.put(task.id, task);
    logInfo('Completed task: ${task.title}');

    // Check if parent task should be completed too
    final parentTask = task.parentTask;
    if (parentTask != null) {
      if (parentTask.subtaskIds.every(
        (subtaskId) => tasksDB.get(subtaskId)!.isDone,
      )) {
        completeTask(parentTask);
      }
    }

    return true;
  }

  /// Gets all task sessions for a task and its subtasks
  List<TaskSession> getTaskSessions(Task task) {
    List<TaskSession> allSessions = List.from(task.sessions);

    // Add sessions from subtasks
    for (var subtaskId in task.subtaskIds) {
      final subtask = tasksDB.get(subtaskId);
      if (subtask != null) {
        allSessions.addAll(getTaskSessions(subtask));
      }
    }

    return allSessions;
  }

  /// Gets the total duration for a task and its subtasks
  int getTotalDuration(Task task) {
    int total = task.getTotalDuration();

    // Add duration from subtasks
    for (var subtaskId in task.subtaskIds) {
      final subtask = tasksDB.get(subtaskId);
      if (subtask != null) {
        total += getTotalDuration(subtask);
      }
    }

    return total;
  }

  /// Gets all tasks that are currently in progress
  List<Task> getTasksInProgress() {
    return tasksDB.values.where((task) => task.isInProgress).toList();
  }

  /// Gets all tasks that are currently paused
  List<Task> getPausedTasks() {
    return tasksDB.values.where((task) => task.isPaused).toList();
  }
}
