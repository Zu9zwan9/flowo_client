import 'dart:developer';

import 'package:flowo_client/models/day.dart';
import 'package:flowo_client/models/scheduled_task_type.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/services/notification_manager.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:hive/hive.dart';

import '../models/scheduled_task.dart';

class TaskUrgencyCalculator {
  final Box<Day> daysDB;
  final NotificationManager? notificationManager;

  TaskUrgencyCalculator(this.daysDB, {this.notificationManager});

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
        _negativeUrgencyHandler(task);
      } else {
        taskUrgencyMap[task] = urgency;
        log('Task: ${task.title} has urgency $urgency');
      }
    }

    return taskUrgencyMap;
  }

  void _negativeUrgencyHandler(Task task) {
    final timeLeft = task.deadline - DateTime.now().millisecondsSinceEpoch;
    if (timeLeft - task.estimatedTime < 0) {
      log('Task ${task.title} is impossible to complete in time');
      // Notify user that task is impossible to complete in time and should be rescheduled
      if (notificationManager != null) {
        notificationManager!.notifyTaskImpossibleToComplete(task);
      }
    } else {
      log('Task ${task.title} is possible to complete in time if rescheduled');
      // Notify user that task is possible to complete in time if rescheduled or some pinned tasks are removed
      if (notificationManager != null) {
        notificationManager!.notifyTaskPossibleIfRescheduled(task);
      }
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
