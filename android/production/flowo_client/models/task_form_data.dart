import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/utils/logger.dart';

class TaskFormData {
  DateTime selectedDateTime;
  String category;
  int priority;
  int estimatedTime;
  int? color;
  int optimisticTime;
  int realisticTime;
  int pessimisticTime;

  TaskFormData({
    required this.selectedDateTime,
    required this.category,
    required this.priority,
    required this.estimatedTime,
    this.color,
    this.optimisticTime = 0,
    this.realisticTime = 0,
    this.pessimisticTime = 0,
  });

  factory TaskFormData.fromTask(Task task) {
    return TaskFormData(
      selectedDateTime: DateTime.fromMillisecondsSinceEpoch(task.deadline),
      category: task.category.name,
      priority: task.priority,
      estimatedTime: task.estimatedTime,
      color: task.color,
      optimisticTime: task.optimisticTime ?? 0,
      realisticTime: task.realisticTime ?? 0,
      pessimisticTime: task.pessimisticTime ?? 0,
    );
  }

  void calculateEstimatedTime() {
    if (optimisticTime > 0 && realisticTime > 0 && pessimisticTime > 0) {
      estimatedTime = ((optimisticTime + 4 * realisticTime + pessimisticTime) ~/ 6);
    }
  }
}
