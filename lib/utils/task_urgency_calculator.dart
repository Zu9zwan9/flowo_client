import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/models/days.dart';
import 'package:hive/hive.dart';

class TaskUrgencyCalculator {
  final Box<Days> daysDB;

  TaskUrgencyCalculator(this.daysDB);

  void calculateUrgency(List<Task> tasks) {
    for (var task in tasks) {
      final timeLeft = task.deadline - DateTime.now().millisecondsSinceEpoch;
      final trueTimeLeft = timeLeft - _busyTime();
      final timeCoefficient = (trueTimeLeft - task.estimatedTime) *
          (trueTimeLeft + task.estimatedTime);
      task.urgency = task.priority * 10 / timeCoefficient;

      if (task.urgency < 0) {
        _negativeUrgencyHandler(task);
      }
    }
    tasks.sort((a, b) => b.urgency.compareTo(a.urgency));
  }

  void _negativeUrgencyHandler(Task task) {
    final timeLeft = task.deadline - DateTime.now().millisecondsSinceEpoch;
    if (timeLeft - task.estimatedTime < 0) {
      task.overdue = true;
      task.deadline += 24 * 60 * 60 * 1000; // Extend deadline by one day
      calculateUrgency([task]);
    }
  }

  int _busyTime() {
    int busyTime = 0;
    for (var day in daysDB.values) {
      for (var timeRange in day.timeRanges) {
        busyTime += timeRange.end.difference(timeRange.start).inMilliseconds;
      }
    }
    return busyTime;
  }
}
