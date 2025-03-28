import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircularProgressIndicator, AlwaysStoppedAnimation;
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../../models/pomodoro_session.dart';
import '../../models/task.dart';
import '../ambient/ambient_screen.dart';

/// The main screen for the Pomodoro timer.
/// This follows the Dependency Inversion Principle by depending on abstractions
/// rather than concrete implementations.
class PomodoroTimerScreen extends StatefulWidget {
  final Task? task;
  final int? customDuration;

  const PomodoroTimerScreen({super.key, this.task, this.customDuration});

  @override
  State<PomodoroTimerScreen> createState() => _PomodoroTimerScreenState();
}

class _PomodoroTimerScreenState extends State<PomodoroTimerScreen> with WidgetsBindingObserver {
  late PomodoroSession _session;
  Timer? _timer;
  DateTime? _pausedAt;

  // Statistics
  int _completedSessions = 0;
  int _totalFocusTime = 0;
  DateTime? _sessionStartTime;

  // Settings
  final int _defaultFocusDuration = 25 * 60 * 1000; // 25 minutes in milliseconds
  final int _defaultShortBreakDuration = 5 * 60 * 1000; // 5 minutes in milliseconds
  final int _defaultLongBreakDuration = 15 * 60 * 1000; // 15 minutes in milliseconds
  final int _sessionsBeforeLongBreak = 4;
  final bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is in background
      if (_session.state == PomodoroState.running) {
        _pausedAt = DateTime.now();
        _pauseTimer();
      }
    } else if (state == AppLifecycleState.resumed) {
      // App is in foreground
      if (_session.state == PomodoroState.paused && _pausedAt != null) {
        final now = DateTime.now();
        final elapsedMillis = now.difference(_pausedAt!).inMilliseconds;

        // If more than 5 minutes have passed, show reset confirmation
        if (elapsedMillis > 5 * 60 * 1000) {
          _showResetConfirmation();
        } else {
          _resumeTimer();
        }
        _pausedAt = null;
      }
    }
  }

  void _initSession() {
    // Determine break duration based on completed sessions
    final isLongBreakDue = _completedSessions % _sessionsBeforeLongBreak == 0 && _completedSessions > 0;
    final breakDuration = isLongBreakDue ? _defaultLongBreakDuration : _defaultShortBreakDuration;

    if (widget.task != null) {
      _session = PomodoroSession.fromTask(
        widget.task!,
        customDuration: widget.customDuration,
        breakDuration: breakDuration,
      );
    } else if (widget.customDuration != null) {
      _session = PomodoroSession.custom(
        duration: widget.customDuration!,
        breakDuration: breakDuration,
      );
    } else {
      _session = PomodoroSession.custom(
        duration: _defaultFocusDuration,
        breakDuration: breakDuration,
      );
    }

    // Save the session to Hive
    final pomodoroBox = Provider.of<Box<PomodoroSession>>(context, listen: false);
    pomodoroBox.put(_session.id, _session);

    // Listen for state changes
    _session.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _startTimer() {
    _session.start();
    _sessionStartTime = DateTime.now();

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _session.tick(100);

      if (_session.state == PomodoroState.completed) {
        _timer?.cancel();
        _updateStatistics();
        HapticFeedback.heavyImpact();
        _showCompletionDialog();
      } else if (_session.state == PomodoroState.breakTime) {
        HapticFeedback.mediumImpact();
        _showBreakStartDialog();
      }
    });
  }

  void _pauseTimer() {
    _session.pause();
    _timer?.cancel();
  }

  void _resumeTimer() {
    _session.resume();
    _startTimer();
  }

  void _resetTimer() {
    _timer?.cancel();
    _session.reset();
  }

  void _completeEarly() {
    _timer?.cancel();
    _session.completeEarly();
    _updateStatistics();
    _showCompletionDialog();
  }

  void _updateStatistics() {
    _completedSessions++;

    if (_sessionStartTime != null) {
      final now = DateTime.now();
      final sessionDuration = now.difference(_sessionStartTime!).inMilliseconds;
      _totalFocusTime += sessionDuration;
      _sessionStartTime = null;
    }
  }

  void _showBreakStartDialog() {
    if (!_notificationsEnabled) return;

    final breakMinutes = (_session.breakDuration / 60000).floor();

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Break Time!'),
        content: Text(
          'You\'ve completed a pomodoro session. Take a $breakMinutes minute break.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    if (!_notificationsEnabled) return;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Session Completed!'),
        content: Text(
          'You\'ve completed $_completedSessions pomodoro ${_completedSessions == 1 ? 'session' : 'sessions'} today.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Start New Session'),
            onPressed: () {
              Navigator.pop(context);
              _resetTimer();
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Done'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Reset Timer?'),
        content: const Text(
          'You were away for a while. Would you like to reset the timer?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('No, Continue'),
            onPressed: () {
              Navigator.pop(context);
              _resumeTimer();
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Yes, Reset'),
            onPressed: () {
              Navigator.pop(context);
              _resetTimer();
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(int milliseconds) {
    final minutes = (milliseconds / 60000).floor();
    final seconds = ((milliseconds % 60000) / 1000).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = _session.state == PomodoroState.running;
    final isPaused = _session.state == PomodoroState.paused;
    final isBreak = _session.state == PomodoroState.breakTime;
    final isInitial = _session.state == PomodoroState.initial;

    // Get dynamic colors based on system theme
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    final backgroundColor = CupertinoTheme.of(context).scaffoldBackgroundColor;
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;

    // Define colors for different states
    final focusColor = primaryColor;
    final breakColor = CupertinoColors.activeGreen;
    final pauseColor = CupertinoColors.systemOrange;
    final resetColor = CupertinoColors.systemGrey;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.task?.title ?? 'Pomodoro Timer'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.xmark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (widget.task != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Working on: ${widget.task!.title}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Session counter
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Session ${_completedSessions + 1}',
                style: TextStyle(
                  fontSize: 16,
                  color: textColor?.withOpacity(0.7),
                ),
              ),
            ),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Timer display
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: backgroundColor,
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey5.withOpacity(0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Progress indicator
                          SizedBox(
                            width: 230,
                            height: 230,
                            child: CircularProgressIndicator(
                              value: isBreak ? _session.breakProgress : _session.progress,
                              strokeWidth: 10,
                              backgroundColor: CupertinoColors.systemGrey5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isBreak ? breakColor : focusColor,
                              ),
                            ),
                          ),

                          // Time display
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isBreak ? 'BREAK' : 'FOCUS',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isBreak ? breakColor : focusColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isBreak
                                    ? _formatTime(_session.remainingBreakDuration)
                                    : _formatTime(_session.remainingDuration),
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Control buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Start/Pause button
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: isInitial || isPaused ? _startTimer : _pauseTimer,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (isInitial || isPaused ? focusColor : pauseColor).withOpacity(0.1),
                              border: Border.all(
                                color: isInitial || isPaused ? focusColor : pauseColor,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              isInitial || isPaused
                                  ? CupertinoIcons.play_fill
                                  : CupertinoIcons.pause_fill,
                              color: isInitial || isPaused ? focusColor : pauseColor,
                              size: 32,
                            ),
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Reset button
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _resetTimer,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: resetColor.withOpacity(0.1),
                              border: Border.all(
                                color: resetColor,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              CupertinoIcons.refresh,
                              color: CupertinoColors.systemGrey,
                              size: 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Ambient mode button
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                color: primaryColor.withOpacity(0.1),
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const AmbientScreen(),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.music_note_2,
                      color: primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ambient Mode',
                      style: TextStyle(color: primaryColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
