import 'dart:async';
import 'dart:convert';

import 'package:flowo_client/config/env_config.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:http/http.dart' as http;

// Pipeline factory function
Pipeline pipeline(
  String task, {
  required String model,
  required String apiKey,
  String? apiUrl,
}) {
  return Pipeline(task: task, model: model, apiKey: apiKey, apiUrl: apiUrl);
}

// Pipeline class for Azure API
class Pipeline {
  final String task;
  final String model;
  final String apiKey;
  final String apiUrl;

  Pipeline({
    required this.task,
    required this.model,
    required this.apiKey,
    String? apiUrl,
  }) : apiUrl =
           apiUrl ?? 'https://models.inference.ai.azure.com/chat/completions';

  Future<dynamic> call(List<Map<String, String>> messages) async {
    // Convert the messages to the format expected by Azure API
    final List<Map<String, String>> formattedMessages = [];

    // Add system message if not present
    bool hasSystemMessage = messages.any((msg) => msg["role"] == "system");
    if (!hasSystemMessage) {
      formattedMessages.add({"role": "system", "content": ""});
    }

    // Add the rest of the messages
    formattedMessages.addAll(messages);

    final data = {
      "messages": formattedMessages,
      "model": model,
      "temperature": 1,
      "max_tokens": 4096,
      "top_p": 1,
    };

    final headers = {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    };

    try {
      logInfo('Making request to Azure API for model: $model');
      final client = http.Client();
      final response = await client.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        logInfo('Received successful response from Azure API');
        final responseBody = jsonDecode(response.body);
        // Extract the generated text from the Azure API response format
        if (responseBody.containsKey('choices') &&
            responseBody['choices'] is List &&
            responseBody['choices'].isNotEmpty &&
            responseBody['choices'][0].containsKey('message') &&
            responseBody['choices'][0]['message'].containsKey('content')) {
          return {
            "generated_text": responseBody['choices'][0]['message']['content'],
          };
        } else {
          logWarning('Unexpected response format from Azure API');
          return {
            "generated_text": "1 hour", // Fallback for time estimation
          };
        }
      } else {
        logError(
          'Error from Azure API: ${response.statusCode} - ${response.body}',
        );
        logWarning('Using fallback response due to API error');
        return {
          "generated_text": "1 hour", // Fallback for time estimation
        };
      }
    } catch (e) {
      logError('Exception making request to Azure API: $e');
      logWarning('Using fallback response due to exception');
      return {
        "generated_text": "1 hour", // Fallback for time estimation
      };
    }
  }
}

/// A service that combines task breakdown and time estimation using Azure API
class TaskProcessorAPI {
  final String apiKey;
  final String apiUrl;
  final Pipeline _pipeline;

  /// Creates a new TaskProcessorAPI with the given API key
  TaskProcessorAPI({String? apiKey, String? apiUrl})
    : apiKey = apiKey ?? EnvConfig.azureApiKey,
      apiUrl = apiUrl ?? EnvConfig.azureApiUrl,
      _pipeline = pipeline(
        "chat",
        model: EnvConfig.aiModel,
        apiKey: apiKey ?? EnvConfig.azureApiKey,
        apiUrl: apiUrl ?? EnvConfig.azureApiUrl,
      );

  /// Processes a task by breaking it into subtasks and estimating time for each
  /// Returns a list of tuples containing subtask description and estimated time in milliseconds
  Future<List<(String, int)>> processTask(String task) async {
    // Handle empty task input
    if (task.trim().isEmpty) {
      logWarning('Empty task provided, returning mock response');
      return [
        ("Define the task clearly", 30 * 60 * 1000), // 30 minutes
        ("Break down into smaller steps", 60 * 60 * 1000), // 1 hour
        ("Execute the plan", 45 * 60 * 1000), // 45 minutes
      ];
    }

    // Step 1: Break down the task into subtasks
    final subtasks = await _breakdownTask(task);
    if (subtasks.isEmpty) {
      logWarning('No subtasks generated, returning default response');
      return [
        ("Research the topic", 60 * 60 * 1000), // 1 hour
        ("Draft the content", 90 * 60 * 1000), // 1.5 hours
        ("Review and finalize", 30 * 60 * 1000), // 30 minutes
      ];
    }

    // Step 2: Estimate time for each subtask
    final processedSubtasks = <(String, int)>[];
    for (final subtask in subtasks) {
      final timeEstimate = await _estimateTime(subtask);
      processedSubtasks.add((subtask, timeEstimate));
    }

    logInfo(
      'Processed task "$task" into ${processedSubtasks.length} subtasks with time estimates',
    );
    return processedSubtasks;
  }

  /// Breaks down a task into a list of subtasks
  Future<List<String>> _breakdownTask(String task) async {
    final messages = [
      {
        "role": "user",
        "content":
            "Break down the task into clear, actionable subtasks. Format your response as a numbered list (e.g., '1. Do this'). Task: $task",
      },
    ];

    final response = await _pipeline.call(messages);
    return _parseSubtasks(response);
  }

  /// Estimates time for a single subtask
  Future<int> _estimateTime(String subtask) async {
    final messages = [
      {
        "role": "user",
        "content":
            "Estimate the time for this subtask in hours and minutes (e.g., '2 hours 30 minutes'). Do not include any additional text. Subtask: $subtask",
      },
    ];

    final response = await _pipeline.call(messages);
    return _parseTimeEstimate(response);
  }

  /// Parses subtasks from the API response
  List<String> _parseSubtasks(dynamic response) {
    if (response == null) {
      logWarning('Received null response for subtasks');
      return [];
    }

    try {
      String text =
          response is List && response.isNotEmpty
              ? response[0]["generated_text"] ?? ""
              : response["generated_text"] ?? "";

      text = text.trim();
      if (text.isEmpty) {
        logWarning('Empty subtask text after cleanup');
        return [];
      }

      final subtasks = <String>[];
      final lines = text.split('\n');
      for (var line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isNotEmpty && _isSubtaskLine(trimmedLine)) {
          final subtask = _cleanSubtaskLine(trimmedLine);
          if (subtask.isNotEmpty) subtasks.add(subtask);
        }
      }

      return subtasks.isEmpty ? [] : subtasks;
    } catch (e) {
      logError('Error parsing subtasks: $e');
      return [];
    }
  }

  /// Parses time estimate from the API response into milliseconds
  int _parseTimeEstimate(dynamic response) {
    if (response == null) {
      logWarning('Received null response for time estimate');
      return 60 * 60 * 1000; // Default: 1 hour
    }

    try {
      String text =
          response is List && response.isNotEmpty
              ? response[0]["generated_text"] ?? ""
              : response["generated_text"] ?? "";

      text = text.trim();
      if (text.isEmpty) {
        logWarning('Empty time estimate text after cleanup');
        return 60 * 60 * 1000; // Default: 1 hour
      }

      return _parseTimeString(text);
    } catch (e) {
      logError('Error parsing time estimate: $e');
      return 60 * 60 * 1000; // Default: 1 hour
    }
  }

  /// Parses a time string into milliseconds
  int _parseTimeString(String timeString) {
    int totalMilliseconds = 0;
    timeString = timeString.toLowerCase();

    final hourRegexes = [
      RegExp(r'(\d+(\.\d+)?)\s*hours?'),
      RegExp(r'(\d+(\.\d+)?)\s*hrs?'),
      RegExp(r'(\d+(\.\d+)?)\s*h\b'),
    ];
    for (var regex in hourRegexes) {
      final match = regex.firstMatch(timeString);
      if (match != null) {
        totalMilliseconds +=
            (double.parse(match.group(1)!) * 60 * 60 * 1000).round();
        break;
      }
    }

    final minuteRegexes = [
      RegExp(r'(\d+(\.\d+)?)\s*minutes?'),
      RegExp(r'(\d+(\.\d+)?)\s*mins?'),
      RegExp(r'(\d+(\.\d+)?)\s*m\b'),
    ];
    for (var regex in minuteRegexes) {
      final match = regex.firstMatch(timeString);
      if (match != null) {
        totalMilliseconds +=
            (double.parse(match.group(1)!) * 60 * 1000).round();
        break;
      }
    }

    return totalMilliseconds > 0
        ? totalMilliseconds
        : 60 * 60 * 1000; // Default: 1 hour
  }

  /// Checks if a line represents a subtask
  bool _isSubtaskLine(String line) {
    return RegExp(r'^\d+[\.\)\-]?\s+|^[•\*\-]\s+').hasMatch(line);
  }

  /// Cleans a subtask line by removing number/bullet
  String _cleanSubtaskLine(String line) {
    return line
        .replaceFirst(RegExp(r'^\d+[\.\)\-]?\s+|^[•\*\-]\s+'), '')
        .trim();
  }
}

/// Extension method to remove a suffix from a string (unchanged)
extension StringExtension on String {
  String rstrip(String pattern) {
    if (endsWith(pattern)) {
      return substring(0, length - pattern.length);
    }
    return this;
  }
}
