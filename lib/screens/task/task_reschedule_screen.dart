import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, BoxShadow;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flutter/services.dart';

/// Screen for rescheduling tasks to make room for a specific task
class TaskRescheduleScreen extends StatefulWidget {
  final Task targetTask;
  final Duration timeNeeded;
  final Duration freeTime;

  const TaskRescheduleScreen({
    super.key,
    required this.targetTask,
    required this.timeNeeded,
    required this.freeTime,
  });

  @override
  State<TaskRescheduleScreen> createState() => _TaskRescheduleScreenState();
}

class _TaskRescheduleScreenState extends State<TaskRescheduleScreen> {
  List<Task> _reschedulableTasks = [];
  final Set<String> _selectedTaskIds = {};
  Duration _selectedDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadReschedulableTasks();
  }

  void _loadReschedulableTasks() {
    final tasksCubit = context.read<TaskManagerCubit>();
    final allTasks = tasksCubit.state.tasks;
    final now = DateTime.now().millisecondsSinceEpoch;
    final deadline = widget.targetTask.deadline;

    // Find tasks that can be rescheduled (not completed, not the target task, and due before the target task)
    _reschedulableTasks =
        allTasks.where((task) {
          return !task.isDone &&
              task.id != widget.targetTask.id &&
              task.deadline > now &&
              task.deadline <= deadline &&
              task.scheduledTasks.isNotEmpty;
        }).toList();

    // Sort by urgency (lower priority and further deadline first)
    _reschedulableTasks.sort((a, b) {
      // First sort by priority (lower first)
      final priorityComparison = a.priority.compareTo(b.priority);
      if (priorityComparison != 0) return priorityComparison;

      // Then sort by deadline (further first)
      return b.deadline.compareTo(a.deadline);
    });
  }

  void _toggleTaskSelection(Task task) {
    setState(() {
      if (_selectedTaskIds.contains(task.id)) {
        _selectedTaskIds.remove(task.id);
        _selectedDuration -= Duration(milliseconds: task.estimatedTime);
      } else {
        _selectedTaskIds.add(task.id);
        _selectedDuration += Duration(milliseconds: task.estimatedTime);
      }
    });
  }

  bool _canReschedule() {
    return _selectedDuration >= widget.timeNeeded;
  }

  void _rescheduleSelectedTasks() {
    if (!_canReschedule()) return;

    final tasksCubit = context.read<TaskManagerCubit>();

    // Remove scheduled tasks for selected tasks
    for (var taskId in _selectedTaskIds) {
      final task = _reschedulableTasks.firstWhere((t) => t.id == taskId);
      // Remove all scheduled tasks for this task
      task.scheduledTasks.clear();
      // Save the task
      tasksCubit.editTask(
        task: task,
        title: task.title,
        priority: task.priority,
        estimatedTime: task.estimatedTime,
        deadline: task.deadline,
        category: task.category,
        parentTask:
            task.parentTaskId != null
                ? tasksCubit.state.tasks.firstWhere(
                  (t) => t.id == task.parentTaskId,
                )
                : null,
        notes: task.notes,
        color: task.color,
        frequency: task.frequency,
      );
    }

    // Reschedule the target task
    tasksCubit.scheduleTasks();

    // Show confirmation
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Tasks Rescheduled'),
            content: Text(
              'Selected tasks have been unscheduled to make room for "${widget.targetTask.title}".',
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to statistics screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Reschedule Tasks for ${widget.targetTask.title}'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildInfoCard(),
            Expanded(child: _buildTaskList()),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).barBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? CupertinoColors.black.withOpacity(0.1)
                    : CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Information',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'You need ${widget.timeNeeded.inHours}h ${widget.timeNeeded.inMinutes.remainder(60)}m more time to complete this task.',
            style: CupertinoTheme.of(context).textTheme.textStyle,
          ),
          const SizedBox(height: 4),
          Text(
            'You have ${widget.freeTime.inHours}h ${widget.freeTime.inMinutes.remainder(60)}m of free time before the deadline.',
            style: CupertinoTheme.of(context).textTheme.textStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Selected: ${_selectedDuration.inHours}h ${_selectedDuration.inMinutes.remainder(60)}m of ${widget.timeNeeded.inHours}h ${widget.timeNeeded.inMinutes.remainder(60)}m needed',
            style: TextStyle(
              color:
                  _canReschedule()
                      ? CupertinoColors.activeGreen.resolveFrom(context)
                      : CupertinoTheme.of(context).textTheme.textStyle.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    if (_reschedulableTasks.isEmpty) {
      return Center(
        child: Text(
          'No tasks available for rescheduling',
          style: CupertinoTheme.of(context).textTheme.textStyle,
        ),
      );
    }

    return ListView.builder(
      itemCount: _reschedulableTasks.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final task = _reschedulableTasks[index];
        final isSelected = _selectedTaskIds.contains(task.id);

        return _TaskSelectionItem(
          task: task,
          isSelected: isSelected,
          onToggle: () => _toggleTaskSelection(task),
        );
      },
    );
  }

  Widget _buildActionButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: CupertinoButton.filled(
        onPressed: _canReschedule() ? _rescheduleSelectedTasks : null,
        child: const Text('Reschedule Selected Tasks'),
      ),
    );
  }
}

class _TaskSelectionItem extends StatelessWidget {
  final Task task;
  final bool isSelected;
  final VoidCallback onToggle;

  const _TaskSelectionItem({
    required this.task,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;
    final secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? CupertinoColors.systemGrey5.resolveFrom(context)
                  : CupertinoTheme.of(context).barBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected
                    ? CupertinoTheme.of(context).primaryColor
                    : CupertinoColors.separator.resolveFrom(context),
          ),
        ),
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              color:
                  isSelected
                      ? CupertinoTheme.of(context).primaryColor
                      : secondaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Due: ${_formatDate(task.deadline)} • Est: ${_formatDuration(task.estimatedTime)}',
                    style: TextStyle(fontSize: 12, color: secondaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (date.isBefore(tomorrow)) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (date.isBefore(tomorrow.add(const Duration(days: 1)))) {
      return 'Tomorrow ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}
