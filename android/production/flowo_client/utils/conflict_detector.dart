import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/scheduled_task_type.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/foundation.dart';

/// A class that detects conflicts between scheduled tasks
class ConflictDetector {
  /// Detects if a new task would conflict with existing scheduled tasks
  ///
  /// Returns a list of conflicting scheduled tasks, or an empty list if no conflicts
  static List<ScheduledTask> detectConflicts({
    required DateTime start,
    required DateTime end,
    required List<ScheduledTask> existingTasks,
    String? taskId,
  }) {
    final conflicts = <ScheduledTask>[];

    for (final existingTask in existingTasks) {
      // Skip if it's the same task (for editing)
      if (taskId != null && existingTask.parentTaskId == taskId) {
        continue;
      }

      // Check if there's an overlap
      if (existingTask.startTime.isBefore(end) &&
          existingTask.endTime.isAfter(start)) {
        conflicts.add(existingTask);
        logDebug('Conflict detected with task: ${existingTask.parentTaskId}');
      }
    }

    return conflicts;
  }

  /// Gets the type of conflict based on the scheduled task type
  static String getConflictTypeDescription(ScheduledTaskType type) {
    switch (type) {
      case ScheduledTaskType.defaultType:
        return 'task';
      case ScheduledTaskType.timeSensitive:
        return 'event';
      case ScheduledTaskType.mealBreak:
        return 'meal break';
      case ScheduledTaskType.rest:
        return 'break';
      case ScheduledTaskType.sleep:
        return 'sleep time';
      default:
        return 'item';
    }
  }
}
