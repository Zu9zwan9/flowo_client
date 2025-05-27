import 'dart:async';

/// Enum representing the state of a session
enum SessionState {
  /// Session is running
  running,

  /// Session is paused
  paused,

  /// Session is stopped
  stopped,

  /// Session is completed
  completed,
}

/// A model class that represents session time information.
class SessionTime {
  /// The time when the session started
  final DateTime startTime;

  /// The current elapsed time in seconds
  int _elapsedSeconds = 0;

  /// The accumulated time when the session was paused
  int _accumulatedSeconds = 0;

  /// The current state of the session
  SessionState _state = SessionState.running;

  /// The time when the session was paused
  DateTime? _pauseTime;

  /// Stream controller for elapsed time updates
  final StreamController<int> _elapsedTimeController =
      StreamController<int>.broadcast();

  /// Stream controller for session state updates
  final StreamController<SessionState> _stateController =
      StreamController<SessionState>.broadcast();

  /// Timer for updating elapsed time
  Timer? _timer;

  /// Stream of elapsed time updates
  Stream<int> get elapsedTimeStream => _elapsedTimeController.stream;

  /// Stream of session state updates
  Stream<SessionState> get stateStream => _stateController.stream;

  /// Current elapsed time in seconds
  int get elapsedSeconds => _elapsedSeconds;

  /// Current state of the session
  SessionState get state => _state;

  /// Formatted elapsed time as HH:MM:SS
  String get formattedElapsedTime {
    final hours = (_elapsedSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  /// Creates a new SessionTime instance with the current time as start time
  SessionTime() : startTime = DateTime.now() {
    _startTimer();
    _stateController.add(_state);
  }

  /// Creates a new SessionTime instance with a specific start time (useful for testing)
  SessionTime.withStartTime(this.startTime) {
    _startTimer();
    _stateController.add(_state);
  }

  /// Starts the timer to update elapsed time every second
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state == SessionState.running) {
        _elapsedSeconds =
            _accumulatedSeconds +
            DateTime.now().difference(startTime).inSeconds;
        _elapsedTimeController.add(_elapsedSeconds);
      }
    });
  }

  /// Pauses the session
  void pause() {
    if (_state == SessionState.running) {
      _pauseTime = DateTime.now();
      _accumulatedSeconds = _elapsedSeconds;
      _state = SessionState.paused;
      _stateController.add(_state);
    }
  }

  /// Resumes the session
  void resume() {
    if (_state == SessionState.paused) {
      _state = SessionState.running;
      _stateController.add(_state);
    }
  }

  /// Stops the session
  void stop() {
    if (_state == SessionState.running || _state == SessionState.paused) {
      _state = SessionState.stopped;
      _stateController.add(_state);
      _timer?.cancel();
    }
  }

  /// Completes the session
  void complete() {
    if (_state == SessionState.running || _state == SessionState.paused) {
      _state = SessionState.completed;
      _stateController.add(_state);
      _timer?.cancel();
    }
  }

  /// Resets the session
  void reset() {
    _timer?.cancel();
    _elapsedSeconds = 0;
    _accumulatedSeconds = 0;
    _state = SessionState.running;
    _stateController.add(_state);
    _elapsedTimeController.add(_elapsedSeconds);
    _startTimer();
  }

  /// Disposes resources
  void dispose() {
    _timer?.cancel();
    _elapsedTimeController.close();
    _stateController.close();
  }
}
