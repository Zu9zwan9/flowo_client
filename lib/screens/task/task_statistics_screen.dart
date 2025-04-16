import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, BoxShadow;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/blocs/tasks_controller/task_manager_state.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/utils/task_urgency_calculator.dart';
import 'package:flowo_client/models/day.dart';
import 'package:hive/hive.dart';
import 'package:flutter/services.dart';
import 'task_reschedule_screen.dart';
import 'task_form_screen.dart';
import '../event/event_form_screen.dart';
import '../habit/habit_form_screen.dart';

/// Screen for displaying task execution statistics and scheduling information
class TaskStatisticsScreen extends StatefulWidget {
  const TaskStatisticsScreen({super.key});

  @override
  State<TaskStatisticsScreen> createState() => _TaskStatisticsScreenState();
}

class _TaskStatisticsScreenState extends State<TaskStatisticsScreen> {
  late TaskUrgencyCalculator _urgencyCalculator;
  List<Task> _impossibleTasks = [];
  List<Task> _needsReschedulingTasks = [];
  int _totalScheduledTasks = 0;
  int _completedTasks = 0;
  int _overdueTasks = 0;
  int _upcomingTasks = 0;

  @override
  void initState() {
    super.initState();
    _urgencyCalculator = TaskUrgencyCalculator(
      Hive.box<Day>('scheduled_tasks'),
    );
    _loadStatistics();
  }

  void _loadStatistics() {
    final tasksCubit = context.read<TaskManagerCubit>();
    final tasks = tasksCubit.state.tasks;
    final scheduledTasks = tasksCubit.getScheduledTasks();

    _totalScheduledTasks = scheduledTasks.length;
    _completedTasks = tasks.where((task) => task.isDone).length;
    _overdueTasks =
        tasks
            .where(
              (task) =>
                  !task.isDone &&
                  task.deadline < DateTime.now().millisecondsSinceEpoch &&
                  _canTaskBeOverdue(task),
            )
            .length;
    _upcomingTasks = _totalScheduledTasks - _completedTasks - _overdueTasks;

    // Find tasks that are impossible to complete or need rescheduling
    _analyzeTaskUrgency(tasks, scheduledTasks);
  }

  // Helper method to determine if a task can be overdue
  // Only tasks with subtasks or without can be overdue
  // Events, habits, and free time tasks can't be overdue
  bool _canTaskBeOverdue(Task task) {
    // Check if it's an event (category name contains "event")
    if (task.category.name.toLowerCase().contains('event')) {
      return false;
    }

    // Check if it's a habit (has frequency)
    if (task.frequency != null) {
      return false;
    }

    // Check if it's a free time task (category name is "Free Time Manager")
    if (task.category.name == 'Free Time Manager') {
      return false;
    }

    // Regular tasks can be overdue
    return true;
  }

  void _analyzeTaskUrgency(
    List<Task> tasks,
    List<ScheduledTask> scheduledTasks,
  ) {
    _impossibleTasks = [];
    _needsReschedulingTasks = [];

    for (var task in tasks) {
      if (task.isDone) continue;
      if (!_canTaskBeOverdue(task)) {
        continue; // Skip tasks that can't be overdue
      }

      final timeLeft = task.deadline - DateTime.now().millisecondsSinceEpoch;
      if (timeLeft <= 0) continue; // Already overdue

      final trueTimeLeft =
          timeLeft - _calculateBusyTime(task.deadline, scheduledTasks);
      final timeCoefficient =
          (trueTimeLeft - task.estimatedTime) *
          (trueTimeLeft + task.estimatedTime);

      if (timeCoefficient < 0) {
        if (timeLeft - task.estimatedTime < 0) {
          _impossibleTasks.add(task);
        } else {
          _needsReschedulingTasks.add(task);
        }
      }
    }
  }

  int _calculateBusyTime(int deadline, List<ScheduledTask> scheduledTasks) {
    final now = DateTime.now().millisecondsSinceEpoch;
    int busyTime = 0;

    for (var scheduledTask in scheduledTasks) {
      if (scheduledTask.startTime.millisecondsSinceEpoch >= now &&
          scheduledTask.endTime.millisecondsSinceEpoch <= deadline) {
        busyTime +=
            scheduledTask.endTime
                .difference(scheduledTask.startTime)
                .inMilliseconds;
      }
    }

    return busyTime;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Task Statistics'),
      ),
      child: SafeArea(
        child: BlocListener<TaskManagerCubit, TaskManagerState>(
          listener: (context, state) {
            _loadStatistics();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 16),
              _buildTaskStatusCard(),
              const SizedBox(height: 16),
              if (_impossibleTasks.isNotEmpty) ...[
                _buildImpossibleTasksCard(),
                const SizedBox(height: 16),
              ],
              if (_needsReschedulingTasks.isNotEmpty) ...[
                _buildReschedulingTasksCard(),
                const SizedBox(height: 16),
              ],
              _buildScheduleActionsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return _StatisticsCard(
      title: 'Summary',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: CupertinoIcons.calendar,
                value: _totalScheduledTasks.toString(),
                label: 'Scheduled',
              ),
              _StatItem(
                icon: CupertinoIcons.check_mark,
                value: _completedTasks.toString(),
                label: 'Completed',
                color: CupertinoColors.activeGreen,
              ),
              _StatItem(
                icon: CupertinoIcons.exclamationmark_circle,
                value: _overdueTasks.toString(),
                label: 'Overdue',
                color: CupertinoColors.systemRed,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: CupertinoIcons.clock,
                value: _upcomingTasks.toString(),
                label: 'Upcoming',
                color: CupertinoColors.activeBlue,
              ),
              _StatItem(
                icon: CupertinoIcons.exclamationmark_triangle,
                value: _impossibleTasks.length.toString(),
                label: 'Impossible',
                color: CupertinoColors.systemRed,
              ),
              _StatItem(
                icon: CupertinoIcons.arrow_2_circlepath,
                value: _needsReschedulingTasks.length.toString(),
                label: 'Need Reschedule',
                color: CupertinoColors.systemOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStatusCard() {
    final completionRate =
        _totalScheduledTasks > 0
            ? (_completedTasks / _totalScheduledTasks * 100).toStringAsFixed(1)
            : '0.0';

    final overdueRate =
        _totalScheduledTasks > 0
            ? (_overdueTasks / _totalScheduledTasks * 100).toStringAsFixed(1)
            : '0.0';

    return _StatisticsCard(
      title: 'Task Status',
      child: Column(
        children: [
          _ProgressBar(
            label: 'Completion Rate',
            value: double.parse(completionRate),
            color: CupertinoColors.activeGreen,
          ),
          const SizedBox(height: 16),
          _ProgressBar(
            label: 'Overdue Rate',
            value: double.parse(overdueRate),
            color: CupertinoColors.systemRed,
          ),
        ],
      ),
    );
  }

  Widget _buildImpossibleTasksCard() {
    return _StatisticsCard(
      title: 'Tasks Impossible to Complete',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The following tasks cannot be completed before their deadlines:',
            style: TextStyle(
              color: CupertinoColors.label.resolveFrom(context),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ..._impossibleTasks.map(
            (task) => _TaskListItem(
              task: task,
              onTap: () => _showTaskOptions(task, true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReschedulingTasksCard() {
    return _StatisticsCard(
      title: 'Tasks That Need Rescheduling',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The following tasks need rescheduling to be completed on time:',
            style: TextStyle(
              color: CupertinoColors.label.resolveFrom(context),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ..._needsReschedulingTasks.map(
            (task) => _TaskListItem(
              task: task,
              onTap: () => _showTaskOptions(task, false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleActionsCard() {
    return _StatisticsCard(
      title: 'Schedule Actions',
      child: Column(
        children: [
          CupertinoButton.filled(
            onPressed: () {
              HapticFeedback.mediumImpact();
              final tasksCubit = context.read<TaskManagerCubit>();
              tasksCubit.scheduleTasks();
              tasksCubit.scheduleHabits();
              setState(() {
                _loadStatistics();
              });
            },
            child: const Text('Reschedule All Tasks'),
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              final tasksCubit = context.read<TaskManagerCubit>();
              tasksCubit.removeScheduledTasks();
              setState(() {
                _loadStatistics();
              });
            },
            child: const Text('Clear All Scheduled Tasks'),
          ),
        ],
      ),
    );
  }

  void _showTaskOptions(Task task, bool isImpossible) {
    final timeLeft = task.deadline - DateTime.now().millisecondsSinceEpoch;
    final trueTimeLeft =
        timeLeft -
        _calculateBusyTime(
          task.deadline,
          context.read<TaskManagerCubit>().getScheduledTasks(),
        );

    final timeNeeded = Duration(
      milliseconds: task.estimatedTime - trueTimeLeft,
    );
    final freeTime = Duration(milliseconds: trueTimeLeft);

    String message;
    if (isImpossible) {
      message =
          'This task is impossible to complete before the deadline. '
          'You need ${timeNeeded.inHours}h ${timeNeeded.inMinutes.remainder(60)}m '
          'more time than available before the deadline.';
    } else {
      message =
          'This task is possible to complete if you reschedule some other tasks. '
          'You need ${timeNeeded.inHours}h ${timeNeeded.inMinutes.remainder(60)}m '
          'more time, and you have ${freeTime.inHours}h ${freeTime.inMinutes.remainder(60)}m '
          'of free time before the deadline.';
    }

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: Text(task.title),
            message: Text(message),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _editTask(task);
                },
                child: const Text('Edit Task'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _extendDeadline(task, timeNeeded);
                },
                child: const Text('Extend Deadline'),
              ),
              if (!isImpossible)
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to the task reschedule screen
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder:
                            (context) => TaskRescheduleScreen(
                              targetTask: task,
                              timeNeeded: timeNeeded,
                              freeTime: freeTime,
                            ),
                      ),
                    ).then((_) {
                      // Refresh the statistics when returning from the reschedule screen
                      setState(() {
                        _loadStatistics();
                      });
                    });
                  },
                  child: const Text('Reschedule Other Tasks'),
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  void _editTask(Task task) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) {
          if (task.category.name.toLowerCase().contains('event')) {
            return EventFormScreen(event: task);
          } else if (task.frequency != null) {
            return HabitFormScreen(habit: task);
          } else {
            return TaskFormScreen(task: task);
          }
        },
      ),
    );
  }

  void _extendDeadline(Task task, Duration additionalTime) {
    final tasksCubit = context.read<TaskManagerCubit>();

    // Calculate new deadline
    final newDeadline = task.deadline + additionalTime.inMilliseconds;

    // Update the task with the new deadline
    tasksCubit.editTask(
      task: task,
      title: task.title,
      priority: task.priority,
      estimatedTime: task.estimatedTime,
      deadline: newDeadline,
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
      optimisticTime: task.optimisticTime,
      realisticTime: task.realisticTime,
      pessimisticTime: task.pessimisticTime,
      firstNotification: task.firstNotification,
      secondNotification: task.secondNotification,
    );

    // Show confirmation
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Deadline Extended'),
            content: Text(
              'The deadline for "${task.title}" has been extended by '
              '${additionalTime.inHours}h ${additionalTime.inMinutes.remainder(60)}m.',
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}

/// Card widget for displaying statistics
class _StatisticsCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _StatisticsCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              title,
              style: CupertinoTheme.of(
                context,
              ).textTheme.navTitleTextStyle.copyWith(fontSize: 18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying a statistic with an icon
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        color != null
            ? CupertinoDynamicColor.resolve(color!, context)
            : CupertinoTheme.of(context).primaryColor;

    return Column(
      children: [
        Icon(icon, size: 24, color: resolvedColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: CupertinoTheme.of(context).textTheme.textStyle.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }
}

/// Widget for displaying a progress bar
class _ProgressBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ProgressBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = CupertinoDynamicColor.resolve(color, context);
    final backgroundColor = CupertinoColors.systemGrey5.resolveFrom(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoTheme.of(context).textTheme.textStyle.color,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: resolvedColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: value / 100,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: resolvedColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget for displaying a task in a list
class _TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const _TaskListItem({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;
    final secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
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
            Icon(CupertinoIcons.chevron_right, color: secondaryColor, size: 18),
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
