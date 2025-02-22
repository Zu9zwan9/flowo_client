import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../../models/task.dart';
import '../../models/scheduled_task.dart';
import 'calendar_state.dart';
import '../../utils/logger.dart';

class CalendarCubit extends Cubit<CalendarState> {
  final Box<Task> taskBox;
  final Box<ScheduledTask> scheduledTaskBox;

  CalendarCubit(this.taskBox, this.scheduledTaskBox)
      : super(CalendarState(selectedDate: DateTime.now())) {
    logInfo('CalendarCubit initialized');
    _loadTasks();
  }
  Future<List<Task>> getTasksForDay(DateTime day) async {
    return taskBox.values.where((task) {
      final taskDeadline = DateTime.fromMillisecondsSinceEpoch(task.deadline);
      return taskDeadline.year == day.year &&
          taskDeadline.month == day.month &&
          taskDeadline.day == day.day;
    }).toList();
  }

  void _loadTasks() {
    final tasks = taskBox.values.toList();
    logDebug('Loaded ${tasks.length} tasks from Hive');
    emit(state.copyWith(tasks: tasks, status: CalendarStatus.success));
  }

  void selectDate(DateTime date) {
    logDebug('Selected date: $date');
    emit(state.copyWith(selectedDate: date));
  }

  Future<void> addTask(Task task) async {
    logInfo('Adding task: ${task.title}');
    await taskBox.add(task);
    logDebug('Task added: ${task.title}');
    _loadTasks();
  }

  Future<void> updateTask(Task task) async {
    logInfo('Updating task: ${task.title}');
    await taskBox.put(task.id, task);
    logDebug('Task updated: ${task.title}');
    _loadTasks();
  }

  Future<void> deleteTask(String taskId) async {
    logWarning('Deleting task with ID: $taskId');
    await taskBox.delete(taskId);
    logDebug('Task deleted with ID: $taskId');
    _loadTasks();
  }

  Future<List<ScheduledTask>> getTasksForSelectedDate() async {
    final startOfDay = DateTime(
      state.selectedDate.year,
      state.selectedDate.month,
      state.selectedDate.day,
    );
    final endOfDay = DateTime(
      state.selectedDate.year,
      state.selectedDate.month,
      state.selectedDate.day,
      23,
      59,
      59,
    );

    final tasksForSelectedDate = scheduledTaskBox.values.where((scheduledTask) {
      final taskStartTime = scheduledTask.startTime;
      return taskStartTime
              .isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
          taskStartTime.isBefore(endOfDay.add(const Duration(seconds: 1)));
    }).toList();

    if (tasksForSelectedDate.isEmpty) {
      logDebug('No tasks found for ${state.selectedDate}');
    } else {
      logDebug(
          'Found ${tasksForSelectedDate.length} tasks for ${state.selectedDate}');
    }
    return tasksForSelectedDate;
  }

  Future<Map<String, List<Task>>> getTasksGroupedByCategory() async {
    final tasks = taskBox.values.toList();
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
}
