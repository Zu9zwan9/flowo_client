import 'package:bloc/bloc.dart';
import 'package:flowo_client/blocs/tasks_controller/task_manager_state.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:hive/hive.dart';

import '../../models/category.dart';
import '../../models/task.dart';
import '../../models/user_settings.dart';
import '../../utils/task_manager.dart';

class TaskManagerCubit extends Cubit<TaskManagerState> {
  final TaskManager taskManager;

  TaskManagerCubit(this.taskManager) : super(TaskManagerState.initial()) {
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  void createTask(
      {required String title,
      required int priority,
      required int estimatedTime,
      required int deadline,
      required Category category,
      Task? parentTask,
      String? notes}) {
    taskManager.createTask(
        title, priority, estimatedTime, deadline, category, parentTask, notes);
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  List<ScheduledTask> getScheduledTasks() {
    final List<ScheduledTask> scheduledTasks = [];
    for (var day in taskManager.daysDB.values) {
      scheduledTasks.addAll(day.scheduledTasks);
    }

    return scheduledTasks;
  }

  Future<Map<Task, ScheduledTask>> getScheduledTasksForDate(
      DateTime date) async {
    var dateKey = _formatDateKey(date);
    final List<ScheduledTask> scheduledTasks = [];
    final Map<Task, ScheduledTask> data = {};
    for (var day in taskManager.daysDB.values) {
      if (day.day == dateKey) {
        scheduledTasks.addAll(day.scheduledTasks);
      }
    }

    for (var scheduledTask in scheduledTasks) {
      final task = taskManager.tasksDB.get(scheduledTask.parentTaskId);
      if (task != null) {
        data[task] = scheduledTask;
      }
    }

    return data;
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  void deleteTask(Task task) {
    taskManager.deleteTask(task);
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  void manageTasks() {
    taskManager.manageTasks();
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  void manageHabits() {
    taskManager.manageHabits();
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  void removeScheduledTasks() {
    taskManager.removeScheduledTasks();
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  void updateUserSettings(UserSettings userSettings) {
    // Update the user settings in the task manager

    taskManager.updateUserSettings(userSettings);

    // If you're storing settings in a Hive box, you should save them
    try {
      final settingsBox = Hive.box<UserSettings>('user_settings');
      settingsBox.put('current', userSettings);
      logInfo('User settings updated and saved to storage');
    } catch (e) {
      logError('Failed to save user settings: $e');
    }

    // Regenerate days with new settings
    _regenerateDaysWithNewSettings();

    // Reschedule tasks with new settings
    removeScheduledTasks();
    manageTasks();

    // Emit updated state
    emit(state.copyWith(userSettings: userSettings));
  }

  void _regenerateDaysWithNewSettings() {
    // Get all existing day keys
    List<String> existingDayKeys =
        taskManager.daysDB.keys.cast<String>().toList();

    // For each day, recreate it with new settings
    for (String dateKey in existingDayKeys) {
      // Remove the old day
      taskManager.daysDB.delete(dateKey);

      // The next time the day is accessed, it will be created with new settings
      // This leverages the _getOrCreateDay method in Scheduler
      logDebug('Regenerated day: $dateKey with new user settings');
    }

    logInfo('All days regenerated with new user settings');
  }
}
