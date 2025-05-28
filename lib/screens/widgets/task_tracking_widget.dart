import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../blocs/tasks_controller/task_manager_cubit.dart';
import '../../blocs/tasks_controller/task_manager_state.dart';
import '../../models/task.dart';

class TaskTrackingWidget extends StatelessWidget {
  const TaskTrackingWidget({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  void _showTaskSelectionDialog(BuildContext context) {
    final taskManager = context.read<TaskManagerCubit>();
    final tasks =
        taskManager.state.tasks
            .where(
              (task) =>
                  !task.isDone &&
                  task.category.name != 'Free Time Manager' &&
                  task.subtaskIds.isEmpty,
            )
            .toList();

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Text('Select Task to Track'),
            message: const Text('Choose a task to start time tracking'),
            actions:
                tasks
                    .map(
                      (task) => CupertinoActionSheetAction(
                        onPressed: () {
                          taskManager.startTaskTracking(task);
                          Navigator.pop(context);
                        },
                        child: Text(task.title),
                      ),
                    )
                    .toList(),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              isDestructiveAction: true,
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskManagerCubit, TaskManagerState>(
      buildWhen: (previous, current) => previous.tasks != current.tasks,
      builder: (context, state) {
        final taskManager = context.read<TaskManagerCubit>();
        final trackingState = taskManager.getCurrentTracking();
        final activeTask = trackingState.task;
        final elapsed = trackingState.elapsed ?? Duration.zero;
        final isRunning = trackingState.isRunning;

        final isDarkMode =
            CupertinoTheme.of(context).brightness == Brightness.dark;

        // When no active task is being tracked
        if (activeTask == null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color:
                  isDarkMode
                      ? const Color(0xFF2C2C2E)
                      : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(12),
              onPressed: () => _showTaskSelectionDialog(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.timer,
                    color: CupertinoColors.activeBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Start Tracking",
                    style: TextStyle(
                      color: CupertinoColors.activeBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Stream for updating timer every second
        final tickStream = Stream.periodic(
          const Duration(seconds: 1),
          (i) => i,
        );

        // Color for the task indicator
        final taskColor =
            activeTask.color != null
                ? Color(activeTask.color!)
                : CupertinoColors.activeBlue;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color:
                  isDarkMode
                      ? const Color(0xFF2C2C2E)
                      : CupertinoColors.systemGrey6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Task title with color indicator
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: taskColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          activeTask.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color:
                                isDarkMode
                                    ? CupertinoColors.white
                                    : CupertinoColors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Timer display
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StreamBuilder<int>(
                    stream: isRunning ? tickStream : Stream.value(0),
                    builder: (context, snapshot) {
                      final displayTime =
                          isRunning && snapshot.hasData
                              ? elapsed + Duration(seconds: snapshot.data!)
                              : elapsed;

                      return Text(
                        _formatDuration(displayTime),
                        style: TextStyle(
                          fontFamily: '.SF Mono',
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                          color:
                              isDarkMode
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                          letterSpacing: -0.5,
                        ),
                      );
                    },
                  ),
                ),

                // Started time info
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Text(
                    'Started at ${DateFormat('HH:mm').format(DateTime.now().subtract(elapsed))}',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),

                // Control buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      // Pause/Resume button
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          color:
                              isRunning
                                  ? CupertinoColors.systemYellow
                                  : CupertinoColors.activeGreen,
                          borderRadius: BorderRadius.circular(10),
                          onPressed: () {
                            if (isRunning) {
                              taskManager.pauseTaskTracking();
                            } else {
                              taskManager.resumeTaskTracking();
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isRunning
                                    ? CupertinoIcons.pause_solid
                                    : CupertinoIcons.play_arrow_solid,
                                color: CupertinoColors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isRunning ? 'Pause' : 'Resume',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Stop button
                      CupertinoButton(
                        padding: const EdgeInsets.all(10),
                        color:
                            isDarkMode
                                ? const Color(0xFF3A3A3C)
                                : CupertinoColors.systemGrey5,
                        borderRadius: BorderRadius.circular(10),
                        onPressed: () {
                          taskManager.stopTaskTracking();
                        },
                        child: Icon(
                          CupertinoIcons.stop_fill,
                          color: CupertinoColors.destructiveRed,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
