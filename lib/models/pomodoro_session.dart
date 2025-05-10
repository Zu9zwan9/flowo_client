import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'session.dart';
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
class PomodoroSession extends Session {
  @HiveField(0)
  @override
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
  @override
  DateTime startTime;

  @HiveField(9)
  @override
  DateTime? endTime;

  // Non-persisted properties
  PomodoroState _state = PomodoroState.initial;

  /// Gets the current state of the Pomodoro session
  PomodoroState get state => _state;

  /// Sets the current state of the Pomodoro session and notifies listeners
  set state(PomodoroState value) {
    _state = value;
    notifyListeners();
  }

  /// Gets the task associated with this session, if any
  Task? get task => taskId != null ? Hive.box<Task>('tasks').get(taskId) : null;

  /// Creates a new Pomodoro session
  ///
  /// @param id Unique identifier for the session
  /// @param taskId Optional ID of the task this session belongs to
  /// @param totalDuration Total duration of the work period in milliseconds
  /// @param breakDuration Duration of the break period in milliseconds
  /// @param completedPomodoros Number of completed pomodoros (default: 0)
  /// @param targetPomodoros Target number of pomodoros to complete (default: 1)
  /// @param startTime Start time of the session (default: now)
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

  /// Creates a Pomodoro session from a task
  ///
  /// This factory method creates a session with appropriate durations based on the task.
  /// It can use a custom duration, the task's estimated time, or calculate sessions based on focus duration.
  factory PomodoroSession.fromTask(
    Task task, {
    int? customDuration,
    int breakDuration = 5 * 60 * 1000, // 5 minutes in milliseconds
    int targetPomodoros = 1,
    int? focusDuration,
  }) {
    // If customDuration is provided, use it for a single session
    if (customDuration != null) {
      return PomodoroSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        taskId: task.id,
        totalDuration: customDuration,
        breakDuration: breakDuration,
        targetPomodoros: targetPomodoros,
      );
    }

    // If focusDuration is provided, calculate the number of sessions needed
    if (focusDuration != null && focusDuration > 0) {
      // Calculate how many full focus sessions are needed
      int sessionsNeeded = (task.estimatedTime / focusDuration).ceil();

      // Use the calculated number of sessions or the provided targetPomodoros, whichever is larger
      int calculatedTargetPomodoros = sessionsNeeded > 0 ? sessionsNeeded : 1;
      int finalTargetPomodoros =
          calculatedTargetPomodoros > targetPomodoros
              ? calculatedTargetPomodoros
              : targetPomodoros;

      return PomodoroSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        taskId: task.id,
        totalDuration: focusDuration,
        breakDuration: breakDuration,
        targetPomodoros: finalTargetPomodoros,
      );
    }

    // Default case: use task's estimated time for a single session
    return PomodoroSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      taskId: task.id,
      totalDuration: task.estimatedTime,
      breakDuration: breakDuration,
      targetPomodoros: targetPomodoros,
    );
  }

  /// Creates a custom Pomodoro session without a task
  ///
  /// This factory method creates a session with the specified duration and parameters.
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

  /// Starts the Pomodoro session
  void start() {
    state = PomodoroState.running;
  }

  /// Pauses the Pomodoro session
  void pause() {
    state = PomodoroState.paused;
  }

  /// Resumes the Pomodoro session after it was paused
  void resume() {
    state = PomodoroState.running;
  }

  /// Resets the Pomodoro session to its initial state
  ///
  /// This resets the remaining durations and state without ending the session.
  void reset() {
    remainingDuration = totalDuration;
    remainingBreakDuration = breakDuration;
    state = PomodoroState.initial;
    notifyListeners();
  }

  /// Updates the timer state based on elapsed time
  void tick(int milliseconds) {
    if (state == PomodoroState.running) {
      remainingDuration -= milliseconds;
      if (remainingDuration <= 0) {
        remainingDuration = 0;
        completedPomodoros++;

        if (completedPomodoros >= targetPomodoros) {
          end(); // Use the end() method to set state and endTime
        } else {
          remainingBreakDuration =
              breakDuration; // Reset break duration when transitioning to break
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

  /// Overrides the base class end() method to set the state to completed
  @override
  void end() {
    if (endTime == null) {
      state = PomodoroState.completed;
      super.end();
    }
  }

  /// Completes the session early
  void completeEarly() {
    state = PomodoroState.completed;
    super.end();
  }

  /// Skip the current work session and move to break
  void skipToBreak() {
    if (state == PomodoroState.running) {
      remainingDuration = 0;
      completedPomodoros++;

      if (completedPomodoros >= targetPomodoros) {
        end(); // Use the end() method to set state and endTime
      } else {
        remainingBreakDuration =
            breakDuration; // Reset break duration when transitioning to break
        state = PomodoroState.breakTime;
      }
      notifyListeners();
    }
  }

  /// Skips the current break and starts a new work session
  void skipBreak() {
    if (state == PomodoroState.breakTime) {
      remainingBreakDuration = 0;
      remainingDuration = totalDuration;
      state = PomodoroState.running;
      notifyListeners();
    }
  }

  /// Gets the progress of the current work session as a value between 0.0 and 1.0
  double get progress {
    return 1.0 - (remainingDuration / totalDuration);
  }

  /// Gets the progress of the current break as a value between 0.0 and 1.0
  double get breakProgress {
    return 1.0 - (remainingBreakDuration / breakDuration);
  }
}
