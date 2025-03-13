import 'dart:async';
import 'dart:io';
import 'package:flowo_client/utils/task_breakdown_api.dart';
import 'package:flowo_client/utils/logger.dart';

// A simple script to test the TaskBreakdownAPI
Future<void> main() async {
  print('Starting TaskBreakdownAPI test script...');

  final api = TaskBreakdownAPI(
    apiKey: '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',
  );

  // Test with a valid task
  print('\n--- Testing with valid task ---');
  await testTask(api, 'Write a research paper on climate change');

  // Test with an empty task
  print('\n--- Testing with empty task ---');
  await testTask(api, '');

  // Test with a very short task
  print('\n--- Testing with short task ---');
  await testTask(api, 'Test');

  // Test direct breakdownTask method
  print('\n--- Testing breakdownTask method ---');
  final directSubtasks = await api.breakdownTask('Create a mobile app');
  print('Direct subtasks: $directSubtasks');
  print('Number of direct subtasks: ${directSubtasks.length}');

  print('\nAll tests completed successfully!');
  exit(0);
}

Future<void> testTask(TaskBreakdownAPI api, String task) async {
  print('Making API request for task: "$task"');
  final response = await api.makeRequest(task);
  print('Raw API response: $response');

  print('Parsing subtasks from response...');
  final subtasks = api.parseSubtasks(response);
  print('Generated subtasks: $subtasks');
  print('Number of subtasks: ${subtasks.length}');

  if (subtasks.isEmpty) {
    print('WARNING: No subtasks were generated.');
  } else {
    print('SUCCESS: Generated ${subtasks.length} subtasks.');
  }
}
