import 'package:flowo_client/utils/logger.dart';

class TaskFormData {
  DateTime selectedDate;
  DateTime selectedTime;
  String category;
  int priority;
  int estimatedTime;
  int? color;

  // PERT time estimates
  int optimisticTime;
  int realisticTime;
  int pessimisticTime;

  TaskFormData({
    required this.selectedDate,
    required this.selectedTime,
    required this.category,
    required this.priority,
    required this.estimatedTime,
    this.color,
    this.optimisticTime = 0,
    this.realisticTime = 0,
    this.pessimisticTime = 0,
  });

  /// Calculates the estimated time using the PERT formula: (O + 4R + P) / 6
  void calculateEstimatedTime() {
    if (optimisticTime > 0 && realisticTime > 0 && pessimisticTime > 0) {
      estimatedTime =
          ((optimisticTime + (4 * realisticTime) + pessimisticTime) / 6)
              .round();
    }
    logDebug('Calculated estimated time: $estimatedTime');
  }
}
