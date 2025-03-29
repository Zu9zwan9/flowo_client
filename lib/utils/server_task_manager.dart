import 'package:flowo_client/models/user_settings.dart';
import 'package:flowo_client/utils/ai_model/server_task_breakdown_api.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flowo_client/utils/task_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

import '../models/day.dart';
import '../models/task.dart';

/// A version of TaskManager that uses server-based implementations for AI operations
class ServerTaskManager extends TaskManager {
  final ServerTaskBreakdownAPI serverTaskBreakdownAPI;

  ServerTaskManager({
    required Box<Day> daysDB,
    required Box<Task> tasksDB,
    required UserSettings userSettings,
    required this.serverTaskBreakdownAPI,
  }) : super(
         daysDB: daysDB,
         tasksDB: tasksDB,
         userSettings: userSettings,
         taskBreakdownAPI: serverTaskBreakdownAPI,
       );

  @override
  Future<List<Task>> breakdownAndScheduleTask(Task task) async {
    logInfo(
      'Breaking down task using server API: ${task.title} ${task.estimatedTime}',
    );

    // Use the server API to break down the task
    final subtaskDataList = await serverTaskBreakdownAPI.breakdownTask(
      task.title,
      task.estimatedTime.toString(),
    );

    if (subtaskDataList.isEmpty) {
      logWarning('No subtasks generated for task: ${task.title}');
      logInfo('Scheduling parent task: ${task.title}');
      scheduler.scheduleTask(task, userSettings.minSession, urgency: null);
      return [];
    }

    logInfo('Generated ${subtaskDataList.length} subtasks for: ${task.title}');

    final subtasks = <Task>[];
    int order = 1;

    for (var subtaskData in subtaskDataList) {
      // Extract title and estimatedTime from Map
      final subtaskTitle = subtaskData['title'] as String;
      final estimatedTime = subtaskData['estimatedTime'] as int;

      final subtask = Task(
        id: UniqueKey().toString(),
        title: subtaskTitle,
        priority: task.priority,
        estimatedTime: estimatedTime,
        deadline: task.deadline,
        category: task.category,
        parentTask: task,
        order: order++,
      );
      tasksDB.put(subtask.id, subtask);
      subtasks.add(subtask);
      task.subtasks.add(subtask);
    }

    tasksDB.put(task.id, task);
    scheduleSubtasks(subtasks);

    return subtasks;
  }
}
