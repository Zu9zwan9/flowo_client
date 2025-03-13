import 'package:bloc/bloc.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:hive/hive.dart';

import '../../models/category.dart';
import '../../models/task.dart';
import '../../models/user_settings.dart';
import '../../utils/task_manager.dart';
import 'task_manager_state.dart';

class TaskManagerCubit extends Cubit<TaskManagerState> {
  final TaskManager taskManager;

  TaskManagerCubit(this.taskManager) : super(TaskManagerState.initial()) {
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  void createTask({
    required String title,
    required int priority,
    required int estimatedTime,
    required int deadline,
    required Category category,
    Task? parentTask,
    String? notes,
    int? color,
  }) {
    taskManager.createTask(
        title, priority, estimatedTime, deadline, category, parentTask, notes,
        color: color);
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  List<ScheduledTask> getScheduledTasks() {
    final scheduledTasks = <ScheduledTask>[];
    for (var day in taskManager.daysDB.values) {
      scheduledTasks.addAll(day.scheduledTasks);
    }
    return scheduledTasks;
  }

  Future<List<TaskWithSchedules>> getScheduledTasksForDate(
      DateTime date) async {
    final dateKey = _formatDateKey(date);

    final scheduledTasks = taskManager.daysDB.values
        .where((day) => day.day == dateKey)
        .expand((day) => day.scheduledTasks);

    final grouped = <Task, List<ScheduledTask>>{};
    for (var scheduledTask in scheduledTasks) {
      final task = taskManager.tasksDB.get(scheduledTask.parentTaskId);
      if (task != null) {
        grouped.putIfAbsent(task, () => []).add(scheduledTask);
      }
    }

    final result = grouped.entries
        .map((entry) => TaskWithSchedules(entry.key, entry.value))
        .toList();

    return result;
  }

  String _formatDateKey(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  void deleteTask(Task task) {
    taskManager.deleteTask(task);
    emit(state.copyWith(
        tasks: taskManager.tasksDB.values
            .toList())); // Refresh state after deletion
  }

  void scheduleTasks() {
    taskManager.scheduleTasks();
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  void scheduleTask(Task task) {
    final minSession = state.userSettings?.minSession ?? 15 * 60 * 1000;
    taskManager.scheduler.scheduleTask(task, minSession);
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  void removeScheduledTasks() {
    taskManager.removeScheduledTasks();
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  void updateUserSettings(UserSettings userSettings) {
    taskManager.updateUserSettings(userSettings);
    try {
      final settingsBox = Hive.box<UserSettings>('user_settings');
      settingsBox.put('current', userSettings);
      logInfo('User settings updated and saved');
    } catch (e) {
      logError('Failed to save user settings: $e');
    }
    _deleteAllDays();
    // removeScheduledTasks();
    scheduleTasks();
    emit(state.copyWith(
        tasks: taskManager.tasksDB.values.toList(),
        userSettings: userSettings));
  }

  void _deleteAllDays() {
    final existingDayKeys = taskManager.daysDB.keys.cast<String>().toList();
    for (var dateKey in existingDayKeys) {
      taskManager.daysDB.delete(dateKey);
      logDebug('Deleted day: $dateKey');
    }
    logInfo('All days deleted');
  }

  /// Breaks down a task into subtasks using AI and schedules them
  ///
  /// Returns a list of the created subtasks
  Future<List<Task>> breakdownAndScheduleTask(Task task) async {
    logInfo('Breaking down task using AI: ${task.title}');
    final subtasks = await taskManager.breakdownAndScheduleTask(task);
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
    return subtasks;
  }
}

class TaskWithSchedules {
  final Task task;
  final List<ScheduledTask> scheduledTasks;

  TaskWithSchedules(this.task, this.scheduledTasks);
}
