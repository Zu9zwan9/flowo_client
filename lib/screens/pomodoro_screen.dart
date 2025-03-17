import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircularProgressIndicator, AlwaysStoppedAnimation;
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../models/pomodoro_session.dart';
import '../models/task.dart';

class PomodoroScreen extends StatefulWidget {
  final Task? task;
  final int? customDuration;

  const PomodoroScreen({
    Key? key,
    this.task,
    this.customDuration,
  }) : super(key: key);

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> with WidgetsBindingObserver {
  late PomodoroSession _session;
  Timer? _timer;
  DateTime? _pausedAt;

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

        // If more than 5 minutes have passed, reset the timer
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
    if (widget.task != null) {
      _session = PomodoroSession.fromTask(
        widget.task!,
        customDuration: widget.customDuration,
      );
    } else if (widget.customDuration != null) {
      _session = PomodoroSession.custom(
        duration: widget.customDuration!,
      );
    } else {
      // Default 25-minute pomodoro
      _session = PomodoroSession.custom(
        duration: 25 * 60 * 1000, // 25 minutes
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
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _session.tick(100);

      if (_session.state == PomodoroState.completed) {
        _timer?.cancel();
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
    _showCompletionDialog();
  }

  void _showBreakStartDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Break Time!'),
        content: Text('You\'ve completed a pomodoro session. Take a ${_session.breakDuration ~/ 60000} minute break.'),
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
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Session Completed!'),
        content: Text('You\'ve completed ${_session.completedPomodoros} pomodoro ${_session.completedPomodoros == 1 ? 'session' : 'sessions'}.'),
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
        content: const Text('You were away for a while. Would you like to reset the timer?'),
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
    final isCompleted = _session.state == PomodoroState.completed;
    final isInitial = _session.state == PomodoroState.initial;

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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
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
                        color: CupertinoColors.systemBackground,
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
                                isBreak
                                    ? CupertinoColors.systemGreen
                                    : CupertinoColors.activeBlue,
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
                                  color: isBreak
                                      ? CupertinoColors.systemGreen
                                      : CupertinoColors.activeBlue,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isBreak
                                    ? _formatTime(_session.remainingBreakDuration)
                                    : _formatTime(_session.remainingDuration),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
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
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: isInitial || isPaused ? _startTimer : _pauseTimer,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isInitial || isPaused
                                  ? CupertinoColors.activeGreen.withOpacity(0.1)
                                  : CupertinoColors.systemOrange.withOpacity(0.1),
                              border: Border.all(
                                color: isInitial || isPaused
                                    ? CupertinoColors.activeGreen
                                    : CupertinoColors.systemOrange,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              isInitial || isPaused
                                  ? CupertinoIcons.play_fill
                                  : CupertinoIcons.pause_fill,
                              color: isInitial || isPaused
                                  ? CupertinoColors.activeGreen
                                  : CupertinoColors.systemOrange,
                              size: 32,
                            ),
                          ),
                        ),

                        const SizedBox(width: 24),

                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _resetTimer,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: CupertinoColors.systemGrey.withOpacity(0.1),
                              border: Border.all(
                                color: CupertinoColors.systemGrey,
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                color: CupertinoColors.systemIndigo.withOpacity(0.1),
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const AmbientModeScreen(),
                    ),
                  );
                },
                child: const Text('Ambient Mode'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder for the AmbientModeScreen
class AmbientModeScreen extends StatelessWidget {
  const AmbientModeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Ambient Mode'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      CupertinoIcons.music_note_2,
                      size: 80,
                      color: CupertinoColors.systemIndigo,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Ambient Work Environment',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Coming Soon',
                      style: TextStyle(
                        fontSize: 18,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Focus with ambient sounds and videos\nto enhance your productivity.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.systemGrey,
                      ),
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
