import 'package:flowo_client/models/user_settings.dart';
import 'package:flowo_client/utils/scheduler.dart';
import 'package:flowo_client/utils/task_urgency_calculator.dart';
import 'package:hive/hive.dart';

import '../models/days.dart';
import '../models/repeat_rule.dart';
import '../models/task.dart';

class TaskManager {
  final Scheduler scheduler;
  final TaskUrgencyCalculator taskUrgencyCalculator;
  final UserSettings userSettings;
  final Box<Days> daysDB;
  final Box<Task> tasksDB;

  TaskManager({
    required this.daysDB,
    required this.tasksDB,
    required this.userSettings,
  })  : scheduler = Scheduler(daysDB, tasksDB),
        taskUrgencyCalculator = TaskUrgencyCalculator(daysDB);

  void manageTasks() {
    List<Task> tasks = tasksDB.values
        .where((task) => task.frequency == null || task.frequency!.isEmpty)
        .toList();
    while (tasks.isNotEmpty) {
      final Map<Task, double> taskUrgencyMap =
          taskUrgencyCalculator.calculateUrgency(tasks);
      final Task mostUrgentTask = taskUrgencyMap.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      scheduler.scheduleTask(mostUrgentTask, userSettings.minSession, urgency: taskUrgencyMap[mostUrgentTask]);
      tasks.remove(mostUrgentTask);
    }
  }

  void manageHabits() {
    List<Task> habits = tasksDB.values
        .where((task) => task.frequency != null && task.frequency!.isNotEmpty)
        .toList();

    for (Task habit in habits) {
      List<DateTime> scheduledDates = _calculateHabitDates(habit);

      for (DateTime date in scheduledDates) {
        scheduler.scheduleTask(
          habit,
          userSettings.minSession,
          availableDates: [date.toIso8601String().split('T').first],
        );
      }
    }
  }

  List<DateTime> _calculateHabitDates(Task habit) {
    List<DateTime> dates = [];
    DateTime currentDate = habit.startDate;
    DateTime endDate = habit.endDate ??
        DateTime.now()
            .add(Duration(days: 365)); // Default to 1 year if no end date
    RepeatRule rule = habit.repeatRule;

    while (currentDate.isBefore(endDate)) {
      if (!_isExceptionDate(habit, currentDate) &&
          !_isCompletedDate(habit, currentDate)) {
        dates.add(currentDate);
      }

      currentDate = _getNextDate(currentDate, rule);
    }

    return dates;
  }

  bool _isExceptionDate(Task habit, DateTime date) {
    return habit.exceptions.contains(date);
  }

  bool _isCompletedDate(Task habit, DateTime date) {
    return habit.scheduledTask
        .any((scheduledTask) => scheduledTask.startTime.isAtSameMomentAs(date));
  }

  DateTime _getNextDate(DateTime currentDate, RepeatRule rule) {
    // TODO: work on implementing daysOfWeek, daysOfMonth, weekOfMonth
    switch (rule.frequency) {
      case 'daily':
        return currentDate.add(Duration(days: rule.interval));
      case 'weekly':
        return currentDate.add(Duration(days: 7 * rule.interval));
      case 'monthly':
        return DateTime(currentDate.year, currentDate.month + rule.interval,
            currentDate.day);
      case 'yearly':
        return DateTime(currentDate.year + rule.interval, currentDate.month,
            currentDate.day);
      default:
        throw ArgumentError('Invalid frequency: ${rule.frequency}');
    }
  }
}
