import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pomodoro_settings.dart';
import '../../models/pomodoro_statistics.dart';
import '../../models/task.dart';
import '../../services/pomodoro_timer_service.dart';
import '../ambient/ambient_screen.dart';
import 'pomodoro_settings_screen.dart';
import 'pomodoro_statistics_screen.dart';

class PomodoroScreen extends StatefulWidget {
  final Task? task;
  final int? customDuration;

  const PomodoroScreen({super.key, this.task, this.customDuration});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with WidgetsBindingObserver {
  late PomodoroTimerService _timerService;
  late PomodoroSettings _settings;
  late PomodoroStatistics _statistics;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize with default settings and statistics
    _settings = PomodoroSettings();
    _statistics = PomodoroStatistics();

    // Initialize timer service
    _timerService = PomodoroTimerService(settings: _settings);

    // Initialize session
    _initSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _timerService.handleAppLifecycleChange(state);
  }

  void _initSession() {
    _timerService.initSession(
      task: widget.task,
      customDuration: widget.customDuration,
    );
  }

  void _showCompletionDialog() {
    if (!_settings.notificationsEnabled) return;

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Session Completed!'),
            content: Text(
              'You\'ve completed ${_timerService.completedSessions} pomodoro ${_timerService.completedSessions == 1 ? 'session' : 'sessions'} today.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Start New Session'),
                onPressed: () {
                  Navigator.pop(context);
                  _timerService.resetTimer();
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
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Reset Timer?'),
            content: const Text(
              'You were away for a while. Would you like to reset the timer?',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('No, Continue'),
                onPressed: () {
                  Navigator.pop(context);
                  _timerService.resumeTimer();
                },
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Yes, Reset'),
                onPressed: () {
                  Navigator.pop(context);
                  _timerService.resetTimer();
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
    return ChangeNotifierProvider.value(
      value: _timerService,
      child: Consumer<PomodoroTimerService>(
        builder: (context, timerService, _) {
          final session = timerService.currentSession;
          if (session == null) return const CupertinoActivityIndicator();

          final isRunning = timerService.isRunning;
          final isPaused = timerService.isPaused;
          final isBreak = timerService.isBreak;
          final isInitial = timerService.isInitial;

          // Get dynamic colors based on system theme
          final primaryColor = CupertinoTheme.of(context).primaryColor;
          final backgroundColor =
              CupertinoTheme.of(context).scaffoldBackgroundColor;
          final textColor =
              CupertinoTheme.of(context).textTheme.textStyle.color;

          // Define colors for different states
          final focusColor = primaryColor;
          final breakColor = CupertinoColors.activeGreen;
          final pauseColor = CupertinoColors.systemOrange;
          final resetColor = CupertinoColors.systemGrey;
          final skipColor = CupertinoColors.systemIndigo;

          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text(widget.task?.title ?? 'Pomodoro Timer'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Settings button
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder:
                              (context) =>
                                  PomodoroSettingsScreen(settings: _settings),
                        ),
                      );
                    },
                  ),
                  // Close button
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.xmark),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
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
                      'Session ${timerService.completedSessions + 1}',
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor?.withOpacity(0.7),
                      ),
                    ),
                  ),

                  // Timer display
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: backgroundColor,
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.systemGrey5
                                      .withOpacity(0.5),
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
                                    value:
                                        isBreak
                                            ? session.breakProgress
                                            : session.progress,
                                    strokeWidth: 10,
                                    backgroundColor:
                                        CupertinoColors.systemGrey5,
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
                                        color:
                                            isBreak ? breakColor : focusColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isBreak
                                          ? _formatTime(
                                            session.remainingBreakDuration,
                                          )
                                          : _formatTime(
                                            session.remainingDuration,
                                          ),
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
                        ],
                      ),
                    ),
                  ),

                  // Control buttons
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Start/Pause button
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed:
                              isInitial || isPaused
                                  ? _timerService.startTimer
                                  : _timerService.pauseTimer,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (isInitial || isPaused
                                      ? focusColor
                                      : pauseColor)
                                  .withOpacity(0.1),
                              border: Border.all(
                                color:
                                    isInitial || isPaused
                                        ? focusColor
                                        : pauseColor,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              isInitial || isPaused
                                  ? CupertinoIcons.play_fill
                                  : CupertinoIcons.pause_fill,
                              color:
                                  isInitial || isPaused
                                      ? focusColor
                                      : pauseColor,
                              size: 32,
                            ),
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Reset button
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _timerService.resetTimer,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: resetColor.withOpacity(0.1),
                              border: Border.all(color: resetColor, width: 2),
                            ),
                            child: Icon(
                              CupertinoIcons.refresh,
                              color: resetColor,
                              size: 32,
                            ),
                          ),
                        ),

                        const SizedBox(width: 24),

                        // Skip button (only shown during running or break)
                        if (isRunning || isBreak)
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed:
                                isRunning
                                    ? _timerService.skipToBreak
                                    : _timerService.skipBreak,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: skipColor.withOpacity(0.1),
                                border: Border.all(color: skipColor, width: 2),
                              ),
                              child: Icon(
                                CupertinoIcons.forward_fill,
                                color: skipColor,
                                size: 32,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Bottom buttons
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Statistics button
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: primaryColor.withOpacity(0.1),
                          onPressed: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder:
                                    (context) => PomodoroStatisticsScreen(
                                      statistics: _statistics,
                                    ),
                              ),
                            );
                          },
                          child: const Text('Statistics'),
                        ),
                        // Ambient button
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
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
                          child: const Text('Ambient'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
