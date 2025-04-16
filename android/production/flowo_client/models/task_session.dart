import 'package:hive/hive.dart';

part 'task_session.g.dart';

/// Represents a single session of working on a task
@HiveType(typeId: 21)
class TaskSession extends HiveObject {
  /// Unique identifier for the session
  @HiveField(0)
  final String id;

  /// ID of the task this session belongs to
  @HiveField(1)
  final String taskId;

  /// Start time of the session
  @HiveField(2)
  final DateTime startTime;

  /// End time of the session (null if session is still active)
  @HiveField(3)
  DateTime? endTime;

  /// Duration of the session in milliseconds
  /// This is calculated as the difference between endTime and startTime
  /// If endTime is null (session is active), this returns the duration until now
  int get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inMilliseconds;
  }

  TaskSession({
    required this.id,
    required this.taskId,
    required this.startTime,
    this.endTime,
  });

  /// Ends the current session
  void end() {
    if (endTime == null) {
      endTime = DateTime.now();
      // Only save if the object is in a box
      if (isInBox) {
        save();
      }
    }
  }

  /// Checks if the session is currently active
  bool get isActive => endTime == null;

  @override
  String toString() {
    return 'TaskSession: {id: $id, taskId: $taskId, startTime: $startTime, endTime: $endTime, duration: ${duration}ms}';
  }
}
