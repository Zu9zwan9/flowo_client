import 'dart:developer';

import 'package:flowo_client/models/day.dart';
import 'package:flowo_client/models/scheduled_task_type.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:hive/hive.dart';

import '../models/scheduled_task.dart';

class TaskUrgencyCalculator {
  final Box<Day> daysDB;

  TaskUrgencyCalculator(this.daysDB);

  Map<Task, double> calculateUrgency(
    List<Task> tasks,
    List<ScheduledTask>? justScheduledTasks,
  ) {
    final Map<Task, double> taskUrgencyMap = {};

    for (var task in tasks) {
      log(
        'Title: ${task.title}, Deadline: ${task.deadline}, EstimatedTime: ${task.estimatedTime}, Priority: ${task.priority}',
      );
      final timeLeft = task.deadline - DateTime.now().millisecondsSinceEpoch;
      final trueTimeLeft =
          timeLeft - _busyTime(task.deadline, justScheduledTasks);
      final timeCoefficient =
          (trueTimeLeft - task.estimatedTime) *
          (trueTimeLeft + task.estimatedTime);
      double urgency = task.priority / timeCoefficient;

      if (urgency < 0) {
        _negativeUrgencyHandler(task, trueTimeLeft);
      } else {
        taskUrgencyMap[task] = urgency;
        logDebug('Task: ${task.title} has urgency $urgency');
      }
    }

    return taskUrgencyMap;
  }

  void _negativeUrgencyHandler(Task task, int trueTimeLeft) {
    final timeLeft = task.deadline - DateTime.now().millisecondsSinceEpoch;
    if (timeLeft - task.estimatedTime < 0) {
      logWarning(
        'Task ${task.title} is impossible to complete in time, estimated time: ${task.estimatedTime}, time left until deadline: $timeLeft',
      );

      // Add task to the list of impossible tasks
      _addImpossibleTask(task, timeLeft);
    } else {
      final timeNeeded = Duration(
        milliseconds: task.estimatedTime - trueTimeLeft,
      );
      final freeTime = Duration(milliseconds: trueTimeLeft);

      logWarning(
        'Task ${task.title} is possible to complete in time if rescheduled some tasks, time needed to complete: ${timeNeeded.inHours}h ${timeNeeded.inMinutes.remainder(60)}m, free time left: ${freeTime.inHours}h ${freeTime.inMinutes.remainder(60)}m',
      );

      // Add task to the list of tasks that need rescheduling
      _addTaskNeedingRescheduling(task, trueTimeLeft, timeNeeded, freeTime);
    }
  }

  // List of tasks that are impossible to complete in time
  final List<Task> _impossibleTasks = [];

  // List of tasks that need rescheduling
  final List<Task> _tasksNeedingRescheduling = [];

  // Get the list of tasks that are impossible to complete in time
  List<Task> getImpossibleTasks() {
    return List.unmodifiable(_impossibleTasks);
  }

  // Get the list of tasks that need rescheduling
  List<Task> getTasksNeedingRescheduling() {
    return List.unmodifiable(_tasksNeedingRescheduling);
  }

  // Clear the lists of tasks
  void clearTaskLists() {
    _impossibleTasks.clear();
    _tasksNeedingRescheduling.clear();
  }

  // Add a task to the list of impossible tasks
  void _addImpossibleTask(Task task, int timeLeft) {
    if (!_impossibleTasks.contains(task)) {
      _impossibleTasks.add(task);
    }
  }

  // Add a task to the list of tasks that need rescheduling
  void _addTaskNeedingRescheduling(
    Task task,
    int trueTimeLeft,
    Duration timeNeeded,
    Duration freeTime,
  ) {
    if (!_tasksNeedingRescheduling.contains(task)) {
      _tasksNeedingRescheduling.add(task);
    }
  }

  int _busyTime(int deadline, List<ScheduledTask>? justScheduledTasks) {
    int busyTime = 0;

    final now = DateTime.now().millisecondsSinceEpoch;

    // Filter days and tasks before the loop
    final relevantDays = daysDB.values.where(
      (day) => day.scheduledTasks.any(
        (task) =>
            (task.type == ScheduledTaskType.timeSensitive ||
                task.type == ScheduledTaskType.mealBreak ||
                task.type == ScheduledTaskType.rest ||
                task.type == ScheduledTaskType.sleep) &&
            task.startTime.millisecondsSinceEpoch >= now &&
            task.endTime.millisecondsSinceEpoch <= deadline,
      ),
    );

    for (var day in relevantDays) {
      for (var scheduledTask in day.scheduledTasks) {
        if ((scheduledTask.type == ScheduledTaskType.timeSensitive ||
                scheduledTask.type == ScheduledTaskType.mealBreak ||
                scheduledTask.type == ScheduledTaskType.rest ||
                scheduledTask.type == ScheduledTaskType.sleep) &&
            scheduledTask.startTime.millisecondsSinceEpoch >= now &&
            scheduledTask.endTime.millisecondsSinceEpoch <= deadline) {
          busyTime +=
              scheduledTask.endTime
                  .difference(scheduledTask.startTime)
                  .inMilliseconds;
        }
      }
    }

    if (justScheduledTasks != null) {
      for (var scheduledTask in justScheduledTasks) {
        if (scheduledTask.startTime.millisecondsSinceEpoch >= now &&
            scheduledTask.endTime.millisecondsSinceEpoch <= deadline) {
          busyTime +=
              scheduledTask.endTime
                  .difference(scheduledTask.startTime)
                  .inMilliseconds;
        }
      }
    }

    logDebug('busy time -> ${busyTime.toString()}');

    return busyTime;
  }
}
