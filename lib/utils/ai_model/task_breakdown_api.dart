import 'dart:async';
import 'dart:convert';

import 'package:flowo_client/utils/logger.dart';
import 'package:http/http.dart' as http;

Pipeline pipeline(
  String task, {
  required String model,
  required String apiKey,
  String? apiUrl,
}) {
  return Pipeline(task: task, model: model, apiKey: apiKey, apiUrl: apiUrl);
}

/// A pipeline for text generation using Azure API models
class Pipeline {
  final String task;
  final String model;
  final String apiKey;
  final String apiUrl;

  /// Creates a new pipeline for text generation
  ///
  /// The task should be a valid task type (e.g., "chat")
  /// The model should be a valid Azure API model ID
  /// The API key should be a valid Azure API key
  Pipeline({
    required this.task,
    required this.model,
    required this.apiKey,
    String? apiUrl,
  }) : apiUrl =
           apiUrl ?? 'https://models.inference.ai.azure.com/chat/completions';

  /// Calls the pipeline with the given messages
  ///
  /// Returns the generated text or null if the request failed
  /// The response can be either a Map<String, dynamic> or a List<dynamic>
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
            "generated_text":
                "1. Research the topic\n2. Create an outline\n3. Draft the content\n4. Review and revise\n5. Finalize the work",
          };
        }
      } else {
        logError(
          'Error from Azure API: ${response.statusCode} - ${response.body}',
        );

        // If the API is unavailable, return a fallback response
        logWarning('Using fallback response due to API error');
        return {
          "generated_text":
              "1. Research the topic\n2. Create an outline\n3. Draft the content\n4. Review and revise\n5. Finalize the work",
        };
      }
    } catch (e) {
      logError('Exception making request to Azure API: $e');

      // If there's an exception, return a fallback response
      logWarning('Using fallback response due to exception');
      return {
        "generated_text":
            "1. Research the topic\n2. Create an outline\n3. Draft the content\n4. Review and revise\n5. Finalize the work",
      };
    }
  }
}

/// A service that uses Azure API to break down tasks into subtasks
class TaskBreakdownAPI {
  final String apiKey;
  final String apiUrl;
  final Pipeline _pipeline;

  /// Creates a new TaskBreakdownAPI with the given API key
  ///
  /// The API key should be a valid Azure API key
  TaskBreakdownAPI({
    String? apiKey,
    this.apiUrl = 'https://models.inference.ai.azure.com/chat/completions',
  }) : apiKey =
           apiKey ??
           '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',
       _pipeline = pipeline(
         "chat",
         model: 'gpt-4o',
         apiKey:
             apiKey ??
             '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',
         apiUrl: apiUrl,
       );

  /// Makes a request to the Azure API to break down a task into subtasks
  ///
  /// Returns the raw API response or null if the request failed
  /// The response can be either a Map<String, dynamic> or a List<dynamic>
  Future<dynamic> makeRequest(String task, String totalTime) async {
    // If task is empty, return a mock response for testing

    totalTime = (int.parse(totalTime.trim()) / 60000).toString();
    if (task.isEmpty) {
      logWarning('Empty task provided, returning mock response');
      return {
        "generated_text":
            "1. First subtask\n2. Second subtask\n3. Third subtask",
      };
    }

    // Create messages in the format expected by the pipeline
    final messages = [
      {
        "role": "user",
        "content":
            "You are a helpful assistant that breaks down tasks into clear, actionable subtasks and distributes the total estimated time among them. "
            "The total estimated time for the task is $totalTime minutes. "
            "Format your response as a numbered list, where each subtask is followed by its estimated time in minutes in parentheses, like this: '1. Subtask (X minutes)'. "
            "Break down the task into specific subtasks and ensure the sum of the subtask times equals $totalTime minutes: $task",
      },
    ];

    // Use the pipeline to generate the response
    return await _pipeline.call(messages);
  }

  /// Parses the response from the Azure API into a list of subtasks
  ///
  /// Returns an empty list if the response is invalid or empty
  List<Map<String, dynamic>> parseSubtasks(dynamic response) {
    if (response == null) {
      logWarning('Received null response from Azure API');
      return [];
    }

    try {
      String text;
      if (response is List && response.isNotEmpty) {
        text = response[0]["generated_text"] ?? "";
      } else if (response is Map<String, dynamic>) {
        text = response["generated_text"] ?? "";
      } else {
        logWarning('Unexpected response format from Azure API: $response');
        return [];
      }

      text = text.trim();
      if (text.isEmpty) {
        logWarning('Empty text after cleanup');
        return [];
      }

      final subtasks = <Map<String, dynamic>>[];
      final lines = text.split('\n');
      for (var line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isNotEmpty) {
          final subtaskData = _parseSubtaskLine(trimmedLine);
          if (subtaskData != null) {
            subtasks.add(subtaskData);
          }
        }
      }

      if (subtasks.isEmpty) {
        logWarning('No valid subtasks parsed');
      } else {
        logInfo('Parsed ${subtasks.length} subtasks');
      }
      return subtasks;
    } catch (e) {
      logError('Error parsing subtasks: $e');
      return [];
    }
  }

  /// Breaks down a task into subtasks using the Hugging Face API
  ///
  /// Returns a list of subtasks or default subtasks if the request failed
  Future<List<Map<String, dynamic>>> breakdownTask(
    String task,
    String totalTime,
  ) async {
    if (task.trim().isEmpty) {
      logWarning('Empty task provided');
      return [];
    }
    final response = await makeRequest(task, totalTime);
    return parseSubtasks(response);
  }

  Map<String, dynamic>? _parseSubtaskLine(String line) {
    final regex = RegExp(r'^\d+\.\s*(.+?)\s*\((\d+)\s*minutes?\)$');
    final match = regex.firstMatch(line);
    if (match != null) {
      final title = match.group(1)!.trim();
      final minutes = int.parse(match.group(2)!);
      final estimatedTime =
          minutes * 60 * 1000; // Конвертация минут в миллисекунды
      return {'title': title, 'estimatedTime': estimatedTime};
    }
    return null; // Если формат не соответствует, возвращаем null
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
