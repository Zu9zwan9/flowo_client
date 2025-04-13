import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/tasks_controller/task_manager_cubit.dart';
import '../../models/task.dart';
import '../../utils/category_utils.dart';
import '../../utils/logger.dart';
import '../calendar/calendar_screen.dart';
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
  bool _isLoading = false;
  List<Task> _subtasks = [];

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _notesController = TextEditingController(text: _task.notes ?? '');
    _arrangeSubtasks();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _arrangeSubtasks() => setState(() => _subtasks = _task.subtasks);

  void _toggleTaskCompletion(TaskManagerCubit cubit) {
    cubit.toggleTaskCompletion(_task).then((isCompleted) {
      setState(() {
        _task.isDone = isCompleted;
        _arrangeSubtasks();
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
          width: 90, // Increased from 70 to fix overflow
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                ), // Add minimal padding
                child: const Icon(
                  CupertinoIcons.pencil,
                  size: 20,
                ), // Reduced size
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
                MagicButton(onGenerate: _generateTaskBreakdown),
                const SizedBox(height: 24),
                SubtasksList(
                  subtasks: _subtasks,
                  parentTask: _task,
                  onAdd: _showAddSubtaskDialog,
                  onDelete: _deleteSubtask,
                  onEstimate: _estimateSubtaskTimes,
                ),
                const SizedBox(height: 24),
                ScheduleButton(onSchedule: _scheduleSubtasks),
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
        _arrangeSubtasks();
      });
    });
  }

  void _confirmDelete(BuildContext context) {
    final subtaskCount = _task.subtasks.length;
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
      final subtasks = await context
          .read<TaskManagerCubit>()
          .breakdownAndScheduleTask(_task);
      setState(() {
        _subtasks = subtasks;
        _isLoading = false;
      });
      logInfo('Generated ${_subtasks.length} subtasks for ${_task.title}');
    } catch (e) {
      logError('Error generating breakdown: $e');
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to generate breakdown');
    }
  }

  void _scheduleSubtasks() {
    if (_subtasks.isEmpty) {
      setState(() => _isLoading = true);
      try {
        context.read<TaskManagerCubit>().scheduleTask(_task);
        setState(() => _isLoading = false);
        _showScheduledDialog(context, hasSubtasks: false);
      } catch (e) {
        logError('Error scheduling task: $e');
        setState(() => _isLoading = false);
        _showErrorDialog('Failed to schedule task');
      }
    } else {
      _showScheduledDialog(context, hasSubtasks: true);
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

  void _showScheduledDialog(BuildContext context, {required bool hasSubtasks}) {
    showCupertinoDialog(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: Text(hasSubtasks ? 'Tasks Scheduled' : 'Task Scheduled'),
            content: Text(
              hasSubtasks
                  ? 'Subtasks are scheduled. View them in the calendar.'
                  : 'Task scheduled in the calendar.',
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('View in Calendar'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushReplacement(
                    CupertinoPageRoute(builder: (_) => const CalendarScreen()),
                  );
                },
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

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (_) => const CalendarScreen()),
        );
      }
    });
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
                    _subtasks.remove(subtask);
                    _task.subtasks.remove(subtask);
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

  Future<void> _estimateSubtaskTimes() async {
    if (_subtasks.isEmpty) return _showErrorDialog('No subtasks to estimate');
    setState(() => _isLoading = true);
    try {
      for (final subtask in _subtasks) {
        final time = await context.read<TaskManagerCubit>().estimateTaskTime(
          subtask,
        );
        subtask.estimatedTime = time;
        subtask.save();
      }
      setState(() => _isLoading = false);
      showCupertinoDialog(
        context: context,
        builder:
            (_) => CupertinoAlertDialog(
              title: const Text('Subtasks Estimated'),
              content: const Text('Reschedule subtasks now?'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('No'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('Yes'),
                  onPressed: () {
                    Navigator.pop(context);
                    _rescheduleSubtasks();
                  },
                ),
              ],
            ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to estimate times: $e');
    }
  }

  Future<void> _rescheduleSubtasks() async {
    setState(() => _isLoading = true);
    try {
      context.read<TaskManagerCubit>().removeScheduledTasks();
      for (final subtask in _subtasks) {
        context.read<TaskManagerCubit>().scheduleTask(subtask);
      }
      setState(() => _isLoading = false);
      _showScheduledDialog(context, hasSubtasks: true);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to reschedule: $e');
    }
  }

  void _showAddSubtaskDialog() =>
      AddSubtaskDialog.show(context, _task, _addSubtask);

  void _addSubtask(
    String title,
    int estimatedTime,
    int priority,
    int deadline,
  ) {
    final subtask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      priority: priority,
      deadline: deadline,
      estimatedTime: estimatedTime,
      category: _task.category,
      parentTask: _task,
    );
    setState(() {
      _task.subtasks.add(subtask);
      _subtasks.add(subtask);
    });
    _task.save();
    context.read<TaskManagerCubit>().scheduleTask(subtask);
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
  final VoidCallback onEstimate;

  const SubtasksList({
    required this.subtasks,
    required this.parentTask,
    required this.onAdd,
    required this.onDelete,
    required this.onEstimate,
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
              if (subtasks.isNotEmpty)
                Flexible(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: onEstimate,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.wand_stars,
                          size: 16,
                          color: CupertinoColors.systemGreen,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Estimate',
                            style: theme.textTheme.textStyle.copyWith(
                              color: CupertinoColors.systemGreen,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                '${subtasks.length}',
                style: theme.textTheme.textStyle.copyWith(
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...subtasks.map(
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
              color: CategoryUtils.getCategoryColor(subtask.category.name),
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

// Schedule Button Widget (unchanged)
class ScheduleButton extends StatelessWidget {
  final VoidCallback onSchedule;

  const ScheduleButton({required this.onSchedule, super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton.filled(
      padding: TaskPageConstants.buttonPadding,
      onPressed: onSchedule,
      child: const Text('Schedule Task'),
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

// Add Subtask Dialog Widget (unchanged for brevity)
class AddSubtaskDialog {
  static void show(
    BuildContext context,
    Task parentTask,
    Function(String, int, int, int) onAdd,
  ) {
    final titleController = TextEditingController();
    int estimatedTime = 0;
    int priority = 1;
    int deadline = parentTask.deadline;

    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  padding: const EdgeInsets.all(TaskPageConstants.padding),
                  color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Text(
                            'Add Subtask',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: const Text('Add'),
                            onPressed: () {
                              if (_validate(
                                titleController.text,
                                estimatedTime,
                                deadline,
                                parentTask,
                                context,
                              )) {
                                onAdd(
                                  titleController.text,
                                  estimatedTime,
                                  priority,
                                  deadline,
                                );
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        titleController,
                        'Title',
                        'Enter subtask title',
                      ),
                      const SizedBox(height: 16),
                      _buildTimePicker(
                        context,
                        estimatedTime,
                        (value) => setState(() => estimatedTime = value),
                      ),
                      const SizedBox(height: 16),
                      _buildPrioritySlider(
                        priority,
                        (value) => setState(() => priority = value),
                      ),
                      const SizedBox(height: 16),
                      _buildDeadlinePicker(
                        context,
                        deadline,
                        (value) => setState(() => deadline = value),
                      ),
                    ],
                  ),
                ),
          ),
    ).then((_) => titleController.dispose());
  }

  static bool _validate(
    String title,
    int estimatedTime,
    int deadline,
    Task parentTask,
    BuildContext context,
  ) {
    if (title.isEmpty) {
      _showError(context, 'Please enter a title');
      return false;
    }
    if (estimatedTime <= 0) {
      _showError(context, 'Select an estimated time greater than 0');
      return false;
    }
    if (estimatedTime > parentTask.estimatedTime) {
      _showError(context, 'Subtask time cannot exceed parent task time');
      return false;
    }
    if (deadline > parentTask.deadline) {
      _showError(
        context,
        'Subtask deadline cannot exceed parent task deadline',
      );
      return false;
    }
    return true;
  }

  static void _showError(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  static Widget _buildTextField(
    TextEditingController controller,
    String label,
    String placeholder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemGrey4),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  static Widget _buildTimePicker(
    BuildContext context,
    int currentTime,
    Function(int) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estimated Time',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final time = await _showTimePicker(context);
            if (time != null) onChanged(time);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimated Time',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.systemBlue,
                  ),
                ),
                Text(
                  DurationFormatter.format(currentTime),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Future<int?> _showTimePicker(BuildContext context) {
    int? hours;
    int? minutes;
    return showCupertinoModalPopup<int>(
      context: context,
      builder:
          (_) => Container(
            height: 300,
            color: CupertinoColors.systemBackground,
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 32,
                          onSelectedItemChanged: (index) => hours = index,
                          children: [
                            for (var i = 0; i <= 120; i++) Text('$i hours'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 32,
                          onSelectedItemChanged:
                              (index) => minutes = index * 15,
                          children: [
                            for (var i = 0; i < 4; i++)
                              Text('${i * 15} minutes'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed:
                          () => Navigator.pop(
                            context,
                            (hours ?? 0) * 3600000 + (minutes ?? 0) * 60000,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  static Widget _buildPrioritySlider(int priority, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority: $priority',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        CupertinoSlider(
          min: 1,
          max: 10,
          divisions: 9,
          value: priority.toDouble(),
          onChanged: (value) => onChanged(value.toInt()),
          activeColor: CupertinoColors.systemOrange,
        ),
      ],
    );
  }

  static Widget _buildDeadlinePicker(
    BuildContext context,
    int deadline,
    Function(int) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deadline',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            final now = DateTime.now();
            showCupertinoModalPopup(
              context: context,
              builder:
                  (_) => Container(
                    height: 300,
                    color: CupertinoColors.systemBackground,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 220,
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.date,
                            initialDateTime:
                                DateTime.fromMillisecondsSinceEpoch(
                                      deadline,
                                    ).isBefore(now)
                                    ? now
                                    : DateTime.fromMillisecondsSinceEpoch(
                                      deadline,
                                    ),
                            minimumDate: now,
                            onDateTimeChanged:
                                (val) => onChanged(val.millisecondsSinceEpoch),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            CupertinoButton(
                              child: const Text('Cancel'),
                              onPressed: () => Navigator.pop(context),
                            ),
                            CupertinoButton(
                              child: const Text('Done'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Date',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.systemBlue,
                  ),
                ),
                Text(
                  DateTime.fromMillisecondsSinceEpoch(
                    deadline,
                  ).toLocal().toString().split(' ')[0],
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
