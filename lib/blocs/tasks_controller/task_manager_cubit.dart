import 'package:bloc/bloc.dart';
import 'package:flowo_client/blocs/tasks_controller/task_manager_state.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/utils/logger.dart';
import '../../models/category.dart';
import '../../models/task.dart';
import '../../utils/task_manager.dart';

class TaskManagerCubit extends Cubit<TaskManagerState> {
  final TaskManager taskManager;

  TaskManagerCubit(this.taskManager) : super(TaskManagerState.initial()) {
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  void createTask(String title, int priority, int estimatedTime, int deadline,
      Category category, Task? parentTask) {
    taskManager.createTask(
        title, priority, estimatedTime, deadline, category, parentTask);
    emit(state.copyWith(tasks: taskManager.tasksDB.values.toList()));
  }

  List<ScheduledTask> getScheduledTasks() {
    final List<ScheduledTask> scheduledTasks = [];
    for (var day in taskManager.daysDB.values) {
      logDebug(day.scheduledTasks.toString());
      scheduledTasks.addAll(day.scheduledTasks);
    }

    return scheduledTasks;
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
}
