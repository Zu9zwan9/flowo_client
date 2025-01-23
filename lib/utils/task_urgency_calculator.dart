import 'package:flowo_client/models/scheduled_task_type.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/models/days.dart';
import 'package:hive/hive.dart';

import '../models/scheduled_task.dart';

class TaskUrgencyCalculator {
  final Box<Day> daysDB;

  TaskUrgencyCalculator(this.daysDB);

  Map<Task, double> calculateUrgency(List<Task> tasks) {
    final Map<Task, double> taskUrgencyMap = {};

    for (var task in tasks) {
      final timeLeft = task.deadline - DateTime.now().millisecondsSinceEpoch;
      final trueTimeLeft = timeLeft - _busyTime(task.deadline);
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
      // message user that task is impossible to complete in time and should be rescheduled
      // messageUserAboutOverdue(task);
      // remove task or change deadline
    } else {
      // show user that task is possible to complete in time, only if reschedule
      // or remove some pinned tasks
    }
  }

  final List<ScheduledTask> _timeSensitiveTasksList = [];

  int _busyTime(int deadline) {
    int busyTime = 0;
    _timeSensitiveTasksList.clear();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var day in daysDB.values) {
      for (var scheduledTask in day.scheduledTasks) {
        if (scheduledTask.type == ScheduledTaskType.timeSensitive &&
            scheduledTask.startTime.millisecondsSinceEpoch >= now &&
            scheduledTask.endTime.millisecondsSinceEpoch <=
                deadline) {
          _timeSensitiveTasksList.add(scheduledTask);
          busyTime += scheduledTask.endTime
              .difference(scheduledTask.startTime)
              .inMilliseconds;
        }
      }
    }

    return busyTime;
  }
}
