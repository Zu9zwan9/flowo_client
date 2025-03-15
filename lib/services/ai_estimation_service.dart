import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/services/task_time_estimator.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flowo_client/utils/task_manager.dart';

/// Service for handling AI-based time estimation for tasks
///
/// This service provides methods for estimating time for a single task,
/// a task and its subtasks, or all tasks in the system.
class AIEstimationService {
  final TaskManager _taskManager;
  final TaskTimeEstimator _taskTimeEstimator;

  /// Creates a new AIEstimationService with the given task manager and time estimator
  AIEstimationService({
    required TaskManager taskManager,
    TaskTimeEstimator? taskTimeEstimator,
    String? huggingFaceApiKey,
  })  : _taskManager = taskManager,
        _taskTimeEstimator = taskTimeEstimator ??
            TaskTimeEstimator(
              AITimeEstimationStrategy(
                apiKey: huggingFaceApiKey ??
                    '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', // Default API key
              ),
            );

  /// Estimates time for a single task using AI
  ///
  /// Returns the estimated time in minutes
  Future<int> estimateTaskTime(Task task) async {
    logInfo('Estimating time for task: ${task.title}');

    try {
      // Use the task breakdown API to generate a description of the task
      final subtaskTitles =
          await _taskManager.taskBreakdownAPI.breakdownTask(task.title);

      if (subtaskTitles.isEmpty) {
        logWarning('No subtasks generated for task: ${task.title}');
        return task.estimatedTime > 0
            ? task.estimatedTime
            : 60; // Default to 1 hour if no estimate
      }

      // Estimate time based on the subtasks
      final estimates = await _taskTimeEstimator.estimateSubtaskTimes(
        subtaskTitles,
        task.estimatedTime > 0
            ? task.estimatedTime
            : 60, // Use existing estimate or default
        task.deadline,
      );

      // Sum up the estimates
      final totalEstimate = estimates.fold(0, (sum, time) => sum + time);

      logInfo(
          'Estimated time for task "${task.title}": $totalEstimate minutes');
      return totalEstimate;
    } catch (e) {
      logError('Error estimating time for task: $e');
      return task.estimatedTime > 0
          ? task.estimatedTime
          : 60; // Return existing estimate or default
    }
  }

  /// Estimates time for a task and its subtasks using AI
  ///
  /// Updates the task and its subtasks with the estimated times
  /// Returns the updated task
  Future<Task> estimateTaskAndSubtasks(Task task) async {
    logInfo('Estimating time for task and subtasks: ${task.title}');

    try {
      // If the task has no subtasks, break it down first
      if (task.subtasks.isEmpty) {
        logInfo('Task has no subtasks, breaking it down: ${task.title}');
        final subtasks = await _taskManager.breakdownAndScheduleTask(task);

        // If subtasks were created, return the updated task
        if (subtasks.isNotEmpty) {
          logInfo(
              'Created ${subtasks.length} subtasks for task: ${task.title}');
          return task;
        }
      } else {
        // Task already has subtasks, estimate time for each
        logInfo(
            'Task has ${task.subtasks.length} subtasks, estimating time for each');

        // Get subtask titles
        final subtaskTitles =
            task.subtasks.map((subtask) => subtask.title).toList();

        // Estimate time for subtasks
        final estimates = await _taskTimeEstimator.estimateSubtaskTimes(
          subtaskTitles,
          task.estimatedTime,
          task.deadline,
        );

        // Apply estimates to subtasks
        _taskTimeEstimator.applyEstimates(task.subtasks, estimates);

        // Update subtasks in database
        for (var subtask in task.subtasks) {
          _taskManager.tasksDB.put(subtask.id, subtask);
          logInfo(
              'Updated subtask "${subtask.title}" with estimated time: ${subtask.estimatedTime} minutes');
        }

        // Update parent task's estimated time to sum of subtasks
        final totalEstimate = task.subtasks
            .fold(0, (sum, subtask) => sum + subtask.estimatedTime);
        task.estimatedTime = totalEstimate;
        _taskManager.tasksDB.put(task.id, task);

        logInfo(
            'Updated task "${task.title}" with total estimated time: ${task.estimatedTime} minutes');
      }

      return task;
    } catch (e) {
      logError('Error estimating time for task and subtasks: $e');
      return task;
    }
  }

  /// Estimates time for all tasks in the system using AI
  ///
  /// Updates all tasks with the estimated times
  /// Returns the number of tasks updated
  Future<int> estimateAllTasks() async {
    logInfo('Estimating time for all tasks');

    try {
      // Get all top-level tasks (tasks without a parent)
      final tasks = _taskManager.tasksDB.values
          .where((task) => task.parentTaskId == null)
          .toList();

      int updatedCount = 0;

      // Process each task
      for (var task in tasks) {
        await estimateTaskAndSubtasks(task);
        updatedCount++;
      }

      logInfo('Updated $updatedCount tasks with AI-estimated times');
      return updatedCount;
    } catch (e) {
      logError('Error estimating time for all tasks: $e');
      return 0;
    }
  }
}
