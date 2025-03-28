import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'task.dart';

part 'pomodoro_session.g.dart';

@HiveType(typeId: 14)
enum PomodoroState {
  @HiveField(0)
  initial,
  @HiveField(1)
  running,
  @HiveField(2)
  paused,
  @HiveField(3)
  breakTime,
  @HiveField(4)
  completed,
}

@HiveType(typeId: 15)
class PomodoroSession extends HiveObject with ChangeNotifier {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? taskId;

  @HiveField(2)
  int totalDuration; // in milliseconds

  @HiveField(3)
  int remainingDuration; // in milliseconds

  @HiveField(4)
  int breakDuration; // in milliseconds

  @HiveField(5)
  int remainingBreakDuration; // in milliseconds

  @HiveField(6)
  int completedPomodoros;

  @HiveField(7)
  int targetPomodoros;

  @HiveField(8)
  DateTime startTime;

  @HiveField(9)
  DateTime? endTime;

  // Non-persisted properties
  PomodoroState _state = PomodoroState.initial;
  PomodoroState get state => _state;
  set state(PomodoroState value) {
    _state = value;
    notifyListeners();
  }

  Task? get task => taskId != null ? Hive.box<Task>('tasks').get(taskId) : null;

  PomodoroSession({
    required this.id,
    this.taskId,
    required this.totalDuration,
    required this.breakDuration,
    this.completedPomodoros = 0,
    this.targetPomodoros = 1,
    DateTime? startTime,
  }) : remainingDuration = totalDuration,
       remainingBreakDuration = breakDuration,
       startTime = startTime ?? DateTime.now();

  // Create a Pomodoro session from a task
  factory PomodoroSession.fromTask(
    Task task, {
    int? customDuration,
    int breakDuration = 5 * 60 * 1000, // 5 minutes in milliseconds
    int targetPomodoros = 1,
  }) {
    return PomodoroSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskId: task.id,
      totalDuration: customDuration ?? task.estimatedTime,
      breakDuration: breakDuration,
      targetPomodoros: targetPomodoros,
    );
  }

  // Create a custom Pomodoro session without a task
  factory PomodoroSession.custom({
    required int duration,
    int breakDuration = 5 * 60 * 1000, // 5 minutes in milliseconds
    int targetPomodoros = 1,
  }) {
    return PomodoroSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      totalDuration: duration,
      breakDuration: breakDuration,
      targetPomodoros: targetPomodoros,
    );
  }

  void start() {
    state = PomodoroState.running;
  }

  void pause() {
    state = PomodoroState.paused;
  }

  void resume() {
    state = PomodoroState.running;
  }

  void reset() {
    remainingDuration = totalDuration;
    remainingBreakDuration = breakDuration;
    state = PomodoroState.initial;
    notifyListeners();
  }

  void tick(int milliseconds) {
    if (state == PomodoroState.running) {
      remainingDuration -= milliseconds;
      if (remainingDuration <= 0) {
        remainingDuration = 0;
        completedPomodoros++;

        if (completedPomodoros >= targetPomodoros) {
          state = PomodoroState.completed;
          endTime = DateTime.now();
        } else {
          state = PomodoroState.breakTime;
        }
      }
      notifyListeners();
    } else if (state == PomodoroState.breakTime) {
      remainingBreakDuration -= milliseconds;
      if (remainingBreakDuration <= 0) {
        remainingBreakDuration = 0;
        remainingDuration = totalDuration;
        state = PomodoroState.running;
      }
      notifyListeners();
    }
  }

  void completeEarly() {
    state = PomodoroState.completed;
    endTime = DateTime.now();
    notifyListeners();
  }

  // Skip the current work session and move to break
  void skipToBreak() {
    if (state == PomodoroState.running) {
      remainingDuration = 0;
      completedPomodoros++;

      if (completedPomodoros >= targetPomodoros) {
        state = PomodoroState.completed;
        endTime = DateTime.now();
      } else {
        state = PomodoroState.breakTime;
      }
      notifyListeners();
    }
  }

  // Skip the current break and start a new work session
  void skipBreak() {
    if (state == PomodoroState.breakTime) {
      remainingBreakDuration = 0;
      remainingDuration = totalDuration;
      state = PomodoroState.running;
      notifyListeners();
    }
  }

  double get progress {
    return 1.0 - (remainingDuration / totalDuration);
  }

  double get breakProgress {
    return 1.0 - (remainingBreakDuration / breakDuration);
  }
}
