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
      scheduler.scheduleTask(mostUrgentTask, userSettings.minSession,
          urgency: taskUrgencyMap[mostUrgentTask]);
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
    RepeatRule repeatRule = habit.repeatRule;

    while (
        (repeatRule.until != null && currentDate.isBefore(repeatRule.until!)) ||
            (repeatRule.count != null && dates.length < repeatRule.count!) ||
            (repeatRule.until == null &&
                repeatRule.count == null &&
                currentDate
                    .isBefore(DateTime.now().add(Duration(days: 365 * 3))))) {
      switch (repeatRule.frequency) {
        case 'daily':
          dates.add(currentDate);
          currentDate = currentDate.add(Duration(days: repeatRule.interval));
          break;
        case 'weekly':
          if (repeatRule.byDay != null &&
              repeatRule.byDay!.contains(currentDate.weekday % 7)) {
            dates.add(currentDate);
          }
          currentDate = currentDate.add(Duration(days: 1));
          break;
        case 'monthly':
          if (repeatRule.byMonthDay != null) {
            if (repeatRule.byMonthDay!.contains(currentDate.day)) {
              dates.add(currentDate);
            } else if (repeatRule.byMonthDay!.contains(-currentDate.day)) {
              DateTime lastDayOfMonth =
                  DateTime(currentDate.year, currentDate.month + 1, 0);
              int dayFromEnd = lastDayOfMonth.day +
                  repeatRule.byMonthDay!.firstWhere((day) => day < 0) +
                  1;
              if (currentDate.day == dayFromEnd) {
                dates.add(currentDate);
              }
            }
          }
          if (repeatRule.bySetPos != null &&
              (currentDate.day - 1) ~/ 7 + 1 == repeatRule.bySetPos) {
            dates.add(currentDate); //To review (31-1 ~/7 + 1 = 5)
          }
          currentDate = DateTime(currentDate.year,
              currentDate.month + repeatRule.interval, currentDate.day);
          break;
        case 'yearly':
          dates.add(currentDate);
          currentDate = DateTime(currentDate.year + repeatRule.interval,
              currentDate.month, currentDate.day);
          break;
        default:
          throw ArgumentError('Invalid frequency: ${repeatRule.frequency}');
      }
    }

    return dates;
  }
}
