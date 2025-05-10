import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Base class for all session types in the application.

abstract class Session extends HiveObject with ChangeNotifier {
  /// Unique identifier for the session
  String get id;

  /// Start time of the session
  DateTime get startTime;

  /// End time of the session (null if session is still active)
  DateTime? get endTime;
  set endTime(DateTime? value);

  /// Duration of the session in milliseconds
  /// This is calculated as the difference between endTime and startTime
  /// If endTime is null (session is active), this returns the duration until now
  int get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inMilliseconds;
  }

  /// Checks if the session is currently active
  bool get isActive => endTime == null;

  /// Ends the current session
  void end() {
    if (endTime == null) {
      endTime = DateTime.now();
      // Only save if the object is in a box
      if (isInBox) {
        save();
      }
      notifyListeners();
    }
  }
}
