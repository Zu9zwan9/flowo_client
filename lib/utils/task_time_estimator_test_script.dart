import 'dart:async';
import 'dart:io';

import 'package:flowo_client/models/category.dart' as flowo;
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/services/task_time_estimator.dart';
import 'package:flutter/foundation.dart';

// A simple script to test the TaskTimeEstimator
Future<void> main() async {
  if (kDebugMode) {
    print('Starting TaskTimeEstimator test script...');
  }

  // Create an AI time estimation strategy
  final strategy = AITimeEstimationStrategy(
    apiKey: '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',
  );

  // Create a task time estimator with the AI strategy
  final estimator = TaskTimeEstimator(strategy);

  // Test with different sets of subtasks and parent task parameters
  await testEstimation(
    estimator,
    'Research Paper',
    [
      'Research the topic',
      'Create an outline',
      'Draft the content',
      'Review and revise',
      'Finalize the work',
    ],
    240, // 4 hours
    DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch,
  );

  await testEstimation(
    estimator,
    'Mobile App Development',
    [
      'Design user interface',
      'Implement core functionality',
      'Add authentication',
      'Integrate with backend',
      'Test and debug',
      'Deploy to app stores',
    ],
    1200, // 20 hours
    DateTime.now().add(const Duration(days: 14)).millisecondsSinceEpoch,
  );

  await testEstimation(
    estimator,
    'Quick Task',
    [
      'Step 1',
      'Step 2',
      'Step 3',
    ],
    30, // 30 minutes
    DateTime.now().add(const Duration(hours: 3)).millisecondsSinceEpoch,
  );

  if (kDebugMode) {
    print('\nAll tests completed successfully!');
  }
  exit(0);
}

Future<void> testEstimation(
  TaskTimeEstimator estimator,
  String taskName,
  List<String> subtaskTitles,
  int parentEstimatedTime,
  int parentDeadline,
) async {
  if (kDebugMode) {
    print('\n--- Testing estimation for "$taskName" ---');
    print('Parent task estimated time: $parentEstimatedTime minutes');
    print(
        'Parent task deadline: ${DateTime.fromMillisecondsSinceEpoch(parentDeadline)}');
    print('Subtasks:');
    for (var i = 0; i < subtaskTitles.length; i++) {
      print('  ${i + 1}. ${subtaskTitles[i]}');
    }
  }

  if (kDebugMode) {
    print('\nEstimating time for subtasks...');
  }

  final estimates = await estimator.estimateSubtaskTimes(
    subtaskTitles,
    parentEstimatedTime,
    parentDeadline,
  );

  if (kDebugMode) {
    print('Time estimates:');
    for (var i = 0; i < subtaskTitles.length; i++) {
      final estimate = i < estimates.length ? estimates[i] : 'N/A';
      print('  ${i + 1}. ${subtaskTitles[i]}: $estimate minutes');
    }

    // Calculate total estimated time
    final totalEstimatedTime = estimates.fold(0, (sum, time) => sum + time);
    print('\nTotal estimated time: $totalEstimatedTime minutes');
    print('Original parent task estimated time: $parentEstimatedTime minutes');
    print('Difference: ${totalEstimatedTime - parentEstimatedTime} minutes');

    if ((totalEstimatedTime - parentEstimatedTime).abs() <=
        parentEstimatedTime * 0.2) {
      print(
          'SUCCESS: Total estimated time is within 20% of parent task estimated time.');
    } else {
      print(
          'WARNING: Total estimated time differs from parent task estimated time by more than 20%.');
    }
  }

  // Create mock subtasks and apply estimates
  final subtasks = <Task>[];
  for (var i = 0; i < subtaskTitles.length; i++) {
    subtasks.add(Task(
      id: 'test_subtask_$i',
      title: subtaskTitles[i],
      priority: 2,
      estimatedTime: 0, // Will be set by applyEstimates
      deadline: parentDeadline,
      category: flowo.Category(name: 'Test'),
    ));
  }

  if (kDebugMode) {
    print('\nApplying estimates to subtasks...');
  }

  estimator.applyEstimates(subtasks, estimates);

  if (kDebugMode) {
    print('Subtasks with applied estimates:');
    for (var i = 0; i < subtasks.length; i++) {
      print(
          '  ${i + 1}. ${subtasks[i].title}: ${subtasks[i].estimatedTime} minutes');
    }
  }
}
