import 'dart:async';
import 'dart:io';

import 'package:flowo_client/utils/ai_model/task_breakdown_api.dart';
import 'package:flutter/foundation.dart';

// A simple script to test the TaskBreakdownAPI
Future<void> main() async {
  if (kDebugMode) {
    print('Starting TaskBreakdownAPI test script...');
  }

  final api = TaskBreakdownAPI(apiKey: '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');

  // Test with a valid task
  if (kDebugMode) {
    print('\n--- Testing with valid task ---');
  }
  await testTask(api, 'Write a research paper on climate change');

  // Test with an empty task
  if (kDebugMode) {
    print('\n--- Testing with empty task ---');
  }
  await testTask(api, '');

  // Test with a very short task
  if (kDebugMode) {
    print('\n--- Testing with short task ---');
  }
  await testTask(api, 'Test');

  // Test direct breakdownTask method
  if (kDebugMode) {
    print('\n--- Testing breakdownTask method ---');
  }
  final directSubtasks = await api.breakdownTask('Create a mobile app');
  if (kDebugMode) {
    print('Direct subtasks: $directSubtasks');
  }
  if (kDebugMode) {
    print('Number of direct subtasks: ${directSubtasks.length}');
  }

  if (kDebugMode) {
    print('\nAll tests completed successfully!');
  }
  exit(0);
}

Future<void> testTask(TaskBreakdownAPI api, String task) async {
  if (kDebugMode) {
    print('Making API request for task: "$task"');
  }
  final response = await api.makeRequest(task);
  if (kDebugMode) {
    print('Raw API response: $response');
  }

  if (kDebugMode) {
    print('Parsing subtasks from response...');
  }
  final subtasks = api.parseSubtasks(response);
  if (kDebugMode) {
    print('Generated subtasks: $subtasks');
  }
  if (kDebugMode) {
    print('Number of subtasks: ${subtasks.length}');
  }

  if (subtasks.isEmpty) {
    if (kDebugMode) {
      print('WARNING: No subtasks were generated.');
    }
  } else {
    if (kDebugMode) {
      print('SUCCESS: Generated ${subtasks.length} subtasks.');
    }
  }
}
