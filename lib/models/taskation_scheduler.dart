import 'package:flowo_client/models/notification_type.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/scheduled_task_type.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/utils/logger.dart';

/// A scheduler that estimates and schedules tasks based on their content and context.
///
/// The TaskationScheduler uses AI to estimate how long tasks will take and
/// schedules them accordingly, optimizing for user productivity and task completion.
class TaskationScheduler {
  /// Estimates the time required to complete a task based on its content and context.
  ///
  /// Returns the estimated time in minutes.
  int estimateTaskTime(Task task) {
    // If the task already has an estimated time, return it
    if (task.estimatedTime > 0) {
      return task.estimatedTime;
    }

    // Basic estimation logic based on task properties
    int baseEstimate = 30; // Default 30 minutes

    // Adjust based on task title length (longer titles might indicate more complex tasks)
    if (task.title.length > 50) {
      baseEstimate += 30;
    } else if (task.title.length > 20) {
      baseEstimate += 15;
    }

    // Adjust based on priority (higher priority tasks might be more complex)
    baseEstimate += task.priority * 10;

    // Adjust based on number of subtasks (more subtasks indicate more complex tasks)
    baseEstimate += task.subtasks.length * 15;

    logInfo('Estimated time for task "${task.title}": $baseEstimate minutes');

    return baseEstimate;
  }

  /// Estimates the time required to complete each subtask of a parent task.
  ///
  /// Distributes the parent task's estimated time among subtasks based on their
  /// relative complexity, ensuring the total equals the parent's estimated time.
  ///
  /// Returns a map of subtask IDs to estimated times in minutes.
  Map<String, int> estimateSubtaskTimes(Task parentTask) {
    final subtasks = parentTask.subtasks;
    if (subtasks.isEmpty) {
      logWarning('No subtasks found for task "${parentTask.title}"');
      return {};
    }

    final parentEstimatedTime = parentTask.estimatedTime;
    if (parentEstimatedTime <= 0) {
      logWarning('Parent task "${parentTask.title}" has no estimated time');
      return {};
    }

    // Calculate complexity scores for each subtask
    final complexityScores = <String, double>{};
    double totalComplexity = 0;

    for (final subtask in subtasks) {
      double complexity = 1.0;

      // Adjust based on title length
      complexity *= (0.5 + (subtask.title.length / 50));

      // Adjust based on priority
      complexity *= (0.8 + (subtask.priority * 0.1));

      complexityScores[subtask.id] = complexity;
      totalComplexity += complexity;
    }

    // Distribute parent's estimated time based on complexity scores
    final estimatedTimes = <String, int>{};
    int totalAllocated = 0;

    for (int i = 0; i < subtasks.length; i++) {
      final subtask = subtasks[i];
      final complexity = complexityScores[subtask.id] ?? 1.0;

      // Calculate this subtask's share of the parent's time
      int estimatedTime =
          (parentEstimatedTime * (complexity / totalComplexity)).round();

      // Ensure minimum time of 5 minutes
      if (estimatedTime < 5) {
        estimatedTime = 5;
      }

      // For the last subtask, adjust to ensure total equals parent's time
      if (i == subtasks.length - 1) {
        estimatedTime = parentEstimatedTime - totalAllocated;
        if (estimatedTime < 5) {
          estimatedTime = 5;
        }
      }

      estimatedTimes[subtask.id] = estimatedTime;
      totalAllocated += estimatedTime;

      logInfo(
        'Estimated time for subtask "${subtask.title}": $estimatedTime minutes',
      );
    }

    return estimatedTimes;
  }

  /// Applies estimated times to a list of subtasks.
  ///
  /// Updates each subtask's estimatedTime property based on the provided estimates.
  void applySubtaskEstimates(List<Task> subtasks, Map<String, int> estimates) {
    for (final subtask in subtasks) {
      final estimatedTime = estimates[subtask.id];
      if (estimatedTime != null) {
        subtask.estimatedTime = estimatedTime;
        logInfo(
          'Applied estimated time to subtask "${subtask.title}": $estimatedTime minutes',
        );
      }
    }
  }

  /// Optimizes the scheduling of tasks based on their estimated times and deadlines.
  ///
  /// Returns a list of scheduled tasks.
  List<ScheduledTask> optimizeSchedule(List<Task> tasks) {
    // Sort tasks by deadline and priority
    tasks.sort((a, b) {
      final deadlineComparison = a.deadline.compareTo(b.deadline);
      if (deadlineComparison != 0) {
        return deadlineComparison;
      }
      return b.priority.compareTo(a.priority); // Higher priority first
    });

    final scheduledTasks = <ScheduledTask>[];

    // Simple scheduling logic - in a real implementation, this would be more sophisticated
    DateTime currentDateTime = DateTime.now();

    for (final task in tasks) {
      // Skip tasks that are already completed
      if (task.isDone) continue;

      // Calculate end time by adding estimated minutes to current time
      final endDateTime = currentDateTime.add(
        Duration(minutes: task.estimatedTime),
      );

      // Create a scheduled task
      final scheduledTask = ScheduledTask(
        scheduledTaskId:
            'scheduled_${task.id}_${currentDateTime.millisecondsSinceEpoch}',
        parentTaskId: task.id,
        startTime: currentDateTime,
        endTime: endDateTime,
        type: ScheduledTaskType.values[0], // defaultType
        travelingTime: 0, // Default to no traveling time
        breakTime: 0, // Default to no break time
        notification: NotificationType.values[0], // none
      );

      scheduledTasks.add(scheduledTask);

      // Update current time for next task (add 15 minutes break)
      currentDateTime = endDateTime.add(const Duration(minutes: 15));
    }

    logInfo('Optimized schedule for ${scheduledTasks.length} tasks');

    return scheduledTasks;
  }
}
