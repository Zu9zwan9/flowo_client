import 'package:flowo_client/models/user_settings.dart';

import '../../models/task.dart';

class TaskManagerState {
  final List<Task> tasks;

  TaskManagerState(this.tasks);

  factory TaskManagerState.initial() => TaskManagerState([]);

  TaskManagerState copyWith({List<Task>? tasks, UserSettings? userSettings}) {
    return TaskManagerState(tasks ?? this.tasks);
  }
}
