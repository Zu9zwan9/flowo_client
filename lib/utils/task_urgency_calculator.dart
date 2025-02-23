import 'package:flowo_client/models/day.dart';
import 'package:flowo_client/models/scheduled_task_type.dart';
import 'package:flowo_client/models/task.dart';
import 'package:hive/hive.dart';

import '../models/scheduled_task.dart';

class TaskUrgencyCalculator {
  final Box<Day> daysDB;

  TaskUrgencyCalculator(this.daysDB);

  Map<Task, double> calculateUrgency(
      List<Task> tasks, List<ScheduledTask>? justScheduledTasks) {
    final Map<Task, double> taskUrgencyMap = {};

    for (var task in tasks) {
      final timeLeft = task.deadline - DateTime.now().millisecondsSinceEpoch;
      final trueTimeLeft =
          timeLeft - _busyTime(task.deadline, justScheduledTasks);
      final timeCoefficient = (trueTimeLeft - task.estimatedTime) *
          (trueTimeLeft + task.estimatedTime);
      double urgency = task.priority / timeCoefficient;

      if (urgency < 0) {
        _negativeUrgencyHandler(task);
      } else {
        taskUrgencyMap[task] = urgency;
      }
    }

    return taskUrgencyMap;
  }

  void _negativeUrgencyHandler(Task task) {
    final timeLeft = task.deadline - DateTime.now().millisecondsSinceEpoch;
    if (timeLeft - task.estimatedTime < 0) {
      // TODO: message user that task is impossible to complete in time and should be rescheduled
      // messageUserAboutOverdue(task);
      // remove task or change deadline
    } else {
      // show user that task is possible to complete in time, only if reschedule
      // or remove some pinned tasks //
    }
  }

  int _busyTime(int deadline, List<ScheduledTask>? justScheduledTasks) {
    int busyTime = 0;

    final now = DateTime.now().millisecondsSinceEpoch;

    // Filter days and tasks before the loop
    final relevantDays = daysDB.values.where((day) => day.scheduledTasks.any(
        (task) =>
            task.type == ScheduledTaskType.timeSensitive &&
            task.startTime.millisecondsSinceEpoch >= now &&
            task.endTime.millisecondsSinceEpoch <= deadline));

    for (var day in relevantDays) {
      for (var scheduledTask in day.scheduledTasks) {
        if (scheduledTask.type == ScheduledTaskType.timeSensitive &&
            scheduledTask.startTime.millisecondsSinceEpoch >= now &&
            scheduledTask.endTime.millisecondsSinceEpoch <= deadline) {
          busyTime += scheduledTask.endTime
              .difference(scheduledTask.startTime)
              .inMilliseconds;
        }
      }
    }

    if (justScheduledTasks != null) {
      for (var scheduledTask in justScheduledTasks) {
        if (scheduledTask.startTime.millisecondsSinceEpoch >= now &&
            scheduledTask.endTime.millisecondsSinceEpoch <= deadline) {
          busyTime += scheduledTask.endTime
              .difference(scheduledTask.startTime)
              .inMilliseconds;
        }
      }
    }

    return busyTime;
  }
}
