import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/task.dart';

/// A service for breaking down tasks into subtasks using the Hugging Face API.
class HuggingFaceAPI {
  final String apiKey;
  final String apiUrl;
  final Logger _logger = Logger();

  HuggingFaceAPI({
    required this.apiKey,
    this.apiUrl =
        "https://api-inference.huggingface.co/models/HuggingFaceH4/zephyr-7b-beta",
  });

  /// Makes a request to the Hugging Face API to break down a task into subtasks.
  ///
  /// [taskDescription] is the description of the task to break down.
  /// Returns a Map containing the API response, or null if the request failed.
  Future<Map<String, dynamic>?> makeRequest(String taskDescription) async {
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final messages = [
      {
        "role": "system",
        "content":
            "You are a helpful assistant that breaks down tasks into clear, actionable subtasks."
      },
      {
        "role": "user",
        "content":
            "Break down the task into specific subtasks: $taskDescription"
      }
    ];

    final data = {
      "inputs": jsonEncode(messages),
      "parameters": {"max_new_tokens": 500, "return_full_text": false}
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        _logger
            .e('API request failed with status code: ${response.statusCode}');
        _logger.e('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Error making request: $e');
      return null;
    }
  }

  /// Parses the response from the Hugging Face API to extract subtasks.
  ///
  /// [response] is the response from the API.
  /// Returns a list of subtask descriptions.
  List<String> parseSubtasks(dynamic response) {
    if (response == null) {
      _logger.w('Response is null');
      return [];
    }

    try {
      _logger.i('Parsing response: ${jsonEncode(response)}');

      // Extract the generated text from the response
      String text = '';

      if (response is List) {
        // Handle list response format
        if (response.isNotEmpty && response[0] is Map) {
          text = response[0]["generated_text"] ?? "";
        }
      } else if (response is Map<String, dynamic>) {
        // Handle map response format
        if (response.containsKey("generated_text")) {
          text = response["generated_text"] ?? "";
        } else if (response.containsKey("outputs") &&
            response["outputs"] is List) {
          final outputs = response["outputs"] as List;
          if (outputs.isNotEmpty && outputs[0] is Map) {
            text = outputs[0]["generated_text"] ?? "";
          }
        }
      }

      if (text.isEmpty) {
        _logger.w('No text found in response');
        return [];
      }

      _logger.i('Extracted text: $text');

      // Clean up the text
      text = text.replaceAll(RegExp(r'"}]$'), '');

      // Extract subtasks using multiple strategies
      final subtasks = <String>[];
      final lines = text.split('\n');

      // Strategy 1: Look for numbered or bulleted lines
      for (var line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isNotEmpty) {
          // Check if line starts with a number or has a numbering pattern
          if (RegExp(r'^\d+[\.\)-]?\s+').hasMatch(trimmedLine) ||
              RegExp(r'^[\*\-•]\s+').hasMatch(trimmedLine)) {
            // Remove the numbering/bullet and trim
            final subtask = trimmedLine
                .replaceFirst(RegExp(r'^\d+[\.\)-]?\s+|^[\*\-•]\s+'), '')
                .trim();
            if (subtask.isNotEmpty) {
              subtasks.add(subtask);
            }
          }
        }
      }

      // Strategy 2: If no subtasks found, try to split by sentences or paragraphs
      if (subtasks.isEmpty) {
        _logger.i('No numbered subtasks found, trying alternative parsing');

        // Split by paragraphs
        final paragraphs = text.split(RegExp(r'\n\s*\n'));
        if (paragraphs.length > 1) {
          for (var paragraph in paragraphs) {
            final trimmed = paragraph.trim();
            if (trimmed.isNotEmpty &&
                !trimmed.startsWith('Here') &&
                !trimmed.startsWith('These')) {
              subtasks.add(trimmed);
            }
          }
        } else {
          // Split by sentences
          final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
          for (var sentence in sentences) {
            final trimmed = sentence.trim();
            if (trimmed.length > 10 &&
                !trimmed.startsWith('Here') &&
                !trimmed.contains('subtasks')) {
              subtasks.add(trimmed);
            }
          }
        }
      }

      _logger.i('Extracted ${subtasks.length} subtasks');
      return subtasks;
    } catch (e) {
      _logger.e('Error parsing subtasks: $e');
      return [];
    }
  }

  /// Generates subtasks for a given task using the Hugging Face API.
  ///
  /// [parentTask] is the parent task to break down.
  /// Returns a list of Task objects representing the subtasks.
  Future<List<Task>> generateSubtasks(Task parentTask) async {
    try {
      _logger.i('Generating subtasks for task: ${parentTask.title}');

      // If the task title is too short, add more context
      String taskDescription = parentTask.title;
      if (taskDescription.length < 10 &&
          parentTask.notes != null &&
          parentTask.notes!.isNotEmpty) {
        taskDescription += ": ${parentTask.notes}";
      }

      // Make the API request
      final response = await makeRequest(taskDescription);

      // Parse the response to get subtask descriptions
      final subtaskDescriptions = parseSubtasks(response);

      if (subtaskDescriptions.isEmpty) {
        _logger.w('No subtasks were generated for task: ${parentTask.title}');
        return [];
      }

      _logger.i('Generated ${subtaskDescriptions.length} subtask descriptions');

      // Create Task objects for each subtask description
      final subtasks = <Task>[];
      final totalEstimatedTime = parentTask.estimatedTime;

      // Calculate time per subtask, ensuring a minimum of 15 minutes (900000 milliseconds)
      int timePerSubtask = (totalEstimatedTime ~/ subtaskDescriptions.length)
          .clamp(900000, totalEstimatedTime);

      // Create a unique ID prefix to avoid collisions
      final idPrefix = DateTime.now().millisecondsSinceEpoch.toString();

      for (var i = 0; i < subtaskDescriptions.length; i++) {
        // Limit subtask title length to 100 characters
        String subtaskTitle = subtaskDescriptions[i];
        if (subtaskTitle.length > 100) {
          subtaskTitle = subtaskTitle.substring(0, 97) + '...';
        }

        final subtask = Task(
          id: '${idPrefix}_${i}',
          title: subtaskTitle,
          priority: parentTask.priority,
          deadline: parentTask.deadline,
          estimatedTime: timePerSubtask,
          category: parentTask.category,
          notes:
              'Subtask ${i + 1} for ${parentTask.title}\n\nOriginal description: ${subtaskDescriptions[i]}',
          parentTask: parentTask,
        );
        subtasks.add(subtask);
      }

      _logger.i('Created ${subtasks.length} subtask objects');
      return subtasks;
    } catch (e) {
      _logger.e('Error generating subtasks: $e');
      return [];
    }
  }
}
