import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/task.dart';

/// Represents an issue with scheduling a task
abstract class TaskSchedulingIssue {
  /// The task that has a scheduling issue
  final Task task;

  /// A message describing the issue
  final String message;

  TaskSchedulingIssue({required this.task, required this.message});
}

/// Represents a task that is impossible to complete in time
class ImpossibleTask extends TaskSchedulingIssue {
  /// The time left until the deadline in milliseconds
  final int timeLeft;

  /// The estimated time needed to complete the task in milliseconds
  final int estimatedTime;

  /// The suggested new deadline for the task
  DateTime get suggestedDeadline => DateTime.fromMillisecondsSinceEpoch(
    DateTime.now().millisecondsSinceEpoch + estimatedTime,
  );

  ImpossibleTask({
    required super.task,
    required this.timeLeft,
    required this.estimatedTime,
  }) : super(
         message:
             'Task ${task.title} is impossible to complete in time. '
             'Estimated time: ${Duration(milliseconds: estimatedTime).inHours}h '
             '${Duration(milliseconds: estimatedTime).inMinutes.remainder(60)}m, '
             'Time left: ${Duration(milliseconds: timeLeft).inHours}h '
             '${Duration(milliseconds: timeLeft).inMinutes.remainder(60)}m',
       );
}

/// Represents a task that needs rescheduling to be completed in time
class TaskNeedingRescheduling extends TaskSchedulingIssue {
  /// The true time left until the deadline in milliseconds (after accounting for busy time)
  final int trueTimeLeft;

  /// The time needed to complete the task in milliseconds
  final Duration timeNeeded;

  /// The free time left until the deadline in milliseconds
  final Duration freeTime;

  /// The list of tasks that can be rescheduled to make time for this task
  final List<ScheduledTask> reschedulableTasks;

  TaskNeedingRescheduling({
    required super.task,
    required this.trueTimeLeft,
    required this.timeNeeded,
    required this.freeTime,
    this.reschedulableTasks = const [],
  }) : super(
         message:
             'Task ${task.title} is possible to complete in time if some tasks are rescheduled. '
             'Time needed: ${timeNeeded.inHours}h ${timeNeeded.inMinutes.remainder(60)}m, '
             'Free time left: ${freeTime.inHours}h ${freeTime.inMinutes.remainder(60)}m',
       );
}
