import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../../models/pomodoro_session.dart';
import '../../models/pomodoro_settings.dart';
import '../../models/pomodoro_statistics.dart';
import '../../models/task.dart';

/// A service class that manages the Pomodoro timer logic.
/// This class follows the Single Responsibility Principle by focusing only on timer management.
class PomodoroTimerService extends ChangeNotifier {
  // Timer state
  PomodoroSession? _currentSession;
  Timer? _timer;
  DateTime? _pausedAt;

  // Settings
  final PomodoroSettings _settings;

  // Statistics
  final PomodoroStatistics _statistics;
  int _completedSessions = 0;
  int _totalFocusTime = 0;
  DateTime? _sessionStartTime;

  // Constructor
  PomodoroTimerService({
    required PomodoroSettings settings,
    required PomodoroStatistics statistics,
  }) : _settings = settings,
       _statistics = statistics {
    // Listen for settings changes
    _settings.addListener(() {
      notifyListeners();
    });
  }

  // Getters
  PomodoroSession? get currentSession => _currentSession;
  bool get isRunning => _currentSession?.state == PomodoroState.running;
  bool get isPaused => _currentSession?.state == PomodoroState.paused;
  bool get isBreak => _currentSession?.state == PomodoroState.breakTime;
  bool get isCompleted => _currentSession?.state == PomodoroState.completed;
  bool get isInitial => _currentSession?.state == PomodoroState.initial;
  int get completedSessions => _completedSessions;
  int get totalFocusTime => _totalFocusTime;
  bool get isLongBreakDue =>
      _completedSessions % _settings.sessionsBeforeLongBreak == 0 &&
      _completedSessions > 0;

  // Initialize a new session
  void initSession({
    Task? task,
    int? customDuration,
    Box<PomodoroSession>? pomodoroBox,
  }) {
    // Cancel any existing timer
    _timer?.cancel();

    // Create a new session
    if (task != null) {
      _currentSession = PomodoroSession.fromTask(
        task,
        customDuration: customDuration,
        breakDuration:
            isLongBreakDue
                ? _settings.longBreakDuration
                : _settings.shortBreakDuration,
        focusDuration: _settings.focusDuration,
      );
    } else if (customDuration != null) {
      _currentSession = PomodoroSession.custom(
        duration: customDuration,
        breakDuration:
            isLongBreakDue
                ? _settings.longBreakDuration
                : _settings.shortBreakDuration,
      );
    } else {
      _currentSession = PomodoroSession.custom(
        duration: _settings.focusDuration,
        breakDuration:
            isLongBreakDue
                ? _settings.longBreakDuration
                : _settings.shortBreakDuration,
      );
    }

    // Save the session to Hive if a box is provided
    if (pomodoroBox != null) {
      pomodoroBox.put(_currentSession!.id, _currentSession!);
    }

    // Listen for state changes
    _currentSession!.addListener(() {
      notifyListeners();
    });

    notifyListeners();
  }

  // Start the timer
  void startTimer() {
    if (_currentSession == null) return;

    _currentSession!.start();
    _sessionStartTime = DateTime.now();

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      PomodoroState previousState = _currentSession!.state;
      _currentSession!.tick(100);
      PomodoroState currentState = _currentSession!.state;

      // Handle state transitions
      if (currentState == PomodoroState.completed) {
        _timer?.cancel();
        _updateStatistics();
      } else if (previousState == PomodoroState.running &&
          currentState == PomodoroState.breakTime) {
        // Ensure break duration is properly set when transitioning to break state
        _currentSession!.remainingBreakDuration =
            _currentSession!.breakDuration;
      }
    });

    notifyListeners();
  }

  // Pause the timer
  void pauseTimer() {
    if (_currentSession == null) return;

    _currentSession!.pause();
    _pausedAt = DateTime.now();
    _timer?.cancel();

    notifyListeners();
  }

  // Resume the timer
  void resumeTimer() {
    if (_currentSession == null) return;

    _currentSession!.resume();
    startTimer();

    notifyListeners();
  }

  // Reset the timer
  void resetTimer() {
    if (_currentSession == null) return;

    _timer?.cancel();
    _currentSession!.reset();

    notifyListeners();
  }

  // Complete the session early
  void completeEarly() {
    if (_currentSession == null) return;

    _timer?.cancel();
    _currentSession!.completeEarly();
    _updateStatistics();

    notifyListeners();
  }

  // Skip the current work session and move to break
  void skipToBreak() {
    if (_currentSession == null) return;

    _currentSession!.skipToBreak();

    // If the session is now completed, update statistics
    if (_currentSession!.state == PomodoroState.completed) {
      _updateStatistics();
    } else if (_currentSession!.state == PomodoroState.breakTime) {
      // Ensure break duration is properly set when transitioning to break state
      _currentSession!.remainingBreakDuration = _currentSession!.breakDuration;
    }

    notifyListeners();
  }

  // Skip the current break and start a new work session
  void skipBreak() {
    if (_currentSession == null) return;

    _currentSession!.skipBreak();
    notifyListeners();
  }

  // Handle app lifecycle changes
  void handleAppLifecycleChange(AppLifecycleState state) {
    if (_currentSession == null) return;

    if (state == AppLifecycleState.paused) {
      // App is in background
      if (_currentSession!.state == PomodoroState.running) {
        _pausedAt = DateTime.now();
        pauseTimer();
      }
    } else if (state == AppLifecycleState.resumed) {
      // App is in foreground
      if (_currentSession!.state == PomodoroState.paused && _pausedAt != null) {
        final now = DateTime.now();
        final elapsedMillis = now.difference(_pausedAt!).inMilliseconds;

        // If more than 5 minutes have passed, don't auto-resume
        if (elapsedMillis <= 5 * 60 * 1000) {
          resumeTimer();
        }
        _pausedAt = null;
      }
    }
  }

  // Update statistics when a session is completed
  void _updateStatistics() {
    _completedSessions++;

    if (_sessionStartTime != null) {
      final now = DateTime.now();
      final sessionDuration = now.difference(_sessionStartTime!).inMilliseconds;
      _totalFocusTime += sessionDuration;
      _sessionStartTime = null;
    }

    notifyListeners();
  }

  // Format time for display
  String formatTime(int milliseconds) {
    final minutes = (milliseconds / 60000).floor();
    final seconds = ((milliseconds % 60000) / 1000).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Clean up resources
  @override
  void dispose() {
    _timer?.cancel();
    _currentSession?.removeListener(() {});
    super.dispose();
  }
}
