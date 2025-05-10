
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
      final timeLeft = task.deadline - DateTime.now().millisecondsSinceEpoch;
      final trueTimeLeft =
          timeLeft - busyTime(task.deadline, justScheduledTasks);
      final timeCoefficient =
          (trueTimeLeft - task.estimatedTime) *
          (trueTimeLeft + task.estimatedTime);
      double urgency = task.priority / timeCoefficient;

      if (urgency < 0) {
        _negativeUrgencyHandler(task, trueTimeLeft);
      } else {
        taskUrgencyMap[task] = urgency;
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
      // TODO: Notify user that task is impossible to complete in time and deadline should be pushed back
    } else {
      logWarning(
        'Task ${task.title} is possible to complete in time if rescheduled some tasks, time needed to complete: ${Duration(milliseconds: task.estimatedTime - trueTimeLeft).inHours}h ${Duration(milliseconds: task.estimatedTime - trueTimeLeft).inMinutes.remainder(60)}m, free time left: ${Duration(milliseconds: trueTimeLeft).inHours}h ${Duration(milliseconds: trueTimeLeft).inMinutes.remainder(60)}m',
      ); // TODO: Передавати кількість часу, скільки не вистачає до дедлайну і вказувати скільки можна зекономити завдяки зменшенню вільного часу
      // TODO: Give a choice to user with a list of tasks that can be rescheduled(move/delete/edit (CRUD))
      // TODO: Implement a way to notify user that task is possible to complete in time if rescheduled some tasks. And return a list of tasks that can be removed
    }
  }

  int busyTime(int deadline, List<ScheduledTask>? justScheduledTasks) {
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

    return busyTime;
  }
}
