import 'dart:async';
import 'dart:io';

import 'package:flowo_client/models/category.dart' as flowo;
import 'package:flowo_client/models/day.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

// A simple script to test the EnhancedTaskManager
Future<void> main() async {
  if (kDebugMode) {
    print('Starting EnhancedTaskManager test script...');
  }

  // Initialize Hive (this would normally be done in your app's initialization)
  // Note: This is a simplified version for testing purposes
  if (kDebugMode) {
    print('Initializing Hive...');
  }

  // In a real app, you would register adapters and open boxes
  // For this test, we'll use mock boxes
  final mockDaysBox = MockBox<Day>();
  final mockTasksBox = MockBox<Task>();

  // Create user settings
  final userSettings = UserSettings(
    name: 'Default User',
    minSession: 30, // Minimum session duration in minutes
    maxSession: 120, // Maximum session duration in minutes
    workingHours: [9, 17], // Working hours (9 AM to 5 PM)
    workingDays: [1, 2, 3, 4, 5], // Working days (Monday to Friday)
  );

  // Create the enhanced task manager
  if (kDebugMode) {
    print('Creating EnhancedTaskManager...');
  }

  final taskManager = EnhancedTaskManager(
    daysDB: mockDaysBox,
    tasksDB: mockTasksBox,
    userSettings: userSettings,
    huggingFaceApiKey: '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',
  );

  // Create a test task
  if (kDebugMode) {
    print('\nCreating test task...');
  }

  final task = Task(
    id: 'test_task_1',
    title: 'Write a comprehensive research paper on climate change',
    priority: 3, // High priority
    estimatedTime: 480, // 8 hours in minutes
    deadline:
        DateTime.now()
            .add(const Duration(days: 7))
            .millisecondsSinceEpoch, // 1 week deadline
    category: flowo.Category(name: 'Work'),
  );

  // Add the task to the mock box
  mockTasksBox.put(task.id, task);

  // Break down the task into subtasks and estimate time for each subtask
  if (kDebugMode) {
    print('\nBreaking down task and estimating time for subtasks...');
  }

  final subtasks = await taskManager.breakdownAndScheduleTask(task);

  // Print the results
  if (kDebugMode) {
    print('\nTask breakdown results:');
    print('Parent task: ${task.title}');
    print('Parent estimated time: ${task.estimatedTime} minutes');
    print('Number of subtasks: ${subtasks.length}');

    if (subtasks.isNotEmpty) {
      print('\nSubtasks with AI-estimated times:');
      for (var i = 0; i < subtasks.length; i++) {
        final subtask = subtasks[i];
        print('  ${i + 1}. ${subtask.title}: ${subtask.estimatedTime} minutes');
      }

      // Calculate total estimated time
      final totalEstimatedTime = subtasks.fold(
        0,
        (sum, subtask) => sum + subtask.estimatedTime,
      );
      print('\nTotal estimated time for subtasks: $totalEstimatedTime minutes');
      print(
        'Original parent task estimated time: ${task.estimatedTime} minutes',
      );
      print('Difference: ${totalEstimatedTime - task.estimatedTime} minutes');

      if ((totalEstimatedTime - task.estimatedTime).abs() <=
          task.estimatedTime * 0.2) {
        print(
          'SUCCESS: Total estimated time is within 20% of parent task estimated time.',
        );
      } else {
        print(
          'WARNING: Total estimated time differs from parent task estimated time by more than 20%.',
        );
      }
    }
  }

  if (kDebugMode) {
    print('\nTest completed successfully!');
  }
  exit(0);
}

// Mock implementation of Box for testing
class MockBox<T> implements Box<T> {
  final Map<dynamic, T> _data = {};

  @override
  T? get(key, {T? defaultValue}) => _data[key] ?? defaultValue;

  @override
  Future<void> put(key, T value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(key) async {
    _data.remove(key);
  }

  @override
  Iterable<T> get values => _data.values;

  // Implement other methods as needed for testing
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class UserSettings {
  final String name;
  final int minSession;
  final int maxSession;
  final List<int> workingHours;
  final List<int> workingDays;

  UserSettings({
    required this.name,
    required this.minSession,
    required this.maxSession,
    required this.workingHours,
    required this.workingDays,
  });
}

class EnhancedTaskManager {
  final Box<Day> daysDB;
  final Box<Task> tasksDB;
  final UserSettings userSettings;
  final String huggingFaceApiKey;

  EnhancedTaskManager({
    required this.daysDB,
    required this.tasksDB,
    required this.userSettings,
    required this.huggingFaceApiKey,
  });

  Future<List<Task>> breakdownAndScheduleTask(Task task) async {
    // Implementation...
    return [];
  }
}
