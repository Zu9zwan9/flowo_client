import 'package:hive/hive.dart';

import 'session.dart';

part 'task_session.g.dart';

/// Represents a single session of working on a task
@HiveType(typeId: 21)
class TaskSession extends Session {
  /// Unique identifier for the session
  @HiveField(0)
  @override
  final String id;

  /// ID of the task this session belongs to
  @HiveField(1)
  final String taskId;

  /// Start time of the session
  @HiveField(2)
  @override
  final DateTime startTime;

  /// End time of the session (null if session is still active)
  @HiveField(3)
  @override
  DateTime? endTime;

  /// Notes about what was accomplished during this session
  @HiveField(4)
  String? notes;

  /// Creates a new task session
  ///
  /// @param id Unique identifier for the session
  /// @param taskId ID of the task this session belongs to
  /// @param startTime Start time of the session
  /// @param endTime End time of the session (null if session is still active)
  TaskSession({
    required this.id,
    required this.taskId,
    required this.startTime,
    this.endTime,
    this.notes,
  });

  /// Returns a string representation of the task session
  @override
  String toString() {
    return 'TaskSession: {id: $id, taskId: $taskId, startTime: $startTime, endTime: $endTime, duration: ${duration}ms}';
  }
}
