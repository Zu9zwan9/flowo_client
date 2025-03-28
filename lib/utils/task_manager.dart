import 'dart:developer';

import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/user_settings.dart';
import 'package:flowo_client/utils/ai_model/task_breakdown_api.dart';
import 'package:flowo_client/utils/ai_model/task_estimator_api.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flowo_client/utils/scheduler.dart';
import 'package:flowo_client/utils/task_urgency_calculator.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

import '../models/day.dart';
import '../models/repeat_rule.dart';
import '../models/repeat_rule_instance.dart';
import '../models/scheduled_task_type.dart';
import '../models/task.dart';

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
         apiKey: huggingFaceApiKey ?? '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',
       ),
       taskEstimatorAPI = TaskEstimatorAPI(
         apiKey: huggingFaceApiKey ?? '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',
       );

  void updateUserSettings(UserSettings userSettings) {
    logInfo('Updating TaskManager user settings');
    this.userSettings = userSettings;
    scheduler.updateUserSettings(userSettings);
  }

  Task createTask(
    String title,
    int priority,
    int estimatedTime,
    int deadline,
    Category category, {
    Task? parentTask,
    String? notes,
    int? color,
    RepeatRule? frequency,
    int? optimisticTime,
    int? realisticTime,
    int? pessimisticTime,
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
    );
    tasksDB.put(task.id, task);
    if (parentTask != null) {
      task.parentTask = parentTask;
      parentTask.subtasks.add(task);
      tasksDB.put(parentTask.id, parentTask);
    }
    logInfo('Created task: ${task.title}');

    if (task.frequency != null) {
      logInfo('Created habit: ${task.toString()}');
    }

    return task;
  }

  void deleteTask(Task task) {
    tasksDB.delete(task.id);
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
    RepeatRule? frequency,
    int? optimisticTime,
    int? realisticTime,
    int? pessimisticTime,
  }) {
    task.title = title;
    task.priority = priority;
    task.estimatedTime = estimatedTime;
    task.deadline = deadline;
    task.category = category;
    task.parentTask = parentTask;
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
    tasksDB.put(task.id, task);
    logInfo('Edited task: ${task.title}');
  }

  void scheduleTasks() {
    final tasks =
        tasksDB.values
            .where((task) => task.frequency == null && task.subtasks.isEmpty)
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
    // Числовое представление дня недели (1 = понедельник, ..., 7 = воскресенье)
    int bySetPos,
    // Позиция недели (1 = первая, 2 = вторая, ..., -1 = последняя)
  ) {
    // Создаём дату для первого дня месяца
    DateTime firstDayOfMonth = DateTime(year, month, 1);
    DateTime lastDayOfMonth = DateTime(
      year,
      month + 1,
      0,
    ); // Последний день месяца

    // Находим первый день, соответствующий targetWeekday
    int daysUntilFirstTargetDay =
        (targetWeekday - firstDayOfMonth.weekday + 7) % 7;
    DateTime firstTargetDay = firstDayOfMonth.add(
      Duration(days: daysUntilFirstTargetDay),
    );

    if (bySetPos == -1) {
      // Для "последнего" дня недели в месяце
      DateTime lastTargetDay = firstTargetDay;
      while (lastTargetDay.month == month) {
        DateTime nextTargetDay = lastTargetDay.add(Duration(days: 7));
        if (nextTargetDay.month != month) break;
        lastTargetDay = nextTargetDay;
      }
      return lastTargetDay;
    } else {
      // Для "первой", "второй", "третьей" или "четвёртой" недели
      int targetWeek = bySetPos - 1; // bySetPos начинается с 1, а нам нужно с 0
      DateTime targetDate = firstTargetDay.add(Duration(days: 7 * targetWeek));

      // Проверяем, что дата всё ещё в пределах месяца
      if (targetDate.month == month && targetDate.day <= lastDayOfMonth.day) {
        return targetDate;
      }
      return null; // Если паттерн не применим (например, "пятая пятница" в месяце, где только 4 пятницы)
    }
  }

  bool _isOrderCorrect(Task task) {
    if (task.order != null && task.order! > 0 && task.parentTask != null) {
      return !task.parentTask!.subtasks.any(
        (subtask) =>
            subtask.order != null &&
            subtask.order! < task.order! &&
            subtask.scheduledTasks.isEmpty,
      );
    }
    return true;
  }

  void removeScheduledTasks() {
    final now = DateTime.now();
    for (var day in daysDB.values) {
      final dayDate = DateTime.parse(day.day);
      if (dayDate.isBefore(now)) continue;

      final toRemove =
          day.scheduledTasks
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
    return dayMap[dayName.toLowerCase()] ?? 1; // Default to Monday if invalid
    /// TODO fix potential error with monday
  }

  Future<List<Task>> breakdownAndScheduleTask(Task task) async {
    logInfo('Breaking down task: ${task.title} ${task.estimatedTime}');

    // Изменяем тип с List<String> на List<Map<String, dynamic>>
    final subtaskDataList = await taskBreakdownAPI.breakdownTask(
      task.title,
      task.estimatedTime.toString(),
    );

    if (subtaskDataList.isEmpty) {
      logWarning('No subtasks generated for task: ${task.title}');
      logInfo('Scheduling parent task: ${task.title}');
      scheduler.scheduleTask(task, userSettings.minSession, urgency: null);
      return [];
    }

    logInfo('Generated ${subtaskDataList.length} subtasks for: ${task.title}');

    final subtasks = <Task>[];
    int order = 1;

    for (var subtaskData in subtaskDataList) {
      // Извлекаем title и estimatedTime из Map
      final subtaskTitle = subtaskData['title'] as String;
      final estimatedTime = subtaskData['estimatedTime'] as int;

      final subtask = Task(
        id: UniqueKey().toString(),
        title: subtaskTitle,
        priority: task.priority,
        estimatedTime: estimatedTime,
        deadline: task.deadline,
        category: task.category,
        parentTask: task,
        order: order++,
      );
      tasksDB.put(subtask.id, subtask);
      subtasks.add(subtask);
      task.subtasks.add(subtask);
    }

    tasksDB.put(task.id, task);
    scheduleSubtasks(subtasks);

    return subtasks;
  }

  void scheduleSubtasks(List<Task> subtasks) {
    logInfo('Scheduling ${subtasks.length} subtasks');
    subtasks.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    for (var subtask in subtasks) {
      scheduler.scheduleTask(subtask, userSettings.minSession, urgency: null);
      logInfo('Scheduled subtask: ${subtask.title}');
    }
  }
}
