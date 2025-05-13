import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'pomodoro_statistics.g.dart';

/// A model class that represents statistics for Pomodoro sessions.
@HiveType(typeId: 18)
class PomodoroStatistics extends HiveObject with ChangeNotifier {
  // Total completed sessions
  @HiveField(0)
  int _totalSessions;

  // Total focus time in milliseconds
  @HiveField(1)
  int _totalFocusTime;

  // Daily session counts, stored as a map of date string (yyyy-MM-dd) to session count
  @HiveField(2)
  Map<String, int> _dailySessions;

  // Daily focus time, stored as a map of date string (yyyy-MM-dd) to focus time in milliseconds
  @HiveField(3)
  Map<String, int> _dailyFocusTime;

  // Longest streak (consecutive days with at least one completed session)
  @HiveField(4)
  int _longestStreak;

  // Current streak
  @HiveField(5)
  int _currentStreak;

  // Last session date
  @HiveField(6)
  DateTime? _lastSessionDate;

  // Getters
  int get totalSessions => _totalSessions;
  int get totalFocusTime => _totalFocusTime;
  Map<String, int> get dailySessions => Map.unmodifiable(_dailySessions);
  Map<String, int> get dailyFocusTime => Map.unmodifiable(_dailyFocusTime);
  int get longestStreak => _longestStreak;
  int get currentStreak => _currentStreak;
  DateTime? get lastSessionDate => _lastSessionDate;

  // Constructor
  PomodoroStatistics({
    int totalSessions = 0,
    int totalFocusTime = 0,
    Map<String, int>? dailySessions,
    Map<String, int>? dailyFocusTime,
    int longestStreak = 0,
    int currentStreak = 0,
    DateTime? lastSessionDate,
  }) : _totalSessions = totalSessions,
       _totalFocusTime = totalFocusTime,
       _dailySessions = dailySessions ?? {},
       _dailyFocusTime = dailyFocusTime ?? {},
       _longestStreak = longestStreak,
       _currentStreak = currentStreak,
       _lastSessionDate = lastSessionDate;

  // Record a completed session
  void recordSession(int focusTimeMilliseconds, {DateTime? date}) {
    final sessionDate = date ?? DateTime.now();
    final dateString = _formatDate(sessionDate);

    // Update total counts
    _totalSessions++;
    _totalFocusTime += focusTimeMilliseconds;

    // Update daily counts
    _dailySessions[dateString] = (_dailySessions[dateString] ?? 0) + 1;
    _dailyFocusTime[dateString] =
        (_dailyFocusTime[dateString] ?? 0) + focusTimeMilliseconds;

    // Update streak
    _updateStreak(sessionDate);

    // Update last session date
    _lastSessionDate = sessionDate;

    // Notify listeners and save
    notifyListeners();
    save();
  }

  // Update streak based on the new session date
  void _updateStreak(DateTime sessionDate) {
    final today = _formatDate(DateTime.now());
    final sessionDay = _formatDate(sessionDate);

    // If this is the first session ever
    if (_lastSessionDate == null) {
      _currentStreak = 1;
      _longestStreak = 1;
      return;
    }

    // If the session is from today
    if (sessionDay == today) {
      // No change to streak, already counted
      return;
    }

    final lastDay = _formatDate(_lastSessionDate!);
    final yesterday = _formatDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    // If the last session was yesterday, increment streak
    if (lastDay == yesterday) {
      _currentStreak++;
      if (_currentStreak > _longestStreak) {
        _longestStreak = _currentStreak;
      }
    }
    // If there was a gap, reset streak
    else if (sessionDay != lastDay) {
      _currentStreak = 1;
    }
  }

  // Get sessions for a specific date
  int getSessionsForDate(DateTime date) {
    return _dailySessions[_formatDate(date)] ?? 0;
  }

  // Get focus time for a specific date
  int getFocusTimeForDate(DateTime date) {
    return _dailyFocusTime[_formatDate(date)] ?? 0;
  }

  // Get sessions for the current week
  Map<String, int> getSessionsForWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final result = <String, int>{};
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dateString = _formatDate(date);
      result[dateString] = _dailySessions[dateString] ?? 0;
    }

    return result;
  }

  // Get focus time for the current week
  Map<String, int> getFocusTimeForWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final result = <String, int>{};
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dateString = _formatDate(date);
      result[dateString] = _dailyFocusTime[dateString] ?? 0;
    }

    return result;
  }

  // Reset all statistics
  void reset() {
    _totalSessions = 0;
    _totalFocusTime = 0;
    _dailySessions.clear();
    _dailyFocusTime.clear();
    _longestStreak = 0;
    _currentStreak = 0;
    _lastSessionDate = null;

    notifyListeners();
    save();
  }

  // Format date as yyyy-MM-dd
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Helper method to format duration for display
  static String formatDuration(int milliseconds) {
    final hours = (milliseconds / (1000 * 60 * 60)).floor();
    final minutes = ((milliseconds % (1000 * 60 * 60)) / (1000 * 60)).floor();

    if (hours > 0) {
      return '$hours h ${minutes.toString().padLeft(2, '0')} m';
    } else {
      return '$minutes min';
    }
  }
}
