import 'package:flowo_client/models/day.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../../models/scheduled_task.dart';
import '../../models/task.dart';
import '../../utils/logger.dart';
import '../../utils/task_manager.dart';
import 'tasks_controller_state.dart';

class CalendarCubit extends Cubit<CalendarState> {
  final Box<Task> tasksDB;
  final Box<Day> daysDB;
  final TaskManager taskManager;

  CalendarCubit(this.tasksDB, this.daysDB, this.taskManager)
      : super(CalendarState(selectedDate: DateTime.now())) {
    logInfo('CalendarCubit initialized');
    _loadTasks();
  }

  void _loadTasks() {
    final tasks = tasksDB.values.toList();
    logDebug('Loaded ${tasks.length} tasks from Hive');
    emit(state.copyWith(tasks: tasks, status: CalendarStatus.success));
  }

  void selectDate(DateTime date) {
    logDebug('Selected date: $date');
    emit(state.copyWith(selectedDate: date));
  }

  Future<void> addTask(Task task) async {
    logInfo('Adding task: ${task.title}');
    await tasksDB.add(task);
    logDebug('Task added: ${task.title}');
    _loadTasks();
  }

  Future<void> updateTask(Task task) async {
    logInfo('Updating task: ${task.title}');
    await tasksDB.put(task.id, task);
    logDebug('Task updated: ${task.title}');
    _loadTasks();
  }

  Future<void> deleteTask(String taskId) async {
    logWarning('Deleting task with ID: $taskId');
    await tasksDB.delete(taskId);
    logDebug('Task deleted with ID: $taskId');
    _loadTasks();
  }

  Future<List<ScheduledTask>> getScheduledTasksForSelectedDate() async {
    final date = _formatDateKey(state.selectedDate);
    List<ScheduledTask> tasksForSelectedDate = [];
    for (Day day in daysDB.values) {
      if (day.day == date) {
        tasksForSelectedDate = day.scheduledTasks;
      }
    }

    if (tasksForSelectedDate.isEmpty) {
      logDebug('No tasks found for ${state.selectedDate}');
    } else {
      logDebug(
          'Found ${tasksForSelectedDate.length} tasks for ${state.selectedDate}');
    }
    return tasksForSelectedDate;
  }

  Future<List<Task>> getTasksForDay(DateTime day) async {
    return tasksDB.values.where((task) {
      final taskDeadline = DateTime.fromMillisecondsSinceEpoch(task.deadline);
      return taskDeadline.year == day.year &&
          taskDeadline.month == day.month &&
          taskDeadline.day == day.day;
    }).toList();
  }

  Future<Map<String, List<Task>>> getTasksGroupedByCategory() async {
    final tasks = tasksDB.values.toList();
    final Map<String, List<Task>> groupedTasks = {};
    for (var task in tasks) {
      if (!groupedTasks.containsKey(task.category.name)) {
        groupedTasks[task.category.name] = [];
      }
      groupedTasks[task.category.name]!.add(task);
    }
    logDebug('Tasks grouped by category: ${groupedTasks.keys.length}');
    return groupedTasks;
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}
