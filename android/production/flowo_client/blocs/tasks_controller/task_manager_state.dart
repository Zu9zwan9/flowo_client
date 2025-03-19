import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/models/user_settings.dart';

class TaskManagerState {
  final List<Task> tasks;
  final UserSettings? userSettings;

  TaskManagerState(this.tasks, {this.userSettings});

  factory TaskManagerState.initial() => TaskManagerState([]);

  TaskManagerState copyWith({List<Task>? tasks, UserSettings? userSettings}) {
    return TaskManagerState(
      tasks ?? this.tasks,
      userSettings: userSettings ?? this.userSettings,
    );
  }
}
