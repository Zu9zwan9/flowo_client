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
    int? firstNotification,
    int? secondNotification,
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
    task.firstNotification = firstNotification;
    task.secondNotification = secondNotification;
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
    // This method is deprecated. Use TaskManagerCubit.scheduleHabits instead.
    // The TaskManagerCubit.scheduleHabits method handles the scheduling of habits
    // with proper conflict resolution using BuildContext.
    logWarning(
      'TaskManager.manageHabits is deprecated. Use TaskManagerCubit.scheduleHabits instead.',
    );
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
