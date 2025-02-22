import 'package:bloc/bloc.dart';
import 'package:flowo_client/models/task.dart';
import 'package:hive/hive.dart';
import 'task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  final Box<Task> taskBox;

  TaskCubit(this.taskBox) : super(TaskInitial()) {
    loadTasks();
  }

  void loadTasks() {
    final tasks = taskBox.values.toList();
    emit(TaskLoaded(tasks));
  }

  void addTask(Task task) {
    taskBox.put(task.id, task);
    loadTasks();
  }

  void updateTask(Task task) {
    task.save();
    loadTasks();
  }

  void deleteTask(String taskId) {
    taskBox.delete(taskId);
    loadTasks();
  }
}
