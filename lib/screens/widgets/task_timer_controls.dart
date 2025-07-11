import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/models/task.dart';

/// A widget that displays timer controls for a task
/// Allows users to start, pause, and stop tasks
class TaskTimerControls extends StatefulWidget {
  final Task task;
  final bool isDarkMode;

  const TaskTimerControls({
    super.key,
    required this.task,
    required this.isDarkMode,
  });

  @override
  State<TaskTimerControls> createState() => _TaskTimerControlsState();
}

class _TaskTimerControlsState extends State<TaskTimerControls>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Timer _timer;
  int _elapsedTime = 0;
  int _currentSessionTime = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Initialize elapsed time based on task's current session
    _updateElapsedTime();

    // Start timer to update elapsed time every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _updateElapsedTime();
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _updateElapsedTime() {
    final task = widget.task;
    _elapsedTime = task.getTotalDuration();

    // Calculate current session time
    if (task.activeSession != null) {
      _currentSessionTime = task.activeSession!.duration;
    } else if (task.isPaused && task.sessions.isNotEmpty) {
      _currentSessionTime = task.sessions.last.duration;
    } else {
      _currentSessionTime = 0;
    }
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    final bool isActiveOrPaused = task.isInProgress || task.isPaused;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Timer display
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: widget.isDarkMode
                ? CupertinoColors.systemGrey6.darkColor
                : CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Current session time - shown larger
              Text(
                isActiveOrPaused
                    ? _formatDuration(_currentSessionTime)
                    : _formatDuration(_elapsedTime),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SF Mono',
                  color: isActiveOrPaused && task.isPaused
                      ? CupertinoColors.systemYellow
                      : isActiveOrPaused
                      ? CupertinoColors.activeGreen
                      : CupertinoTheme.of(context).textTheme.textStyle.color,
                ),
              ),

              // Total time - shown smaller below if there's an active session
              if (isActiveOrPaused)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(_elapsedTime),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SF Mono',
                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Start/Pause button
            if (task.isInProgress)
              _buildControlButton(
                icon: CupertinoIcons.pause_fill,
                label: 'Pause',
                color: CupertinoColors.systemOrange,
                onPressed: () => _pauseTask(task),
              )
            else if (task.isPaused)
              _buildControlButton(
                icon: CupertinoIcons.play_fill,
                label: 'Continue',
                color: CupertinoColors.activeGreen,
                onPressed: () => _startTask(task),
              )
            else
              _buildControlButton(
                icon: CupertinoIcons.play_fill,
                label: 'Start',
                color: CupertinoColors.activeGreen,
                onPressed: task.canStart ? () => _startTask(task) : null,
              ),

            // Stop button - always displayed
            _buildControlButton(
              icon: CupertinoIcons.stop_fill,
              label: 'Stop',
              color: CupertinoColors.systemRed,
              onPressed: (task.isInProgress || task.isPaused) ? () => _stopTask(task) : null,
            ),
          ],
        ),

        // Show message if task can't be started
        if (!task.canStart && !task.isInProgress && !task.isPaused)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Complete subtasks before starting this task',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    final resolvedColor = CupertinoDynamicColor.resolve(color, context);
    final disabledColor = CupertinoColors.systemGrey;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: onPressed != null ? resolvedColor : disabledColor,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: onPressed != null ? resolvedColor : disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  void _startTask(Task task) {
    final tasksCubit = context.read<TaskManagerCubit>();
    if (task.isPaused) {
      tasksCubit.resumeTask(task);
    } else {
      tasksCubit.startTask(task);
    }
  }

  void _pauseTask(Task task) {
    final tasksCubit = context.read<TaskManagerCubit>();
    tasksCubit.pauseTask(task);
  }

  void _stopTask(Task task) {
    final tasksCubit = context.read<TaskManagerCubit>();
    tasksCubit.stopTask(task);
  }
}