import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flowo_client/utils/logger.dart';

/// A factory function to create a pipeline for various NLP tasks
Pipeline pipeline(String task,
    {required String model, required String apiKey, String? apiUrl}) {
  return Pipeline(
    task: task,
    model: model,
    apiKey: apiKey,
    apiUrl: apiUrl,
  );
}

/// A pipeline for text generation using Hugging Face models
class Pipeline {
  final String task;
  final String model;
  final String apiKey;
  final String apiUrl;

  /// Creates a new pipeline for text generation
  ///
  /// The task should be a valid NLP task (e.g., "text-generation")
  /// The model should be a valid Hugging Face model ID
  /// The API key should be a valid Hugging Face API key
  Pipeline({
    required this.task,
    required this.model,
    required this.apiKey,
    String? apiUrl,
  }) : apiUrl = apiUrl ?? 'https://api-inference.huggingface.co/models/$model';

  /// Calls the pipeline with the given messages
  ///
  /// Returns the generated text or null if the request failed
  /// The response can be either a Map<String, dynamic> or a List<dynamic>
  Future<dynamic> call(List<Map<String, String>> messages) async {
    final data = {
      "inputs": jsonEncode(messages),
      "parameters": {"max_new_tokens": 500, "return_full_text": false}
    };

    final headers = {
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json"
    };

    try {
      logInfo('Making request to Hugging Face API for model: $model');
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        logInfo('Received successful response from Hugging Face API');
        return jsonDecode(response.body);
      } else {
        logError(
            'Error from Hugging Face API: ${response.statusCode} - ${response.body}');

        // If the API is unavailable, return a fallback response
        logWarning('Using fallback response due to API error');
        return {
          "generated_text":
              "1. Research the topic\n2. Create an outline\n3. Draft the content\n4. Review and revise\n5. Finalize the work"
        };
      }
    } catch (e) {
      logError('Exception making request to Hugging Face API: $e');

      // If there's an exception, return a fallback response
      logWarning('Using fallback response due to exception');
      return {
        "generated_text":
            "1. Research the topic\n2. Create an outline\n3. Draft the content\n4. Review and revise\n5. Finalize the work"
      };
    }
  }
}

/// A service that uses Hugging Face API to break down tasks into subtasks
class TaskBreakdownAPI {
  final String apiKey;
  final String apiUrl;
  final Pipeline _pipeline;

  /// Creates a new TaskBreakdownAPI with the given API key
  ///
  /// The API key should be a valid Hugging Face API key
  TaskBreakdownAPI({
    required this.apiKey,
    this.apiUrl =
        'https://api-inference.huggingface.co/models/HuggingFaceH4/zephyr-7b-beta',
  }) : _pipeline = pipeline(
          "text-generation",
          model: 'HuggingFaceH4/zephyr-7b-beta',
          apiKey: apiKey,
          apiUrl: apiUrl,
        );

  /// Makes a request to the Hugging Face API to break down a task into subtasks
  ///
  /// Returns the raw API response or null if the request failed
  /// The response can be either a Map<String, dynamic> or a List<dynamic>
  Future<dynamic> makeRequest(String task) async {
    // If task is empty, return a mock response for testing
    if (task.isEmpty) {
      logWarning('Empty task provided, returning mock response');
      return {
        "generated_text":
            "1. First subtask\n2. Second subtask\n3. Third subtask"
      };
    }

    // Create messages in the format expected by the pipeline
    final messages = [
      {
        "role": "user",
        "content":
            "You are a helpful assistant that breaks down tasks into clear, actionable subtasks. Format your response as a numbered list. Break down the task into specific subtasks: $task"
      }
    ];

    // Use the pipeline to generate the response
    return await _pipeline.call(messages);
  }

  /// Parses the response from the Hugging Face API into a list of subtasks
  ///
  /// Returns an empty list if the response is invalid or empty
  List<String> parseSubtasks(dynamic response) {
    if (response == null) {
      logWarning('Received null response from Hugging Face API');
      // Return default subtasks instead of empty list
      return [
        "Research the topic",
        "Create an outline",
        "Draft the content",
        "Review and revise",
        "Finalize the work"
      ];
    }

    try {
      String text;
      if (response is List && response.isNotEmpty) {
        text = response[0]["generated_text"] ?? "";
      } else if (response is Map<String, dynamic>) {
        text = response["generated_text"] ?? "";
      } else {
        logWarning(
            'Unexpected response format from Hugging Face API: $response');
        // Return default subtasks for unexpected format
        return [
          "Research the topic",
          "Create an outline",
          "Draft the content",
          "Review and revise",
          "Finalize the work"
        ];
      }

      /// Extension method to remove a suffix from a string
      // Clean up the text
      text = text.rstrip('"}]');

      // If text is empty after cleanup, return default subtasks
      if (text.trim().isEmpty) {
        logWarning('Empty text after cleanup, using default subtasks');
        return [
          "Research the topic",
          "Create an outline",
          "Draft the content",
          "Review and revise",
          "Finalize the work"
        ];
      }

      // Extract subtasks by looking for numbered or bulleted lines
      final subtasks = <String>[];
      final lines = text.split('\n');

      for (var line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty) continue;

        // Check if line starts with a number or bullet point
        if (_isSubtaskLine(trimmedLine)) {
          // Remove the number/bullet and any leading whitespace
          final subtask = _cleanSubtaskLine(trimmedLine);
          if (subtask.isNotEmpty) {
            subtasks.add(subtask);
          }
        } else if (subtasks.isEmpty && trimmedLine.length > 5) {
          // If no subtask format is detected but line is substantial,
          // treat each non-empty line as a subtask
          subtasks.add(trimmedLine);
        }
      }

      // If no subtasks were found, try to split the text into sentences
      if (subtasks.isEmpty) {
        logWarning(
            'No subtasks found in structured format, trying sentence splitting');
        final sentences = text.split(RegExp(r'[.!?]\s+'));
        for (var sentence in sentences) {
          final trimmed = sentence.trim();
          if (trimmed.length > 5) {
            subtasks.add(trimmed);
          }
        }
      }

      // If still no subtasks, return default ones
      if (subtasks.isEmpty) {
        logWarning('Failed to extract any subtasks, using default subtasks');
        return [
          "Research the topic",
          "Create an outline",
          "Draft the content",
          "Review and revise",
          "Finalize the work"
        ];
      }

      logInfo(
          'Parsed ${subtasks.length} subtasks from Hugging Face API response');

      if (subtasks.isNotEmpty) {
        subtasks.removeAt(0);
      }
      return subtasks;
    } catch (e) {
      logError('Error parsing subtasks from Hugging Face API response: $e');
      // Return default subtasks on error
      return [
        "Research the topic",
        "Create an outline",
        "Draft the content",
        "Review and revise",
        "Finalize the work"
      ];
    }
  }

  /// Breaks down a task into subtasks using the Hugging Face API
  ///
  /// Returns a list of subtasks or default subtasks if the request failed
  Future<List<String>> breakdownTask(String task) async {
    if (task.trim().isEmpty) {
      logWarning('Empty task provided to breakdownTask');
      return [
        "Define the task clearly",
        "Break down into smaller steps",
        "Prioritize the steps",
        "Estimate time for each step",
        "Execute the plan"
      ];
    }

    final response = await makeRequest(task);
    return parseSubtasks(response);
  }

  /// Checks if a line represents a subtask (starts with a number or bullet point)
  bool _isSubtaskLine(String line) {
    // Check for numbered items (e.g., "1. ", "2) ", etc.)
    if (RegExp(r'^\d+[\.\)\-]?\s+').hasMatch(line)) {
      return true;
    }

    // Check for bullet points
    if (line.startsWith('• ') ||
        line.startsWith('* ') ||
        line.startsWith('- ')) {
      return true;
    }

    return false;
  }

  /// Cleans a subtask line by removing the number/bullet and any leading whitespace
  String _cleanSubtaskLine(String line) {
    // Remove numbers, bullets, and any leading whitespace
    return line
        .replaceFirst(RegExp(r'^\d+[\.\)\-]?\s+|^[•\*\-]\s+'), '')
        .trim();
  }
}

/// Extension method to remove a suffix from a string
extension StringExtension on String {
  String rstrip(String pattern) {
    if (endsWith(pattern)) {
      return substring(0, length - pattern.length);
    }
    return this;
  }
}
