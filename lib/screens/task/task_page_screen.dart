import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/tasks_controller/task_manager_cubit.dart';
import '../../models/task.dart';
import '../../models/task_session.dart';
import '../../utils/category_utils.dart';
import '../../utils/logger.dart';
import 'task_form_screen.dart';

class TaskPageConstants {
  static const double padding = 16.0;
  static const double cornerRadius = 12.0;
  static const double shadowBlurRadius = 4.0;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );
}

// Utility for formatting durations
class DurationFormatter {
  static String format(int milliseconds) {
    final hours = milliseconds ~/ 3600000;
    final minutes = (milliseconds % 3600000) ~/ 60000;
    return hours > 0
        ? '$hours hr ${minutes > 0 ? '$minutes min' : ''}'
        : minutes > 0
        ? '$minutes min'
        : '< 1 min';
  }
}

// Main Screen
class TaskPageScreen extends StatefulWidget {
  final Task task;
  final bool isEditing;

  const TaskPageScreen({required this.task, this.isEditing = false, super.key});

  @override
  State<TaskPageScreen> createState() => _TaskPageScreenState();
}

class _TaskPageScreenState extends State<TaskPageScreen> {
  late Task _task;
  late final TextEditingController _notesController;
  late final TaskManagerCubit _taskManagerCubit;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _taskManagerCubit = context.read<TaskManagerCubit>();
    _task = widget.task;
    _notesController = TextEditingController(text: _task.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _toggleTaskCompletion(TaskManagerCubit cubit) {
    cubit.toggleTaskCompletion(_task).then((isCompleted) {
      setState(() {
        _task.isDone = isCompleted;
      });
      _showAutoDismissDialog(
        context,
        message:
            _task.isDone
                ? 'Task "${_task.title}" completed'
                : 'Task "${_task.title}" incomplete',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_task.title, style: theme.textTheme.navTitleTextStyle),
        trailing: SizedBox(
          width: 90,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: const Icon(CupertinoIcons.pencil, size: 20),
                onPressed: () => _navigateToEditScreen(context),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: const Icon(
                  CupertinoIcons.delete,
                  size: 20,
                  color: CupertinoColors.destructiveRed,
                ),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(TaskPageConstants.padding),
              children: [
                TaskHeader(
                  task: _task,
                  onToggle:
                      () => _toggleTaskCompletion(
                        context.read<TaskManagerCubit>(),
                      ),
                ),
                const SizedBox(height: 24),
                TaskDescription(task: _task, controller: _notesController),
                const SizedBox(height: 24),
                SessionsWidget(
                  task: _task,
                  taskManagerCubit: _taskManagerCubit,
                ),
                const SizedBox(height: 24),
                MagicButton(onGenerate: _generateTaskBreakdown),
                const SizedBox(height: 24),
                SubtasksList(
                  subtasks: _taskManagerCubit.getSubtasksForTask(_task),
                  parentTask: _task,
                  onAdd: _showAddSubtaskDialog,
                  onDelete: _deleteSubtask,
                ),
                const SizedBox(height: 32),
              ],
            ),
            if (_isLoading) const LoadingOverlay(),
          ],
        ),
      ),
    );
  }

  void _navigateToEditScreen(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => TaskFormScreen(task: _task)),
    ).then((_) {
      setState(() {
        _task = widget.task;
        _notesController.text = _task.notes ?? '';
      });
    });
  }

  void _confirmDelete(BuildContext context) {
    final subtaskCount = _task.subtaskIds.length;
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Delete Task'),
            content: Text(
              subtaskCount > 0
                  ? 'Delete "${_task.title}" and its $subtaskCount subtask${subtaskCount == 1 ? "" : "s"}?'
                  : 'Delete "${_task.title}"?',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  context.read<TaskManagerCubit>().deleteTask(_task);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _generateTaskBreakdown() async {
    setState(() => _isLoading = true);
    try {
      final subtasksCopy = List<Task>.from(
        _taskManagerCubit.getSubtasksForTask(_task),
      );
      for (var task in subtasksCopy) {
        context.read<TaskManagerCubit>().deleteTask(task);
      }

      final subtasks = await context
          .read<TaskManagerCubit>()
          .generateSubtasksFor(_task);

      setState(() {
        _isLoading = false;
      });
      logInfo('Generated ${subtasks.length} subtasks for ${_task.title}');
    } catch (e) {
      logError('Error generating breakdown: $e');
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to generate breakdown');
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  void _showAutoDismissDialog(BuildContext context, {required String message}) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CupertinoAlertDialog(content: Text(message)),
    );
  }

  void _deleteSubtask(Task subtask) {
    showCupertinoDialog(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: const Text('Delete Subtask'),
            content: Text('Delete "${subtask.title}"?'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  context.read<TaskManagerCubit>().deleteTask(subtask);
                  setState(() {
                    _task.subtaskIds.remove(subtask.id);
                  });
                  _task.save();
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showAddSubtaskDialog() =>
      AddSubtaskDialog.show(context, _task, _addSubtask);

  void _addSubtask(
    String title,
    int estimatedTime,
    int priority,
    int deadline,
    int order,
  ) {
    _taskManagerCubit.createTask(
      title: title,
      priority: priority,
      estimatedTime: estimatedTime,
      deadline: deadline,
      category: _task.category,
      parentTask: _task,
      order: order,
      color: _task.color,
    );

    setState(() {
      _task = _taskManagerCubit.getTaskById(_task.id) ?? _task;
    });
  }
}

// Task Header Widget
class TaskHeader extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;

  const TaskHeader({required this.task, required this.onToggle, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(TaskPageConstants.padding),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(TaskPageConstants.cornerRadius),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.1),
            blurRadius: TaskPageConstants.shadowBlurRadius,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryTag(categoryName: task.category.name),
              const SizedBox(width: 8),
              Expanded(
                child: CompletionToggle(
                  isDone: task.isDone,
                  onPressed: onToggle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Priority: ${task.priority}',
                  style: theme.textTheme.textStyle.copyWith(
                    color: CupertinoColors.systemGrey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                CupertinoIcons.time,
                size: 14,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  DurationFormatter.format(task.estimatedTime),
                  style: theme.textTheme.textStyle.copyWith(
                    color: CupertinoColors.systemGrey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                CupertinoIcons.calendar,
                size: 14,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  DateTime.fromMillisecondsSinceEpoch(
                    task.deadline,
                  ).toLocal().toString().split(' ')[0],
                  style: theme.textTheme.textStyle.copyWith(
                    color: CupertinoColors.systemGrey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Category Tag Widget
class CategoryTag extends StatelessWidget {
  final String categoryName;

  const CategoryTag({required this.categoryName, super.key});

  @override
  Widget build(BuildContext context) {
    final color = CategoryUtils.getCategoryColor(categoryName);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        categoryName,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// Completion Toggle Widget
class CompletionToggle extends StatelessWidget {
  final bool isDone;
  final VoidCallback onPressed;

  const CompletionToggle({
    required this.isDone,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 4), // Reduced padding
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDone
                ? CupertinoIcons.check_mark_circled_solid
                : CupertinoIcons.circle,
            color:
                isDone
                    ? CupertinoColors.activeGreen
                    : CupertinoColors.systemGrey,
            size: 18, // Slightly smaller
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              isDone ? 'Completed' : 'Mark as completed',
              style: theme.textTheme.textStyle.copyWith(
                color:
                    isDone
                        ? CupertinoColors.activeGreen
                        : CupertinoColors.systemGrey,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Task Description Widget (unchanged for brevity)
class TaskDescription extends StatelessWidget {
  final Task task;
  final TextEditingController controller;

  const TaskDescription({
    required this.task,
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(TaskPageConstants.padding),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(TaskPageConstants.cornerRadius),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.1),
            blurRadius: TaskPageConstants.shadowBlurRadius,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Description',
            style: theme.textTheme.navTitleTextStyle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: controller,
            placeholder: 'Add notes about this task...',
            minLines: 3,
            maxLines: 5,
            padding: const EdgeInsets.all(10),
            style: theme.textTheme.textStyle,
            decoration: BoxDecoration(
              border: Border.all(color: theme.barBackgroundColor),
              borderRadius: BorderRadius.circular(8),
            ),
            onChanged: (value) {
              task.notes = value.isEmpty ? null : value;
              task.save();
            },
          ),
        ],
      ),
    );
  }
}

// Magic Button Widget (unchanged for brevity)
class MagicButton extends StatelessWidget {
  final VoidCallback onGenerate;

  const MagicButton({required this.onGenerate, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(TaskPageConstants.padding),
      decoration: BoxDecoration(
        color: CupertinoColors.systemIndigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(TaskPageConstants.cornerRadius),
        border: Border.all(
          color: CupertinoColors.systemIndigo.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            CupertinoIcons.sparkles,
            size: 40,
            color: CupertinoColors.systemIndigo,
          ),
          const SizedBox(height: 12),
          Text(
            'Task Breakdown Options',
            style: theme.textTheme.navTitleTextStyle.copyWith(
              color: CupertinoColors.systemIndigo,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let AI break this task into subtasks or add them manually below.',
            textAlign: TextAlign.center,
            style: theme.textTheme.textStyle.copyWith(
              color: CupertinoColors.systemGrey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          CupertinoButton.filled(
            padding: TaskPageConstants.buttonPadding,
            onPressed: onGenerate,
            child: const Text('Generate Subtasks with AI'),
          ),
        ],
      ),
    );
  }
}

// Subtasks List Widget (unchanged for brevity)
class SubtasksList extends StatelessWidget {
  final List<Task> subtasks;
  final Task parentTask;
  final VoidCallback onAdd;
  final Function(Task) onDelete;

  const SubtasksList({
    required this.subtasks,
    required this.parentTask,
    required this.onAdd,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    // Sort subtasks by task.order
    final sortedSubtasks = List<Task>.from(subtasks)
      ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

    return Container(
      padding: const EdgeInsets.all(TaskPageConstants.padding),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(TaskPageConstants.cornerRadius),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.1),
            blurRadius: TaskPageConstants.shadowBlurRadius,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.list_bullet,
                size: 20,
                color: CupertinoColors.activeBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Subtasks',
                style: theme.textTheme.navTitleTextStyle.copyWith(fontSize: 18),
              ),
              const Spacer(),
              Flexible(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onPressed: onAdd,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.add, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Add Subtask',
                          style: theme.textTheme.textStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                '${sortedSubtasks.length}',
                style: theme.textTheme.textStyle.copyWith(
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...sortedSubtasks.map(
            (subtask) => SubtaskItem(subtask: subtask, onDelete: onDelete),
          ),
        ],
      ),
    );
  }
}

// Subtask Item Widget (unchanged for brevity)
class SubtaskItem extends StatelessWidget {
  final Task subtask;
  final Function(Task) onDelete;

  const SubtaskItem({required this.subtask, required this.onDelete, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(TaskPageConstants.cornerRadius),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.1),
            blurRadius: TaskPageConstants.shadowBlurRadius,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color:
                  subtask.color != null
                      ? Color(subtask.color!)
                      : CategoryUtils.getCategoryColor(subtask.category.name),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        context
                            .read<TaskManagerCubit>()
                            .toggleTaskCompletion(subtask)
                            .then((isCompleted) {
                              subtask.isDone = isCompleted;
                            });
                      },
                      child: Icon(
                        subtask.isDone
                            ? CupertinoIcons.check_mark_circled_solid
                            : CupertinoIcons.circle,
                        color:
                            subtask.isDone
                                ? CupertinoColors.activeGreen
                                : CupertinoColors.systemGrey,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subtask.title,
                        style: theme.textTheme.textStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration:
                              subtask.isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                          color:
                              subtask.isDone
                                  ? CupertinoColors.systemGrey
                                  : theme.textTheme.textStyle.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.time,
                      size: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Est. time: ${DurationFormatter.format(subtask.estimatedTime)}',
                        style: theme.textTheme.textStyle.copyWith(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      CupertinoIcons.flag,
                      size: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Priority: ${subtask.priority}',
                      style: theme.textTheme.textStyle.copyWith(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.delete, size: 20),
            onPressed: () => onDelete(subtask),
          ),
        ],
      ),
    );
  }
}

// Loading Overlay Widget (unchanged)
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CupertinoColors.systemBackground.withOpacity(0.7),
      child: const Center(child: CupertinoActivityIndicator(radius: 20)),
    );
  }
}

/// Widget to display and manage task sessions
class SessionsWidget extends StatefulWidget {
  final Task task;
  final TaskManagerCubit taskManagerCubit;

  const SessionsWidget({
    required this.task,
    required this.taskManagerCubit,
    super.key,
  });

  @override
  State<SessionsWidget> createState() => _SessionsWidgetState();
}

class _SessionsWidgetState extends State<SessionsWidget> {
  late List<TaskSession> _sessions;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadSessions();

    // Set up a timer to refresh the UI every second if there's an active session
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.task.activeSession != null) {
        setState(() {
          // Just trigger a rebuild to update the duration
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadSessions() {
    setState(() {
      _sessions = widget.taskManagerCubit.getTaskSessions(widget.task);
      // Sort sessions by start time (newest first)
      _sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    });
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // Helper method to build a statistic item
  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 16,
          color: CupertinoColors.systemGrey.resolveFrom(context),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
      ],
    );
  }

  // Calculate session statistics
  Map<String, dynamic> _calculateSessionStats() {
    if (_sessions.isEmpty) {
      return {
        'avgDuration': 0,
        'mostProductiveHour': 0,
        'completedSessions': 0,
        'totalSessions': 0,
      };
    }

    // Calculate average duration
    final completedSessions =
        _sessions.where((s) => s.endTime != null).toList();
    final avgDuration =
        completedSessions.isEmpty
            ? 0
            : completedSessions.fold<int>(
                  0,
                  (sum, session) => sum + session.duration,
                ) ~/
                completedSessions.length;

    // Find most productive hour (hour with most sessions)
    final hourCounts = <int, int>{};
    for (var session in _sessions) {
      final hour = session.startTime.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    int mostProductiveHour = 0;
    int maxCount = 0;
    hourCounts.forEach((hour, count) {
      if (count > maxCount) {
        maxCount = count;
        mostProductiveHour = hour;
      }
    });

    return {
      'avgDuration': avgDuration,
      'mostProductiveHour': mostProductiveHour,
      'completedSessions': completedSessions.length,
      'totalSessions': _sessions.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final totalDuration = widget.taskManagerCubit.getTotalDuration(widget.task);
    final activeSession = widget.task.activeSession;
    final sessionStats = _calculateSessionStats();

    return Container(
      padding: const EdgeInsets.all(TaskPageConstants.padding),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(TaskPageConstants.cornerRadius),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.1),
            blurRadius: TaskPageConstants.shadowBlurRadius,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.clock,
                size: 20,
                color: CupertinoColors.activeBlue.resolveFrom(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Sessions',
                style: theme.textTheme.navTitleTextStyle.copyWith(fontSize: 18),
              ),
              const Spacer(),
              Text(
                'Total: ${_formatDuration(totalDuration)}',
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Session statistics
          if (_sessions.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemFill.resolveFrom(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session Statistics',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          context,
                          icon: CupertinoIcons.time,
                          label: 'Avg. Duration',
                          value: _formatDuration(sessionStats['avgDuration']),
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          context,
                          icon: CupertinoIcons.chart_bar,
                          label: 'Most Productive',
                          value: '${sessionStats['mostProductiveHour']}:00',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          context,
                          icon: CupertinoIcons.checkmark_circle,
                          label: 'Completed',
                          value:
                              '${sessionStats['completedSessions']}/${sessionStats['totalSessions']}',
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          context,
                          icon: CupertinoIcons.calendar,
                          label: 'First Session',
                          value:
                              _sessions.isNotEmpty
                                  ? '${_sessions.last.startTime.day}/${_sessions.last.startTime.month}'
                                  : 'N/A',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Session controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                context,
                icon: CupertinoIcons.play_fill,
                label: 'Start',
                color: CupertinoColors.activeGreen,
                onPressed:
                    widget.task.isDone || widget.task.isInProgress
                        ? null
                        : () {
                          widget.taskManagerCubit.startTask(widget.task);
                          setState(() {});
                        },
              ),
              _buildControlButton(
                context,
                icon: CupertinoIcons.pause_fill,
                label: 'Pause',
                color: CupertinoColors.systemOrange,
                onPressed:
                    widget.task.isInProgress
                        ? () {
                          widget.taskManagerCubit.pauseTask(widget.task);
                          setState(() {});
                        }
                        : null,
              ),
              _buildControlButton(
                context,
                icon: CupertinoIcons.stop_fill,
                label: 'Stop',
                color: CupertinoColors.destructiveRed,
                onPressed:
                    widget.task.isInProgress || widget.task.isPaused
                        ? () {
                          widget.taskManagerCubit.stopTask(widget.task);
                          setState(() {});
                        }
                        : null,
              ),
            ],
          ),

          // Active session indicator
          if (activeSession != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.activeGreen
                    .resolveFrom(context)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CupertinoColors.activeGreen
                      .resolveFrom(context)
                      .withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.timer,
                        color: CupertinoColors.activeGreen.resolveFrom(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Session in progress',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.activeGreen.resolveFrom(
                                  context,
                                ),
                              ),
                            ),
                            Text(
                              'Started at ${activeSession.startTime.hour.toString().padLeft(2, '0')}:${activeSession.startTime.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatDuration(activeSession.duration),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.activeGreen.resolveFrom(
                            context,
                          ),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                          Text(
                            '${((activeSession.duration / widget.task.estimatedTime) * 100).clamp(0, 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.activeGreen.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Stack(
                        children: [
                          // Background
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemFill.resolveFrom(
                                context,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          // Progress
                          Container(
                            height: 8,
                            width:
                                (MediaQuery.of(context).size.width - 64) *
                                (activeSession.duration /
                                        widget.task.estimatedTime)
                                    .clamp(0, 1),
                            decoration: BoxDecoration(
                              color: CupertinoColors.activeGreen.resolveFrom(
                                context,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Elapsed: ${_formatDuration(activeSession.duration)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                          Text(
                            'Estimated: ${_formatDuration(widget.task.estimatedTime)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Sessions list
          if (_sessions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text(
              'Recent Sessions',
              style: theme.textTheme.textStyle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...(_sessions
                .take(5)
                .map((session) => _buildSessionItem(context, session))),
            if (_sessions.length > 5) ...[
              const SizedBox(height: 8),
              Center(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text(
                    'View all ${_sessions.length} sessions',
                    style: theme.textTheme.textStyle.copyWith(
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                  onPressed: () => _showAllSessions(context),
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                'No sessions yet',
                style: theme.textTheme.textStyle.copyWith(
                  color: CupertinoColors.systemGrey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    final theme = CupertinoTheme.of(context);
    final isDisabled = onPressed == null;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  isDisabled
                      ? CupertinoColors.systemGrey5
                      : color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isDisabled
                        ? CupertinoColors.systemGrey4
                        : color.withOpacity(0.3),
              ),
            ),
            child: Icon(
              icon,
              color: isDisabled ? CupertinoColors.systemGrey : color,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.textStyle.copyWith(
              fontSize: 12,
              color:
                  isDisabled
                      ? CupertinoColors.systemGrey
                      : theme.textTheme.textStyle.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionItem(BuildContext context, TaskSession session) {
    final isActive = session.isActive;
    final startDate = session.startTime;
    final endDate = session.endTime;

    // Calculate session completion percentage if there's an estimated time
    final completionPercentage =
        widget.task.estimatedTime > 0
            ? (session.duration / widget.task.estimatedTime * 100)
                .clamp(0, 100)
                .toInt()
            : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isActive
                ? CupertinoColors.activeGreen
                    .resolveFrom(context)
                    .withOpacity(0.05)
                : CupertinoColors.systemFill.resolveFrom(context),
        borderRadius: BorderRadius.circular(8),
        border:
            isActive
                ? Border.all(
                  color: CupertinoColors.activeGreen
                      .resolveFrom(context)
                      .withOpacity(0.2),
                )
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (isActive
                          ? CupertinoColors.activeGreen
                          : CupertinoColors.systemGrey)
                      .resolveFrom(context)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isActive ? CupertinoIcons.timer : CupertinoIcons.clock,
                  size: 14,
                  color: (isActive
                          ? CupertinoColors.activeGreen
                          : CupertinoColors.systemGrey)
                      .resolveFrom(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${startDate.day}/${startDate.month}/${startDate.year}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    Text(
                      'Started at ${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}${endDate != null ? ' - Ended at ${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}' : ' (In Progress)'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isActive
                          ? CupertinoColors.activeGreen
                          : CupertinoColors.systemGrey)
                      .resolveFrom(context)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatDuration(session.duration),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: (isActive
                            ? CupertinoColors.activeGreen
                            : CupertinoColors.label)
                        .resolveFrom(context),
                  ),
                ),
              ),
            ],
          ),

          // Show progress bar for completed sessions if we have estimated time
          if (!isActive && completionPercentage != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // Background
                      Container(
                        height: 4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemFill.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Progress
                      Container(
                        height: 4,
                        width:
                            (MediaQuery.of(context).size.width - 64) *
                            (session.duration / widget.task.estimatedTime)
                                .clamp(0, 1),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey.resolveFrom(
                            context,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$completionPercentage%',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAllSessions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoTheme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Sessions',
                      style:
                          CupertinoTheme.of(
                            context,
                          ).textTheme.navTitleTextStyle,
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _sessions.length,
                    itemBuilder:
                        (context, index) =>
                            _buildSessionItem(context, _sessions[index]),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

// Add Subtask Dialog Widget (improved for better UX and Apple HIG compliance)
class AddSubtaskDialog {
  // Helper method to get a user-friendly label for the order position
  static String _getOrderLabel(int order, List<Task> sortedSubtasks) {
    if (sortedSubtasks.isEmpty || order == 0) {
      return 'First position';
    } else if (order > (sortedSubtasks.last.order ?? 0)) {
      return 'Last position';
    } else {
      // Find the task before this position
      final beforeTask = sortedSubtasks.lastWhere(
        (t) => (t.order ?? 0) < order,
        orElse: () => sortedSubtasks.first,
      );

      final beforeTitle = beforeTask.title.substring(
        0,
        min(20, beforeTask.title.length),
      );

      return 'After "$beforeTitle${beforeTask.title.length > 20 ? '...' : ''}"';
    }
  }

  static void show(
    BuildContext context,
    Task parentTask,
    Function(String, int, int, int, int) onAdd,
  ) {
    final titleController = TextEditingController();
    int estimatedTime = 0;
    int priority = 1;
    int deadline = parentTask.deadline;
    int order = 0; // Will be set based on existing subtasks

    // Get existing subtasks to show order options
    final existingSubtasks = context
        .read<TaskManagerCubit>()
        .getSubtasksForTask(parentTask);

    // Sort subtasks by order
    final sortedSubtasks = List<Task>.from(existingSubtasks)
      ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

    // Default order to the end of the list
    if (sortedSubtasks.isNotEmpty) {
      final lastOrder = sortedSubtasks.last.order ?? 0;
      order = lastOrder + 1;
    } else {
      order = 1; // First subtask
    }

    final theme = CupertinoTheme.of(context);
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    // Create a list of order options
    final orderOptions = <int>[];
    // Add option to insert at the beginning
    orderOptions.add(0);
    // Add options to insert between existing subtasks
    for (int i = 0; i < sortedSubtasks.length; i++) {
      final currentOrder = sortedSubtasks[i].order ?? i;
      orderOptions.add(currentOrder + 1);
    }
    // Add option to add at the end (already set as default)
    if (!orderOptions.contains(order)) {
      orderOptions.add(order);
    }

    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  padding: const EdgeInsets.all(TaskPageConstants.padding),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground.resolveFrom(
                      context,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with navigation bar style
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: CupertinoColors.activeBlue.resolveFrom(
                                    context,
                                  ),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Text(
                              'Add Subtask',
                              style: theme.textTheme.navTitleTextStyle,
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: Text(
                                'Add',
                                style: TextStyle(
                                  color: CupertinoColors.activeBlue.resolveFrom(
                                    context,
                                  ),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                if (titleController.text.trim().isEmpty) {
                                  // Show error for empty title
                                  showCupertinoDialog(
                                    context: context,
                                    builder:
                                        (context) => CupertinoAlertDialog(
                                          title: const Text('Error'),
                                          content: const Text(
                                            'Title cannot be empty',
                                          ),
                                          actions: [
                                            CupertinoDialogAction(
                                              child: const Text('OK'),
                                              onPressed:
                                                  () => Navigator.pop(context),
                                            ),
                                          ],
                                        ),
                                  );
                                  return;
                                }
                                onAdd(
                                  titleController.text.trim(),
                                  estimatedTime,
                                  priority,
                                  deadline,
                                  order,
                                );
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),

                      // Form fields
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title field
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Title',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: CupertinoColors.label
                                            .resolveFrom(context),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    CupertinoTextField(
                                      controller: titleController,
                                      placeholder: 'Enter subtask title',
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.systemFill
                                            .resolveFrom(context),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      style: TextStyle(
                                        color: CupertinoColors.label
                                            .resolveFrom(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Estimated time field with time picker
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Estimated Time',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: CupertinoColors.label
                                            .resolveFrom(context),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () {
                                        showCupertinoModalPopup(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return Container(
                                              height: 216,
                                              padding: const EdgeInsets.only(
                                                top: 6.0,
                                              ),
                                              margin: EdgeInsets.only(
                                                bottom:
                                                    MediaQuery.of(
                                                      context,
                                                    ).viewInsets.bottom,
                                              ),
                                              color: CupertinoColors
                                                  .systemBackground
                                                  .resolveFrom(context),
                                              child: SafeArea(
                                                top: false,
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        CupertinoButton(
                                                          child: const Text(
                                                            'Cancel',
                                                          ),
                                                          onPressed: () {
                                                            Navigator.of(
                                                              context,
                                                            ).pop();
                                                          },
                                                        ),
                                                        CupertinoButton(
                                                          child: const Text(
                                                            'Done',
                                                          ),
                                                          onPressed: () {
                                                            Navigator.of(
                                                              context,
                                                            ).pop();
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                    Expanded(
                                                      child: CupertinoPicker(
                                                        magnification: 1.22,
                                                        squeeze: 1.2,
                                                        useMagnifier: true,
                                                        itemExtent: 32,
                                                        // This sets the initial item.
                                                        scrollController:
                                                            FixedExtentScrollController(
                                                              initialItem:
                                                                  (estimatedTime ~/
                                                                          15)
                                                                      .clamp(
                                                                        0,
                                                                        23,
                                                                      ),
                                                            ),
                                                        // This is called when selected item is changed.
                                                        onSelectedItemChanged: (
                                                          int selectedItem,
                                                        ) {
                                                          setState(() {
                                                            // Convert to minutes (15-minute increments)
                                                            estimatedTime =
                                                                selectedItem *
                                                                15 *
                                                                60 *
                                                                1000;
                                                          });
                                                        },
                                                        children: List<
                                                          Widget
                                                        >.generate(24, (
                                                          int index,
                                                        ) {
                                                          final hours =
                                                              index ~/ 4;
                                                          final minutes =
                                                              (index % 4) * 15;
                                                          return Center(
                                                            child: Text(
                                                              '${hours > 0 ? '$hours hr ' : ''}${minutes > 0
                                                                  ? '$minutes min'
                                                                  : hours > 0
                                                                  ? ''
                                                                  : '0 min'}',
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                  ),
                                                            ),
                                                          );
                                                        }),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.systemFill
                                              .resolveFrom(context),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              DurationFormatter.format(
                                                estimatedTime,
                                              ),
                                              style: TextStyle(
                                                color: CupertinoColors.label
                                                    .resolveFrom(context),
                                              ),
                                            ),
                                            Icon(
                                              CupertinoIcons.time,
                                              color: CupertinoColors
                                                  .secondaryLabel
                                                  .resolveFrom(context),
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Priority field
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Priority',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: CupertinoColors.label
                                            .resolveFrom(context),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.systemFill
                                            .resolveFrom(context),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: CupertinoSlider(
                                              value: priority.toDouble(),
                                              min: 1,
                                              max: 10,
                                              divisions: 9,
                                              onChanged: (value) {
                                                setState(() {
                                                  priority = value.round();
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            priority.toString(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: CupertinoColors.label
                                                  .resolveFrom(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Order field with improved visual cues
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Subtask Order',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: CupertinoColors.label
                                                .resolveFrom(context),
                                          ),
                                        ),
                                        Text(
                                          sortedSubtasks.isEmpty
                                              ? 'No existing subtasks'
                                              : '${sortedSubtasks.length} existing subtask${sortedSubtasks.length > 1 ? 's' : ''}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: CupertinoColors
                                                .secondaryLabel
                                                .resolveFrom(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Choose where to place this subtask in the list',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: CupertinoColors.secondaryLabel
                                            .resolveFrom(context),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () {
                                        showCupertinoModalPopup(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return Container(
                                              height: 300,
                                              padding: const EdgeInsets.only(
                                                top: 6.0,
                                              ),
                                              margin: EdgeInsets.only(
                                                bottom:
                                                    MediaQuery.of(
                                                      context,
                                                    ).viewInsets.bottom,
                                              ),
                                              color: CupertinoColors
                                                  .systemBackground
                                                  .resolveFrom(context),
                                              child: SafeArea(
                                                top: false,
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        CupertinoButton(
                                                          child: const Text(
                                                            'Cancel',
                                                          ),
                                                          onPressed: () {
                                                            Navigator.of(
                                                              context,
                                                            ).pop();
                                                          },
                                                        ),
                                                        Text(
                                                          'Select Position',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        CupertinoButton(
                                                          child: const Text(
                                                            'Done',
                                                          ),
                                                          onPressed: () {
                                                            Navigator.of(
                                                              context,
                                                            ).pop();
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                    Expanded(
                                                      child: CupertinoPicker(
                                                        magnification: 1.17,
                                                        squeeze: 1.45,
                                                        useMagnifier: true,
                                                        itemExtent: 44,
                                                        scrollController:
                                                            FixedExtentScrollController(
                                                              initialItem:
                                                                  orderOptions
                                                                      .indexOf(
                                                                        order,
                                                                      ),
                                                            ),
                                                        onSelectedItemChanged: (
                                                          index,
                                                        ) {
                                                          setState(() {
                                                            order =
                                                                orderOptions[index];
                                                          });
                                                        },
                                                        children:
                                                            orderOptions.map((
                                                              o,
                                                            ) {
                                                              String label;
                                                              IconData icon;
                                                              Color iconColor;

                                                              if (o == 0 ||
                                                                  (sortedSubtasks
                                                                          .isEmpty &&
                                                                      o == 1)) {
                                                                label =
                                                                    'First position';
                                                                icon =
                                                                    CupertinoIcons
                                                                        .arrow_up_to_line;
                                                                iconColor = CupertinoColors
                                                                    .systemBlue
                                                                    .resolveFrom(
                                                                      context,
                                                                    );
                                                              } else if (o ==
                                                                      order &&
                                                                  sortedSubtasks
                                                                      .isNotEmpty) {
                                                                label =
                                                                    'Last position';
                                                                icon =
                                                                    CupertinoIcons
                                                                        .arrow_down_to_line;
                                                                iconColor = CupertinoColors
                                                                    .systemIndigo
                                                                    .resolveFrom(
                                                                      context,
                                                                    );
                                                              } else {
                                                                // Find the tasks before and after this position
                                                                final beforeTask =
                                                                    sortedSubtasks.lastWhere(
                                                                      (t) =>
                                                                          (t.order ??
                                                                              0) <
                                                                          o,
                                                                      orElse:
                                                                          () =>
                                                                              sortedSubtasks.first,
                                                                    );
                                                                final afterTask = sortedSubtasks.firstWhere(
                                                                  (t) =>
                                                                      (t.order ??
                                                                          0) >=
                                                                      o,
                                                                  orElse:
                                                                      () =>
                                                                          sortedSubtasks
                                                                              .last,
                                                                );

                                                                final beforeTitle = beforeTask
                                                                    .title
                                                                    .substring(
                                                                      0,
                                                                      min(
                                                                        45,
                                                                        beforeTask
                                                                            .title
                                                                            .length,
                                                                      ),
                                                                    );
                                                                final afterTitle = afterTask
                                                                    .title
                                                                    .substring(
                                                                      0,
                                                                      min(
                                                                        45,
                                                                        afterTask
                                                                            .title
                                                                            .length,
                                                                      ),
                                                                    );

                                                                label =
                                                                    'After "$beforeTitle${beforeTask.title.length > 45 ? '...' : ''}"';
                                                                icon =
                                                                    CupertinoIcons
                                                                        .arrow_right;
                                                                iconColor = CupertinoColors
                                                                    .systemGreen
                                                                    .resolveFrom(
                                                                      context,
                                                                    );
                                                              }

                                                              return Container(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          16,
                                                                    ),
                                                                child: Row(
                                                                  children: [
                                                                    Icon(
                                                                      icon,
                                                                      color:
                                                                          iconColor,
                                                                      size: 20,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 12,
                                                                    ),
                                                                    Expanded(
                                                                      child: Text(
                                                                        label,
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              16,
                                                                          color: CupertinoColors.label.resolveFrom(
                                                                            context,
                                                                          ),
                                                                        ),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            }).toList(),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.systemFill
                                              .resolveFrom(context),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: CupertinoColors.activeBlue
                                                .resolveFrom(context)
                                                .withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              AddSubtaskDialog._getOrderLabel(
                                                order,
                                                sortedSubtasks,
                                              ),
                                              style: TextStyle(
                                                color: CupertinoColors.label
                                                    .resolveFrom(context),
                                              ),
                                            ),
                                            Icon(
                                              CupertinoIcons.list_number,
                                              color: CupertinoColors.activeBlue
                                                  .resolveFrom(context),
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Deadline field with date picker (limited to parent's deadline)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Deadline',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: CupertinoColors.label
                                                .resolveFrom(context),
                                          ),
                                        ),
                                        CupertinoSwitch(
                                          value:
                                              deadline != parentTask.deadline,
                                          onChanged: (value) {
                                            setState(() {
                                              if (value) {
                                                // Set to one day before parent deadline if using custom
                                                final parentDate =
                                                    DateTime.fromMillisecondsSinceEpoch(
                                                      parentTask.deadline,
                                                    );
                                                final oneDayBefore = parentDate
                                                    .subtract(
                                                      const Duration(days: 1),
                                                    );
                                                deadline =
                                                    oneDayBefore
                                                        .millisecondsSinceEpoch;
                                              } else {
                                                // Use parent deadline
                                                deadline = parentTask.deadline;
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      deadline == parentTask.deadline
                                          ? 'Using parent task deadline'
                                          : 'Custom deadline (before parent\'s)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: CupertinoColors.secondaryLabel
                                            .resolveFrom(context),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap:
                                          deadline != parentTask.deadline
                                              ? () {
                                                showCupertinoModalPopup(
                                                  context: context,
                                                  builder: (
                                                    BuildContext context,
                                                  ) {
                                                    return Container(
                                                      height: 216,
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 6.0,
                                                          ),
                                                      margin: EdgeInsets.only(
                                                        bottom:
                                                            MediaQuery.of(
                                                              context,
                                                            ).viewInsets.bottom,
                                                      ),
                                                      color: CupertinoColors
                                                          .systemBackground
                                                          .resolveFrom(context),
                                                      child: SafeArea(
                                                        top: false,
                                                        child: Column(
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                CupertinoButton(
                                                                  child:
                                                                      const Text(
                                                                        'Cancel',
                                                                      ),
                                                                  onPressed: () {
                                                                    Navigator.of(
                                                                      context,
                                                                    ).pop();
                                                                  },
                                                                ),
                                                                CupertinoButton(
                                                                  child:
                                                                      const Text(
                                                                        'Done',
                                                                      ),
                                                                  onPressed: () {
                                                                    Navigator.of(
                                                                      context,
                                                                    ).pop();
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                            Expanded(
                                                              child: CupertinoDatePicker(
                                                                mode:
                                                                    CupertinoDatePickerMode
                                                                        .date,
                                                                initialDateTime:
                                                                    DateTime.fromMillisecondsSinceEpoch(
                                                                      deadline,
                                                                    ),
                                                                minimumDate:
                                                                    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
                                                                maximumDate:
                                                                    DateTime.fromMillisecondsSinceEpoch(
                                                                      parentTask
                                                                          .deadline,
                                                                    ),
                                                                onDateTimeChanged: (
                                                                  DateTime
                                                                  newDate,
                                                                ) {
                                                                  setState(() {
                                                                    deadline =
                                                                        newDate
                                                                            .millisecondsSinceEpoch;
                                                                  });
                                                                },
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              }
                                              : null,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.systemFill
                                              .resolveFrom(context),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border:
                                              deadline != parentTask.deadline
                                                  ? Border.all(
                                                    color: CupertinoColors
                                                        .activeBlue
                                                        .resolveFrom(context)
                                                        .withOpacity(0.3),
                                                    width: 1,
                                                  )
                                                  : null,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              DateTime.fromMillisecondsSinceEpoch(
                                                deadline,
                                              ).toLocal().toString().split(
                                                ' ',
                                              )[0],
                                              style: TextStyle(
                                                color:
                                                    deadline !=
                                                            parentTask.deadline
                                                        ? CupertinoColors.label
                                                            .resolveFrom(
                                                              context,
                                                            )
                                                        : CupertinoColors
                                                            .secondaryLabel
                                                            .resolveFrom(
                                                              context,
                                                            ),
                                              ),
                                            ),
                                            Icon(
                                              CupertinoIcons.calendar,
                                              color:
                                                  deadline !=
                                                          parentTask.deadline
                                                      ? CupertinoColors
                                                          .activeBlue
                                                          .resolveFrom(context)
                                                      : CupertinoColors
                                                          .secondaryLabel
                                                          .resolveFrom(context),
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }
}
