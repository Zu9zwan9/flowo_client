import '../../models/task.dart';

class TaskManagerState {
  final List<Task> tasks;

  TaskManagerState(this.tasks);

  factory TaskManagerState.initial() => TaskManagerState([]);

  TaskManagerState copyWith({List<Task>? tasks}) {
    return TaskManagerState(tasks ?? this.tasks);
  }
}
