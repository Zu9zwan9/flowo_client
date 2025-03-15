import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/services/task_time_estimator.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flowo_client/utils/task_manager.dart';
import 'package:flutter/material.dart';

/// An enhanced version of TaskManager that adds AI-based time estimation for subtasks.
///
/// This class extends the original TaskManager and overrides the breakdownAndScheduleTask
/// method to use AI for estimating subtask times instead of simple proportional distribution.
class EnhancedTaskManager extends TaskManager {
  /// The TaskTimeEstimator used for AI-based time estimation
  final TaskTimeEstimator _taskTimeEstimator;

  /// Creates a new EnhancedTaskManager with the given parameters.
  ///
  /// In addition to the parameters required by TaskManager, this constructor
  /// initializes a TaskTimeEstimator with an AITimeEstimationStrategy.
  /// Creates a new EnhancedTaskManager with the given parameters.
  ///
  /// Uses super parameters for daysDB, tasksDB, and userSettings to pass them directly
  /// to the TaskManager superclass.
  EnhancedTaskManager({
    required super.daysDB,
    required super.tasksDB,
    required super.userSettings,
    required String huggingFaceApiKey,
  })  : _taskTimeEstimator = TaskTimeEstimator(
          AITimeEstimationStrategy(
            apiKey: huggingFaceApiKey,
          ),
        ),
        super(
          huggingFaceApiKey: huggingFaceApiKey,
        );

  /// Breaks down a task into subtasks using AI, estimates time for each subtask using AI,
  /// and schedules them.
  ///
  /// This method overrides the original breakdownAndScheduleTask method to use
  /// AI-based time estimation instead of simple proportional distribution.
  ///
  /// Returns a list of the created subtasks.
  @override
  Future<List<Task>> breakdownAndScheduleTask(Task task) async {
    logInfo('Breaking down task with AI: ${task.title}');

    // Use the API to break down the task into subtasks
    final subtaskTitles = await taskBreakdownAPI.breakdownTask(task.title);

    if (subtaskTitles.isEmpty) {
      logWarning('No subtasks generated for task: ${task.title}');

      // If no subtasks were generated, schedule the parent task itself
      logInfo('Scheduling parent task: ${task.title}');
      scheduler.scheduleTask(
        task,
        userSettings.minSession,
        urgency: null,
      );

      return [];
    }

    logInfo('Generated ${subtaskTitles.length} subtasks for: ${task.title}');

    // Use AI to estimate time for each subtask
    logInfo('Estimating time for subtasks using AI...');
    final estimates = await _taskTimeEstimator.estimateSubtaskTimes(
      subtaskTitles,
      task.estimatedTime,
      task.deadline,
    );

    // Create subtask objects
    final subtasks = <Task>[];
    int order = 1;

    for (var i = 0; i < subtaskTitles.length; i++) {
      final subtaskTitle = subtaskTitles[i];

      // Use AI-estimated time if available, otherwise use proportional distribution
      final estimatedTime = i < estimates.length
          ? estimates[i]
          : (task.estimatedTime / subtaskTitles.length).round();

      final subtask = Task(
        id: UniqueKey().toString(),
        title: subtaskTitle,
        priority: task.priority,
        estimatedTime: estimatedTime,
        deadline: task.deadline,
        category: task.category,
        parentTask: task,
        order: order++,
      );

      tasksDB.put(subtask.id, subtask);
      subtasks.add(subtask);

      // Add subtask to parent task's subtasks list
      task.subtasks.add(subtask);

      logInfo(
          'Created subtask "$subtaskTitle" with estimated time: $estimatedTime minutes');
    }

    // Update the parent task in the database
    tasksDB.put(task.id, task);

    // Schedule the subtasks
    scheduleSubtasks(subtasks);

    return subtasks;
  }
}
