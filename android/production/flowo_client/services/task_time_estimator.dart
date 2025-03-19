import 'dart:convert';

import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flowo_client/utils/task_breakdown_api.dart';

/// Interface for task time estimation strategies
abstract class TimeEstimationStrategy {
  /// Estimates time for a list of subtasks based on their content, parent task's estimated time, and deadline
  Future<List<int>> estimateTime(
    List<String> subtaskTitles,
    int parentEstimatedTime,
    int parentDeadline,
  );
}

/// A strategy that uses AI to estimate time for subtasks
class AITimeEstimationStrategy implements TimeEstimationStrategy {
  final Pipeline _pipeline;

  /// Creates a new AITimeEstimationStrategy with the given API key
  AITimeEstimationStrategy({required String apiKey, String? apiUrl})
    : _pipeline = pipeline(
        "text-generation",
        model: 'HuggingFaceH4/zephyr-7b-beta',
        apiKey: apiKey,
        apiUrl: apiUrl,
      );

  @override
  Future<List<int>> estimateTime(
    List<String> subtaskTitles,
    int parentEstimatedTime,
    int parentDeadline,
  ) async {
    if (subtaskTitles.isEmpty) {
      logWarning('No subtasks provided for time estimation');
      return [];
    }

    logInfo('Estimating time for ${subtaskTitles.length} subtasks');

    // Format the subtasks as a numbered list for the AI
    final subtasksList = subtaskTitles
        .asMap()
        .entries
        .map((entry) => "${entry.key + 1}. ${entry.value}")
        .join('\n');

    // Calculate time until deadline in hours
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeUntilDeadline =
        (parentDeadline - now) ~/ (1000 * 60 * 60); // hours

    // Create the prompt for the AI
    final prompt = """
I have a task with an estimated total time of $parentEstimatedTime minutes and a deadline in $timeUntilDeadline hours.
The task is broken down into the following subtasks:
$subtasksList

Please estimate how many minutes each subtask will take, considering the total estimated time of $parentEstimatedTime minutes.
Respond with only a JSON array of integers representing the estimated minutes for each subtask in order, like [30, 45, 60, ...].
The sum of all estimates should be approximately equal to the total estimated time.
""";

    // Create messages in the format expected by the pipeline
    final messages = [
      {"role": "user", "content": prompt},
    ];

    try {
      // Use the pipeline to generate the response
      final response = await _pipeline.call(messages);

      // Parse the response
      return _parseTimeEstimates(
        response,
        subtaskTitles.length,
        parentEstimatedTime,
      );
    } catch (e) {
      logError('Error estimating time for subtasks: $e');

      // Fallback to proportional distribution
      return _distributeProportionally(
        subtaskTitles.length,
        parentEstimatedTime,
      );
    }
  }

  /// Parses the time estimates from the AI response
  List<int> _parseTimeEstimates(
    dynamic response,
    int subtaskCount,
    int totalTime,
  ) {
    if (response == null) {
      logWarning('Received null response from Hugging Face API');
      return _distributeProportionally(subtaskCount, totalTime);
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
        return _distributeProportionally(subtaskCount, totalTime);
      }

      // Extract JSON array from the response
      final jsonRegExp = RegExp(r'\[[\d\s,]+\]');
      final match = jsonRegExp.firstMatch(text);

      if (match != null) {
        final jsonStr = match.group(0);
        if (jsonStr != null) {
          final List<dynamic> estimates = jsonDecode(jsonStr);

          // Convert to list of integers
          final List<int> timeEstimates =
              estimates.map((e) => e as int).toList();

          // Validate the estimates
          if (timeEstimates.length == subtaskCount) {
            // Check if the sum is reasonably close to the total time
            final sum = timeEstimates.fold(0, (sum, time) => sum + time);
            if (sum > 0 && (sum - totalTime).abs() <= totalTime * 0.2) {
              // Allow 20% deviation
              logInfo('Successfully parsed time estimates: $timeEstimates');
              return timeEstimates;
            }
          }
        }
      }

      logWarning('Failed to parse valid time estimates from response: $text');
      return _distributeProportionally(subtaskCount, totalTime);
    } catch (e) {
      logError('Error parsing time estimates: $e');
      return _distributeProportionally(subtaskCount, totalTime);
    }
  }

  /// Distributes time proportionally among subtasks (fallback method)
  List<int> _distributeProportionally(int subtaskCount, int totalTime) {
    logInfo('Using proportional distribution for time estimates');
    final baseTime = totalTime ~/ subtaskCount;
    final remainder = totalTime % subtaskCount;

    return List.generate(
      subtaskCount,
      (index) => index < remainder ? baseTime + 1 : baseTime,
    );
  }
}

/// Service for estimating time for subtasks
class TaskTimeEstimator {
  final TimeEstimationStrategy _strategy;

  /// Creates a new TaskTimeEstimator with the given strategy
  TaskTimeEstimator(this._strategy);

  /// Estimates time for a list of subtasks based on their content, parent task's estimated time, and deadline
  Future<List<int>> estimateSubtaskTimes(
    List<String> subtaskTitles,
    int parentEstimatedTime,
    int parentDeadline,
  ) async {
    return await _strategy.estimateTime(
      subtaskTitles,
      parentEstimatedTime,
      parentDeadline,
    );
  }

  /// Applies estimated times to a list of subtasks
  void applyEstimates(List<Task> subtasks, List<int> estimates) {
    if (subtasks.length != estimates.length) {
      logError('Mismatch between subtasks and estimates count');
      return;
    }

    for (int i = 0; i < subtasks.length; i++) {
      subtasks[i].estimatedTime = estimates[i];
      logInfo(
        'Set estimated time for "${subtasks[i].title}" to ${estimates[i]} minutes',
      );
    }
  }
}
