import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'pomodoro_settings.g.dart';

/// A model class that represents customizable settings for the Pomodoro timer.
/// This follows the Open/Closed Principle by allowing extension through settings
/// without modifying the core timer logic.
@HiveType(typeId: 16)
class PomodoroSettings extends HiveObject with ChangeNotifier {
  // Focus duration in milliseconds
  @HiveField(0)
  int _focusDuration;

  // Short break duration in milliseconds
  @HiveField(1)
  int _shortBreakDuration;

  // Long break duration in milliseconds
  @HiveField(2)
  int _longBreakDuration;

  // Number of sessions before a long break
  @HiveField(3)
  int _sessionsBeforeLongBreak;

  // Whether to use auto-start for breaks and next sessions
  @HiveField(4)
  bool _autoStartBreaks;

  @HiveField(5)
  bool _autoStartNextSession;

  // Whether to use sound notifications
  @HiveField(6)
  bool _soundEnabled;

  // Whether to use vibration notifications
  @HiveField(7)
  bool _vibrationEnabled;

  // Whether to show notifications
  @HiveField(8)
  bool _notificationsEnabled;

  // Getters
  int get focusDuration => _focusDuration;
  int get shortBreakDuration => _shortBreakDuration;
  int get longBreakDuration => _longBreakDuration;
  int get sessionsBeforeLongBreak => _sessionsBeforeLongBreak;
  bool get autoStartBreaks => _autoStartBreaks;
  bool get autoStartNextSession => _autoStartNextSession;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get notificationsEnabled => _notificationsEnabled;

  // Setters with notification
  set focusDuration(int value) {
    if (value != _focusDuration) {
      _focusDuration = value;
      notifyListeners();
      save();
    }
  }

  set shortBreakDuration(int value) {
    if (value != _shortBreakDuration) {
      _shortBreakDuration = value;
      notifyListeners();
      save();
    }
  }

  set longBreakDuration(int value) {
    if (value != _longBreakDuration) {
      _longBreakDuration = value;
      notifyListeners();
      save();
    }
  }

  set sessionsBeforeLongBreak(int value) {
    if (value != _sessionsBeforeLongBreak) {
      _sessionsBeforeLongBreak = value;
      notifyListeners();
      save();
    }
  }

  set autoStartBreaks(bool value) {
    if (value != _autoStartBreaks) {
      _autoStartBreaks = value;
      notifyListeners();
      save();
    }
  }

  set autoStartNextSession(bool value) {
    if (value != _autoStartNextSession) {
      _autoStartNextSession = value;
      notifyListeners();
      save();
    }
  }

  set soundEnabled(bool value) {
    if (value != _soundEnabled) {
      _soundEnabled = value;
      notifyListeners();
      save();
    }
  }

  set vibrationEnabled(bool value) {
    if (value != _vibrationEnabled) {
      _vibrationEnabled = value;
      notifyListeners();
      save();
    }
  }

  set notificationsEnabled(bool value) {
    if (value != _notificationsEnabled) {
      _notificationsEnabled = value;
      notifyListeners();
      save();
    }
  }

  // Constructor
  PomodoroSettings({
    int focusDuration = 25 * 60 * 1000, // 25 minutes
    int shortBreakDuration = 5 * 60 * 1000, // 5 minutes
    int longBreakDuration = 15 * 60 * 1000, // 15 minutes
    int sessionsBeforeLongBreak = 4,
    bool autoStartBreaks = true,
    bool autoStartNextSession = false,
    bool soundEnabled = true,
    bool vibrationEnabled = true,
    bool notificationsEnabled = true,
  }) : _focusDuration = focusDuration,
       _shortBreakDuration = shortBreakDuration,
       _longBreakDuration = longBreakDuration,
       _sessionsBeforeLongBreak = sessionsBeforeLongBreak,
       _autoStartBreaks = autoStartBreaks,
       _autoStartNextSession = autoStartNextSession,
       _soundEnabled = soundEnabled,
       _vibrationEnabled = vibrationEnabled,
       _notificationsEnabled = notificationsEnabled;

  // Reset to default settings
  void resetToDefaults() {
    _focusDuration = 25 * 60 * 1000;
    _shortBreakDuration = 5 * 60 * 1000;
    _longBreakDuration = 15 * 60 * 1000;
    _sessionsBeforeLongBreak = 4;
    _autoStartBreaks = true;
    _autoStartNextSession = false;
    _soundEnabled = true;
    _vibrationEnabled = true;
    _notificationsEnabled = true;
    notifyListeners();
    save();
  }

  // Helper method to convert minutes to milliseconds
  static int minutesToMilliseconds(int minutes) {
    return minutes * 60 * 1000;
  }

  // Helper method to convert milliseconds to minutes
  static int millisecondsToMinutes(int milliseconds) {
    return (milliseconds / (60 * 1000)).round();
  }
}
