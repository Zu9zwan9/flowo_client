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
  }) : _taskTimeEstimator = TaskTimeEstimator(
         AITimeEstimationStrategy(apiKey: huggingFaceApiKey),
       ),
       super(huggingFaceApiKey: huggingFaceApiKey);

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
      scheduler.scheduleTask(task, userSettings.minSession, urgency: null);

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
      final estimatedTime =
          i < estimates.length
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
        'Created subtask "$subtaskTitle" with estimated time: $estimatedTime minutes',
      );
    }

    // Update the parent task in the database
    tasksDB.put(task.id, task);

    // Schedule the subtasks
    scheduleSubtasks(subtasks);

    return subtasks;
  }

  /// Estimates time for a single task using AI and updates its estimated time.
  ///
  /// Returns the estimated time in milliseconds.
  Future<int> estimateTaskTime(Task task) async {
    logInfo('Estimating time for task: ${task.title}');

    // Create task description with notes if available
    final taskDescription =
        task.notes != null && task.notes!.isNotEmpty
            ? "${task.title}\nNotes: ${task.notes}"
            : task.title;

    try {
      // Use the TaskBreakdownAPI to make a request with a custom prompt
      final response = await taskBreakdownAPI.makeRequest(
        "Estimate how long this task will take in minutes. Only respond with a number: $taskDescription",
      );

      // Parse the response
      final estimatedTime = _parseTimeEstimate(response);

      // Update the task's estimated time
      task.estimatedTime = estimatedTime;
      tasksDB.put(task.id, task);

      logInfo(
        'Updated estimated time for "${task.title}" to $estimatedTime milliseconds',
      );

      return estimatedTime;
    } catch (e) {
      logError('Error estimating time for task: $e');
      return task.estimatedTime; // Return the existing estimate
    }
  }

  /// Parses a time estimate from the AI response.
  ///
  /// Returns the estimated time in milliseconds.
  int _parseTimeEstimate(dynamic response) {
    if (response == null) {
      logWarning('Received null response from Hugging Face API');
      return 60 * 60 * 1000; // Default to 1 hour
    }

    try {
      String text;
      if (response is List && response.isNotEmpty) {
        text = response[0]["generated_text"] ?? "";
      } else if (response is Map<String, dynamic>) {
        text = response["generated_text"] ?? "";
      } else {
        logWarning(
          'Unexpected response format from Hugging Face API: $response',
        );
        return 60 * 60 * 1000; // Default to 1 hour
      }

      // Clean up the text
      text = text.trim();

      // Extract the first number from the response
      final numberRegExp = RegExp(r'(\d+(\.\d+)?)');
      final match = numberRegExp.firstMatch(text);

      if (match != null) {
        final minutes = double.parse(match.group(1)!);
        return (minutes * 60 * 1000).round(); // Convert minutes to milliseconds
      } else {
        logWarning('Could not parse time estimate from response: $text');
        return 60 * 60 * 1000; // Default to 1 hour
      }
    } catch (e) {
      logError('Error parsing time estimate: $e');
      return 60 * 60 * 1000; // Default to 1 hour
    }
  }

  /// Estimates time for all subtasks of a task using AI and updates their estimated times.
  ///
  /// Returns a list of the updated subtasks.
  Future<List<Task>> estimateSubtaskTimes(Task task) async {
    if (task.subtasks.isEmpty) {
      logWarning('No subtasks to estimate for task: ${task.title}');
      return [];
    }

    logInfo(
      'Estimating time for ${task.subtasks.length} subtasks of: ${task.title}',
    );

    // Get subtask titles
    final subtaskTitles =
        task.subtasks.map((subtask) => subtask.title).toList();

    // Use AI to estimate time for each subtask
    final estimates = await _taskTimeEstimator.estimateSubtaskTimes(
      subtaskTitles,
      task.estimatedTime,
      task.deadline,
    );

    // Apply the estimates to the subtasks
    for (var i = 0; i < task.subtasks.length; i++) {
      if (i < estimates.length) {
        task.subtasks[i].estimatedTime = estimates[i];
        tasksDB.put(task.subtasks[i].id, task.subtasks[i]);

        logInfo(
          'Updated estimated time for "${task.subtasks[i].title}" to ${estimates[i]} milliseconds',
        );
      }
    }

    return task.subtasks;
  }

  /// Reschedules a task with its new estimated time.
  ///
  /// Returns the updated task.
  Future<Task> rescheduleTask(Task task) async {
    logInfo('Rescheduling task: ${task.title}');

    // Remove previous scheduled tasks
    scheduler.removePreviousScheduledTasks(task);

    // Schedule the task with its new estimated time
    scheduler.scheduleTask(task, userSettings.minSession, urgency: null);

    logInfo('Rescheduled task: ${task.title}');

    return task;
  }

  /// Estimates time for a task and reschedules it with the new estimated time.
  ///
  /// Returns the updated task.
  Future<Task> estimateAndRescheduleTask(Task task) async {
    await estimateTaskTime(task);
    return rescheduleTask(task);
  }

  /// Estimates time for all subtasks of a task and reschedules them with the new estimated times.
  ///
  /// Returns the updated subtasks.
  Future<List<Task>> estimateAndRescheduleSubtasks(Task task) async {
    final subtasks = await estimateSubtaskTimes(task);

    // Schedule the subtasks
    scheduleSubtasks(subtasks);

    return subtasks;
  }
}
