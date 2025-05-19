import 'package:flowo_client/blocs/analytics/analytics_cubit.dart';
import 'package:flowo_client/blocs/analytics/analytics_state.dart';
import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/blocs/tasks_controller/task_manager_state.dart';
import 'package:flowo_client/models/analytics_data.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/scheduled_task_type.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/screens/event/event_form_screen.dart';
import 'package:flowo_client/screens/habit/habit_form_screen.dart';
import 'package:flowo_client/screens/task/task_form_screen.dart';
import 'package:flowo_client/screens/task/task_reschedule_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        Color,
        BoxShadow,
        TextStyle,
        FontWeight,
        CircularProgressIndicator,
        AlwaysStoppedAnimation;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Formatter for analytics data
abstract class AnalyticsFormatter {
  String formatNumber(num value);
  String formatPercent(double value);
  String getEfficiencyMessage(double score);
}

/// Default implementation of AnalyticsFormatter
class DefaultAnalyticsFormatter implements AnalyticsFormatter {
  @override
  String formatNumber(num value) => value.toString();

  @override
  String formatPercent(double value) => '${value.toStringAsFixed(1)}%';

  @override
  String getEfficiencyMessage(double score) {
    if (score >= 90) {
      return 'Excellent! You\'re extremely efficient at managing your tasks.';
    } else if (score >= 75) {
      return 'Great job! You\'re doing well at managing your tasks.';
    } else if (score >= 60) {
      return 'Good progress. Keep working on improving your task management.';
    } else if (score >= 40) {
      return 'You\'re making progress, but there\'s room for improvement.';
    } else {
      return 'You might need to work on your task management skills.';
    }
  }
}

/// A unified screen that combines analytics and task statistics
class UnifiedAnalyticsScreen extends StatefulWidget {
  const UnifiedAnalyticsScreen({super.key});

  @override
  State<UnifiedAnalyticsScreen> createState() => _UnifiedAnalyticsScreenState();
}

class _UnifiedAnalyticsScreenState extends State<UnifiedAnalyticsScreen> {
  late AnalyticsCubit _analyticsCubit;
  late TaskManagerCubit _taskManagerCubit;

  // Task statistics data
  List<Task> _impossibleTasks = [];
  List<Task> _needsReschedulingTasks = [];
  List<Task> _unscheduledTasksList = [];
  int _totalScheduledTasks = 0;
  int _completedTasks = 0;
  int _overdueTasks = 0;
  int _upcomingTasks = 0;
  int _unscheduledTasks = 0;

  // Duration statistics
  int _totalDuration = 0;
  int _tasksWithDuration = 0;
  int _averageDuration = 0;
  int _longestTaskDuration = 0;
  String _longestTaskTitle = '';

  @override
  void initState() {
    super.initState();
    _analyticsCubit = BlocProvider.of<AnalyticsCubit>(context);
    _taskManagerCubit = BlocProvider.of<TaskManagerCubit>(context);
    _loadData();
  }

  void _loadData() {
    _analyticsCubit.loadAnalytics();
    _loadTaskStatistics();
  }

  void _loadTaskStatistics() {
    final tasks = _taskManagerCubit.state.tasks;
    final scheduledTasks = _taskManagerCubit.getScheduledTasks();

    _totalScheduledTasks =
        scheduledTasks
            .where(
              (task) =>
                  task.type == ScheduledTaskType.defaultType ||
                  task.type == ScheduledTaskType.timeSensitive,
            )
            .length;
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

    // Find unscheduled tasks
    _unscheduledTasksList = _findUnscheduledTasks(tasks);
    _unscheduledTasks = _unscheduledTasksList.length;

    // Find tasks that are impossible to complete or need rescheduling
    _analyzeTaskUrgency(tasks, scheduledTasks);

    // Calculate duration statistics
    _calculateDurationStatistics(tasks);
  }

  void _calculateDurationStatistics(List<Task> tasks) {
    _totalDuration = 0;
    _tasksWithDuration = 0;
    _longestTaskDuration = 0;
    _longestTaskTitle = '';

    for (var task in tasks) {
      final duration = _taskManagerCubit.getTotalDuration(task);
      if (duration > 0) {
        _totalDuration += duration;
        _tasksWithDuration++;

        if (duration > _longestTaskDuration) {
          _longestTaskDuration = duration;
          _longestTaskTitle = task.title;
        }
      }
    }

    _averageDuration =
        _tasksWithDuration > 0 ? (_totalDuration ~/ _tasksWithDuration) : 0;
  }

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
          timeLeft - _taskManagerCubit.getBusyTime(task.deadline);
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

  List<Task> _findUnscheduledTasks(List<Task> tasks) {
    final now = DateTime.now().millisecondsSinceEpoch;

    return tasks
        .where(
          (task) =>
              !task.isDone &&
              task.scheduledTasks.isEmpty &&
              task.deadline > now &&
              _canTaskBeOverdue(task),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Analytics & Task Statistics'),
      ),
      child: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<AnalyticsCubit, AnalyticsState>(
              listener: (context, state) {
                if (state is AnalyticsLoaded) {
                  setState(() {});
                }
              },
            ),
            BlocListener<TaskManagerCubit, TaskManagerState>(
              listener: (context, state) {
                _loadTaskStatistics();
              },
            ),
          ],
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<AnalyticsCubit, AnalyticsState>(
      builder: (context, state) {
        if (state is AnalyticsLoading) {
          return const Center(child: CupertinoActivityIndicator());
        } else if (state is AnalyticsError) {
          return _buildErrorState(context, state.message);
        } else if (state is AnalyticsLoaded) {
          return _buildAnalyticsContent(context, state.analyticsData);
        }
        return const Center(child: CupertinoActivityIndicator());
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 48,
            color: CupertinoColors.systemRed.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading analytics',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              style: CupertinoTheme.of(context).textTheme.textStyle,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: () => _loadData(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent(
    BuildContext context,
    AnalyticsData analyticsData,
  ) {
    final formatter = DefaultAnalyticsFormatter();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(analyticsData),
        const SizedBox(height: 16),
        _buildTaskStatusCard(analyticsData),
        const SizedBox(height: 16),
        _buildTimeTrackingCard(),
        const SizedBox(height: 16),
        EfficiencyScoreCard(
          score: analyticsData.efficiencyScore,
          formatter: formatter,
        ),
        const SizedBox(height: 16),
        if (analyticsData.aiSuggestions.isNotEmpty) ...[
          AiSuggestionsCard(suggestions: analyticsData.aiSuggestions),
          const SizedBox(height: 16),
        ],
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
    );
  }

  Widget _buildSummaryCard(AnalyticsData analyticsData) {
    return AnalyticsCard(
      title: 'Summary',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatItem(
                icon: CupertinoIcons.list_bullet,
                value: _totalScheduledTasks.toString(),
                label: 'Scheduled',
              ),
              StatItem(
                icon: CupertinoIcons.check_mark,
                value: _completedTasks.toString(),
                label: 'Completed',
                color: CupertinoColors.activeGreen,
              ),
              StatItem(
                icon: CupertinoIcons.exclamationmark_circle,
                value: _overdueTasks.toString(),
                label: 'Overdue',
                color: CupertinoColors.systemRed,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatItem(
                icon: CupertinoIcons.clock,
                value: _upcomingTasks.toString(),
                label: 'Upcoming',
                color: CupertinoColors.activeBlue,
              ),
              StatItem(
                icon: CupertinoIcons.exclamationmark_triangle,
                value: _impossibleTasks.length.toString(),
                label: 'Impossible',
                color: CupertinoColors.systemRed,
              ),
              StatItem(
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

  Widget _buildTaskStatusCard(AnalyticsData analyticsData) {
    return AnalyticsCard(
      title: 'Task Status',
      child: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ProgressItem(
                value: analyticsData.completionRate,
                label: 'Completion Rate',
                color: CupertinoColors.activeGreen,
                formatter: DefaultAnalyticsFormatter(),
              ),
              ProgressItem(
                value: analyticsData.overdueRate,
                label: 'Overdue Rate',
                color: CupertinoColors.systemRed,
                formatter: DefaultAnalyticsFormatter(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTrackingCard() {
    return AnalyticsCard(
      title: 'Time Tracking',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatItem(
                icon: CupertinoIcons.time,
                value:
                    Duration(milliseconds: _totalDuration).inHours > 0
                        ? '${Duration(milliseconds: _totalDuration).inHours}h ${Duration(milliseconds: _totalDuration).inMinutes.remainder(60)}m'
                        : '${Duration(milliseconds: _totalDuration).inMinutes}m',
                label: 'Total Time',
                color: CupertinoColors.activeBlue,
              ),
              StatItem(
                icon: CupertinoIcons.timer,
                value:
                    Duration(milliseconds: _averageDuration).inHours > 0
                        ? '${Duration(milliseconds: _averageDuration).inHours}h ${Duration(milliseconds: _averageDuration).inMinutes.remainder(60)}m'
                        : '${Duration(milliseconds: _averageDuration).inMinutes}m',
                label: 'Average Time',
                color: CupertinoColors.systemPurple,
              ),
              StatItem(
                icon: CupertinoIcons.number,
                value: _tasksWithDuration.toString(),
                label: 'Tasks Tracked',
                color: CupertinoColors.systemTeal,
              ),
            ],
          ),
          if (_longestTaskDuration > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Longest Task:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color:
                          CupertinoTheme.of(context).textTheme.textStyle.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _longestTaskTitle,
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          CupertinoTheme.of(context).textTheme.textStyle.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Duration: ${Duration(milliseconds: _longestTaskDuration).inHours > 0 ? '${Duration(milliseconds: _longestTaskDuration).inHours}h ${Duration(milliseconds: _longestTaskDuration).inMinutes.remainder(60)}m' : '${Duration(milliseconds: _longestTaskDuration).inMinutes}m'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImpossibleTasksCard() {
    return AnalyticsCard(
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
          ..._impossibleTasks.map((task) => _buildTaskListItem(task, true)),
        ],
      ),
    );
  }

  Widget _buildTaskListItem(Task task, bool isImpossible) {
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;
    final secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _showTaskOptions(task, isImpossible),
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

  Widget _buildReschedulingTasksCard() {
    return AnalyticsCard(
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
            (task) => _buildTaskListItem(task, false),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleActionsCard() {
    return AnalyticsCard(
      title: 'Schedule Actions',
      child: Column(
        children: [
          CupertinoButton.filled(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _taskManagerCubit.scheduleTasks();
              _taskManagerCubit.scheduleHabits();
              setState(() {
                _loadTaskStatistics();
              });
            },
            child: const Text('Reschedule All Tasks'),
          ),
          const SizedBox(height: 12),
          if (_unscheduledTasks > 0) ...[
            CupertinoButton.filled(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _scheduleUnscheduledTasks();
              },
              child: Text('Schedule Unscheduled Tasks ($_unscheduledTasks)'),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  void _showTaskOptions(Task task, bool isImpossible) {
    final timeLeft = task.deadline - DateTime.now().millisecondsSinceEpoch;
    final trueTimeLeft =
        timeLeft - _taskManagerCubit.getBusyTime(task.deadline);
    final timeNeeded = Duration(
      milliseconds: task.estimatedTime - trueTimeLeft,
    );

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
          'more time to complete this task before the deadline.';
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
                            ),
                      ),
                    ).then((_) {
                      // Refresh the statistics when returning from the reschedule screen
                      setState(() {
                        _loadTaskStatistics();
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

  void _scheduleUnscheduledTasks() {
    if (_unscheduledTasksList.isEmpty) return;

    // Schedule all tasks (including unscheduled ones)
    _taskManagerCubit.scheduleTasks();

    // Refresh the statistics
    setState(() {
      _loadTaskStatistics();
    });

    // Show confirmation
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Tasks Scheduled'),
            content: Text(
              '${_unscheduledTasksList.length} unscheduled tasks have been scheduled.',
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

/// Card widget with iOS styling
class AnalyticsCard extends StatelessWidget {
  final String title;
  final Widget child;

  const AnalyticsCard({super.key, required this.title, required this.child});

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
      margin: const EdgeInsets.symmetric(vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              title,
              style: CupertinoTheme.of(
                context,
              ).textTheme.navTitleTextStyle.copyWith(fontSize: 20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying a statistic with an icon
class StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  const StatItem({
    super.key,
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
        Icon(icon, size: 28, color: resolvedColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CupertinoTheme.of(context).textTheme.textStyle.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: CupertinoTheme.of(
            context,
          ).textTheme.tabLabelTextStyle.copyWith(fontSize: 14),
        ),
      ],
    );
  }
}

/// Widget for displaying a circular progress indicator
class ProgressItem extends StatelessWidget {
  final double value;
  final String label;
  final Color color;
  final AnalyticsFormatter formatter;

  const ProgressItem({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = CupertinoDynamicColor.resolve(color, context);
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;

    // Ensure value is finite and between 0-100
    final safeValue = value.isFinite ? value.clamp(0.0, 100.0) : 0.0;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: safeValue / 100,
                backgroundColor: CupertinoColors.systemGrey5.resolveFrom(
                  context,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(resolvedColor),
                strokeWidth: 8,
              ),
            ),
            Text(
              formatter.formatPercent(safeValue),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: CupertinoTheme.of(
            context,
          ).textTheme.tabLabelTextStyle.copyWith(fontSize: 14),
        ),
      ],
    );
  }
}

/// Card for displaying AI suggestions
class AiSuggestionsCard extends StatelessWidget {
  final List<String> suggestions;

  const AiSuggestionsCard({super.key, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    return AnalyticsCard(
      title: 'AI Suggestions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            suggestions.map((suggestion) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      CupertinoIcons.lightbulb,
                      color: CupertinoColors.systemYellow.resolveFrom(context),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: CupertinoTheme.of(context).textTheme.textStyle,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}

/// Card for displaying efficiency score
class EfficiencyScoreCard extends StatelessWidget {
  final double score;
  final AnalyticsFormatter formatter;

  const EfficiencyScoreCard({
    super.key,
    required this.score,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;

    return AnalyticsCard(
      title: 'Efficiency Score',
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                score.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.activeBlue.resolveFrom(context),
                ),
              ),
              Text(
                '/100',
                style: TextStyle(
                  fontSize: 24,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            formatter.getEfficiencyMessage(score),
            style: CupertinoTheme.of(context).textTheme.textStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// This class is no longer needed as we've moved its functionality to _buildTaskListItem method
