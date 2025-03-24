import 'dart:async';
import 'dart:io';

import 'package:flowo_client/models/category.dart' as flowo;
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/models/taskation_scheduler.dart';
import 'package:flutter/foundation.dart'; // A simple script to test the TaskationScheduler

Future<void> main() async {
  if (kDebugMode) {
    print('Starting TaskationScheduler test script...');
  }

  // Create a TaskationScheduler
  final scheduler = TaskationScheduler();

  // Test estimateTaskTime
  if (kDebugMode) {
    print('\n--- Testing estimateTaskTime ---');
  }

  // Create a task with no estimated time
  final task = Task(
    id: 'test_task_1',
    title: 'Write a comprehensive research paper on climate change',
    priority: 3, // High priority
    estimatedTime: 0, // No estimated time
    deadline:
        DateTime.now()
            .add(const Duration(days: 7))
            .millisecondsSinceEpoch, // 1 week deadline
    category: flowo.Category(name: 'Work'),
  );

  // Estimate time for the task
  final estimatedTime = scheduler.estimateTaskTime(task);
  if (kDebugMode) {
    print('Estimated time for task "${task.title}": $estimatedTime minutes');
  }

  // Test estimateSubtaskTimes
  if (kDebugMode) {
    print('\n--- Testing estimateSubtaskTimes ---');
  }

  // Create a parent task with estimated time
  final parentTask = Task(
    id: 'parent_task',
    title: 'Complete project',
    priority: 2,
    estimatedTime: 240, // 4 hours
    deadline:
        DateTime.now().add(const Duration(days: 5)).millisecondsSinceEpoch,
    category: flowo.Category(name: 'Project'),
  );

  // Create subtasks
  final subtask1 = Task(
    id: 'subtask_1',
    title: 'Research',
    priority: 2,
    estimatedTime: 0,
    deadline: parentTask.deadline,
    category: parentTask.category,
    parentTask: parentTask,
  );

  final subtask2 = Task(
    id: 'subtask_2',
    title: 'Implementation',
    priority: 3,
    estimatedTime: 0,
    deadline: parentTask.deadline,
    category: parentTask.category,
    parentTask: parentTask,
  );

  final subtask3 = Task(
    id: 'subtask_3',
    title: 'Testing and documentation',
    priority: 2,
    estimatedTime: 0,
    deadline: parentTask.deadline,
    category: parentTask.category,
    parentTask: parentTask,
  );

  // Add subtasks to parent task
  parentTask.subtasks.add(subtask1);
  parentTask.subtasks.add(subtask2);
  parentTask.subtasks.add(subtask3);

  // Estimate times for subtasks
  final subtaskEstimates = scheduler.estimateSubtaskTimes(parentTask);
  if (kDebugMode) {
    print('Subtask estimates:');
    for (final entry in subtaskEstimates.entries) {
      final subtask = parentTask.subtasks.firstWhere((s) => s.id == entry.key);
      print('  ${subtask.title}: ${entry.value} minutes');
    }

    // Calculate total estimated time
    final totalEstimatedTime = subtaskEstimates.values.fold(
      0,
      (sum, time) => sum + time,
    );
    print('Total estimated time: $totalEstimatedTime minutes');
    print('Parent task estimated time: ${parentTask.estimatedTime} minutes');
  }

  // Apply estimates to subtasks
  scheduler.applySubtaskEstimates(parentTask.subtasks, subtaskEstimates);
  if (kDebugMode) {
    print('\nAfter applying estimates:');
    for (final subtask in parentTask.subtasks) {
      print('  ${subtask.title}: ${subtask.estimatedTime} minutes');
    }
  }

  // Test optimizeSchedule
  if (kDebugMode) {
    print('\n--- Testing optimizeSchedule ---');
  }

  // Create a list of tasks to schedule
  final tasksToSchedule = [
    Task(
      id: 'task_1',
      title: 'Urgent task',
      priority: 3,
      estimatedTime: 60,
      deadline:
          DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
      category: flowo.Category(name: 'Urgent'),
    ),
    Task(
      id: 'task_2',
      title: 'Important task',
      priority: 2,
      estimatedTime: 120,
      deadline:
          DateTime.now().add(const Duration(days: 2)).millisecondsSinceEpoch,
      category: flowo.Category(name: 'Important'),
    ),
    Task(
      id: 'task_3',
      title: 'Regular task',
      priority: 1,
      estimatedTime: 90,
      deadline:
          DateTime.now().add(const Duration(days: 3)).millisecondsSinceEpoch,
      category: flowo.Category(name: 'Regular'),
    ),
  ];

  // Optimize schedule
  final scheduledTasks = scheduler.optimizeSchedule(tasksToSchedule);
  if (kDebugMode) {
    print('Scheduled tasks:');
    for (var i = 0; i < scheduledTasks.length; i++) {
      final scheduledTask = scheduledTasks[i];
      final task = tasksToSchedule.firstWhere(
        (t) => t.id == scheduledTask.parentTaskId,
      );
      print('  ${i + 1}. ${task.title}');
      print('     Start: ${scheduledTask.startTime}');
      print('     End: ${scheduledTask.endTime}');
      print(
        '     Duration: ${scheduledTask.endTime.difference(scheduledTask.startTime).inMinutes} minutes',
      );
    }
  }

  if (kDebugMode) {
    print('\nAll tests completed successfully!');
  }
  exit(0);
}
