import 'package:flowo_client/models/user_settings.dart';
import 'package:flowo_client/utils/scheduler.dart';
import 'package:flowo_client/utils/task_urgency_calculator.dart';
import 'package:hive/hive.dart';

import '../models/days.dart';
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
  })
      : scheduler = Scheduler(daysDB, tasksDB),
        taskUrgencyCalculator = TaskUrgencyCalculator(daysDB);

  void manageTasks() {
    List<Task> tasks = tasksDB.values.toList();
    while (tasks.isNotEmpty) {
      final Map<Task, double> taskUrgencyMap = taskUrgencyCalculator
          .calculateUrgency(tasks);
      final Task mostUrgentTask = taskUrgencyMap.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      scheduler.scheduleTask(mostUrgentTask, taskUrgencyMap[mostUrgentTask]!, userSettings.minSession);
      tasks.remove(mostUrgentTask);
    }
  }

  // TODO: Implement habit scheduling logic
}

