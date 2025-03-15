import 'dart:async';

import 'package:flowo_client/utils/logger.dart';
import 'package:flowo_client/utils/task_breakdown_api.dart';

/// A service that uses Hugging Face API to estimate time for tasks
class TaskEstimatorAPI {
  final String apiKey;
  final String apiUrl;
  final Pipeline _pipeline;

  /// Creates a new TaskEstimatorAPI with the given API key
  ///
  /// The API key should be a valid Hugging Face API key
  TaskEstimatorAPI({
    required this.apiKey,
    this.apiUrl =
        'https://api-inference.huggingface.co/models/HuggingFaceH4/zephyr-7b-beta',
  }) : _pipeline = pipeline(
         "text-generation",
         model: 'HuggingFaceH4/zephyr-7b-beta',
         apiKey: apiKey,
         apiUrl: apiUrl,
       );

  /// Makes a request to the Hugging Face API to estimate time for a task
  ///
  /// Returns the raw API response or null if the request failed
  /// The response can be either a Map<String, dynamic> or a List<dynamic>
  Future<dynamic> makeRequest(String task, {String? notes}) async {
    // If task is empty, return a mock response for testing
    if (task.isEmpty) {
      logWarning('Empty task provided, returning mock response');
      return {"generated_text": "2 hours"};
    }

    // Create context from task and notes
    final context =
        notes != null && notes.isNotEmpty ? "$task\nNotes: $notes" : task;

    // Create messages in the format expected by the pipeline
    final messages = [
      {
        "role": "user",
        "content":
            "You are a helpful assistant that estimates how long tasks will take. Based on the task description, provide a time estimate in hours and minutes. Only respond with the time estimate, nothing else. For example: '2 hours 30 minutes' or '45 minutes'. Task: $context",
      },
    ];

    // Use the pipeline to generate the response
    return await _pipeline.call(messages);
  }

  /// Parses the response from the Hugging Face API into a duration in milliseconds
  ///
  /// Returns a default estimate if the response is invalid or empty
  int parseTimeEstimate(dynamic response) {
    if (response == null) {
      logWarning('Received null response from Hugging Face API');
      // Return default estimate (1 hour)
      return 60 * 60 * 1000;
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
        // Return default estimate for unexpected format
        return 60 * 60 * 1000;
      }

      // Clean up the text
      text = text.trim();

      // If text is empty after cleanup, return default estimate
      if (text.isEmpty) {
        logWarning('Empty text after cleanup, using default estimate');
        return 60 * 60 * 1000;
      }

      // Parse the time estimate
      return _parseTimeString(text);
    } catch (e) {
      logError(
        'Error parsing time estimate from Hugging Face API response: $e',
      );
      // Return default estimate on error
      return 60 * 60 * 1000;
    }
  }

  /// Parses a time string into milliseconds
  ///
  /// Handles various formats like "2 hours 30 minutes", "2h 30m", "2.5 hours", etc.
  int _parseTimeString(String timeString) {
    int totalMilliseconds = 0;

    // Convert to lowercase for easier matching
    timeString = timeString.toLowerCase();

    // Handle hour formats
    final hourRegexes = [
      RegExp(r'(\d+(\.\d+)?)\s*hours?'),
      RegExp(r'(\d+(\.\d+)?)\s*hrs?'),
      RegExp(r'(\d+(\.\d+)?)\s*h\b'),
    ];

    for (var regex in hourRegexes) {
      final match = regex.firstMatch(timeString);
      if (match != null) {
        final hours = double.parse(match.group(1)!);
        totalMilliseconds += (hours * 60 * 60 * 1000).round();
        break;
      }
    }

    // Handle minute formats
    final minuteRegexes = [
      RegExp(r'(\d+(\.\d+)?)\s*minutes?'),
      RegExp(r'(\d+(\.\d+)?)\s*mins?'),
      RegExp(r'(\d+(\.\d+)?)\s*m\b'),
    ];

    for (var regex in minuteRegexes) {
      final match = regex.firstMatch(timeString);
      if (match != null) {
        final minutes = double.parse(match.group(1)!);
        totalMilliseconds += (minutes * 60 * 1000).round();
        break;
      }
    }

    // If no matches found, try to interpret as a single number (assume hours)
    if (totalMilliseconds == 0) {
      final numberRegex = RegExp(r'^\s*(\d+(\.\d+)?)\s*$');
      final match = numberRegex.firstMatch(timeString);
      if (match != null) {
        final hours = double.parse(match.group(1)!);
        totalMilliseconds = (hours * 60 * 60 * 1000).round();
      } else {
        // Default to 1 hour if no valid format is found
        logWarning('Could not parse time string: $timeString, using default');
        totalMilliseconds = 60 * 60 * 1000;
      }
    }

    return totalMilliseconds;
  }

  /// Estimates time for a task using the Hugging Face API
  ///
  /// Returns the estimated time in milliseconds or a default estimate if the request failed
  Future<int> estimateTaskTime(String task, {String? notes}) async {
    if (task.trim().isEmpty) {
      logWarning('Empty task provided to estimateTaskTime');
      return 60 * 60 * 1000; // Default to 1 hour
    }

    final response = await makeRequest(task, notes: notes);
    return parseTimeEstimate(response);
  }
}
