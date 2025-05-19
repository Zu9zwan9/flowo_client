import 'package:flowo_client/blocs/analytics/analytics_cubit.dart';
import 'package:flowo_client/blocs/analytics/analytics_state.dart';
import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/blocs/tasks_controller/task_manager_state.dart';
import 'package:flowo_client/models/analytics_data.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/scheduled_task_type.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        Color,
        BoxShadow,
        TextStyle,
        FontWeight,
        CircularProgressIndicator,
        AlwaysStoppedAnimation,
        RefreshIndicator;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../event/event_form_screen.dart';
import '../habit/habit_form_screen.dart';
import '../task/task_form_screen.dart';
import '../task/task_reschedule_screen.dart';

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

/// A unified screen that combines analytics and task statistics
/// Following Apple HIG, clean code architecture, OOP, and SOLID principles
class UnifiedAnalyticsScreen extends StatefulWidget {
  const UnifiedAnalyticsScreen({super.key});

  @override
  State<UnifiedAnalyticsScreen> createState() => _UnifiedAnalyticsScreenState();
}

class _UnifiedAnalyticsScreenState extends State<UnifiedAnalyticsScreen> {
  // Analytics formatter
  final AnalyticsFormatter _formatter = DefaultAnalyticsFormatter();

  // Task statistics
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

  // UI state
  bool _isTaskStatsExpanded = true;
  bool _isTimeTrackingExpanded = true;
  bool _isActionableTasksExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();

    // Load analytics data
    final analyticsCubit = context.read<AnalyticsCubit>();
    analyticsCubit.loadAnalytics();
  }

  void _loadStatistics() {
    final tasksCubit = context.read<TaskManagerCubit>();
    final tasks = tasksCubit.state.tasks;
    final scheduledTasks = tasksCubit.getScheduledTasks();

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
    _calculateDurationStatistics(tasks, tasksCubit);
  }

  // Helper method to determine if a task can be overdue
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

  void _calculateDurationStatistics(
    List<Task> tasks,
    TaskManagerCubit tasksCubit,
  ) {
    _totalDuration = 0;
    _tasksWithDuration = 0;
    _longestTaskDuration = 0;
    _longestTaskTitle = '';

    for (var task in tasks) {
      final duration = tasksCubit.getTotalDuration(task);
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

  void _analyzeTaskUrgency(
    List<Task> tasks,
    List<ScheduledTask> scheduledTasks,
  ) {
    _impossibleTasks = [];
    _needsReschedulingTasks = [];
    final tasksCubit = context.read<TaskManagerCubit>();

    for (var task in tasks) {
      if (task.isDone) continue;
      if (!_canTaskBeOverdue(task))
        continue; // Skip tasks that can't be overdue

      final timeLeft = task.deadline - DateTime.now().millisecondsSinceEpoch;
      if (timeLeft <= 0) continue; // Already overdue

      final trueTimeLeft = timeLeft - tasksCubit.getBusyTime(task.deadline);
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

  // Find tasks that are not scheduled yet
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
        middle: Text('Analytics & Statistics'),
      ),
      child: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<TaskManagerCubit, TaskManagerState>(
              listener: (context, state) {
                _loadStatistics();
              },
            ),
          ],
          child: RefreshIndicator(
            onRefresh: () async {
              final analyticsCubit = context.read<AnalyticsCubit>();
              analyticsCubit.loadAnalytics();
              setState(() {
                _loadStatistics();
              });
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildAnalyticsSummary(),
                const SizedBox(height: 16),
                _buildExpandableSection(
                  title: 'Task Statistics',
                  isExpanded: _isTaskStatsExpanded,
                  onToggle:
                      () => setState(
                        () => _isTaskStatsExpanded = !_isTaskStatsExpanded,
                      ),
                  child: Column(
                    children: [
                      _buildTaskStatusSummary(),
                      const SizedBox(height: 16),
                      _buildTaskStatusProgressBars(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildExpandableSection(
                  title: 'Time Tracking',
                  isExpanded: _isTimeTrackingExpanded,
                  onToggle:
                      () => setState(
                        () =>
                            _isTimeTrackingExpanded = !_isTimeTrackingExpanded,
                      ),
                  child: _buildTimeTrackingStats(),
                ),
                const SizedBox(height: 16),
                BlocBuilder<AnalyticsCubit, AnalyticsState>(
                  builder: (context, state) {
                    if (state is AnalyticsLoaded &&
                        state.analyticsData.aiSuggestions.isNotEmpty) {
                      return Column(
                        children: [
                          _buildAiSuggestionsCard(
                            state.analyticsData.aiSuggestions,
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                BlocBuilder<AnalyticsCubit, AnalyticsState>(
                  builder: (context, state) {
                    if (state is AnalyticsLoaded) {
                      return Column(
                        children: [
                          _buildEfficiencyScoreCard(
                            state.analyticsData.efficiencyScore,
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                if (_impossibleTasks.isNotEmpty ||
                    _needsReschedulingTasks.isNotEmpty)
                  _buildExpandableSection(
                    title: 'Tasks Needing Attention',
                    isExpanded: _isActionableTasksExpanded,
                    onToggle:
                        () => setState(
                          () =>
                              _isActionableTasksExpanded =
                                  !_isActionableTasksExpanded,
                        ),
                    child: Column(
                      children: [
                        if (_impossibleTasks.isNotEmpty) ...[
                          _buildImpossibleTasksCard(),
                          const SizedBox(height: 16),
                        ],
                        if (_needsReschedulingTasks.isNotEmpty) ...[
                          _buildReschedulingTasksCard(),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                _buildScheduleActionsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsSummary() {
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
    return AnalyticsCard(
      title: 'Analytics',
      child: Center(
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
              onPressed: () => context.read<AnalyticsCubit>().loadAnalytics(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent(BuildContext context, AnalyticsData data) {
    return AnalyticsCard(
      title: 'Summary',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatItem(
                icon: CupertinoIcons.list_bullet,
                value: _formatter.formatNumber(data.totalTasks),
                label: 'Total Tasks',
              ),
              StatItem(
                icon: CupertinoIcons.check_mark,
                value: _formatter.formatNumber(data.completedTasks),
                label: 'Completed',
                color: CupertinoColors.activeGreen,
              ),
              StatItem(
                icon: CupertinoIcons.exclamationmark_circle,
                value: _formatter.formatNumber(data.overdueTasks),
                label: 'Overdue',
                color: CupertinoColors.systemRed,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ProgressItem(
                value: data.completionRate,
                label: 'Completion Rate',
                color: CupertinoColors.activeGreen,
                formatter: _formatter,
              ),
              ProgressItem(
                value: data.overdueRate,
                label: 'Overdue Rate',
                color: CupertinoColors.systemRed,
                formatter: _formatter,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStatusSummary() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            StatItem(
              icon: CupertinoIcons.calendar,
              value: _totalScheduledTasks.toString(),
              label: 'Scheduled',
            ),
            StatItem(
              icon: CupertinoIcons.clock,
              value: _upcomingTasks.toString(),
              label: 'Upcoming',
              color: CupertinoColors.activeBlue,
            ),
            StatItem(
              icon: CupertinoIcons.square_list,
              value: _unscheduledTasks.toString(),
              label: 'Unscheduled',
              color: CupertinoColors.systemTeal,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
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
    );
  }

  Widget _buildTaskStatusProgressBars() {
    final completionRate =
        _totalScheduledTasks > 0
            ? (_completedTasks / _totalScheduledTasks * 100)
            : 0.0;

    final overdueRate =
        _totalScheduledTasks > 0
            ? (_overdueTasks / _totalScheduledTasks * 100)
            : 0.0;

    return Column(
      children: [
        _ProgressBar(
          label: 'Completion Rate',
          value: completionRate,
          color: CupertinoColors.activeGreen,
        ),
        const SizedBox(height: 10),
        _ProgressBar(
          label: 'Overdue Rate',
          value: overdueRate,
          color: CupertinoColors.systemRed,
        ),
      ],
    );
  }

  Widget _buildTimeTrackingStats() {
    return Column(
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
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _longestTaskTitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
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
    );
  }

  Widget _buildAiSuggestionsCard(List<String> suggestions) {
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

  Widget _buildEfficiencyScoreCard(double score) {
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
            _formatter.getEfficiencyMessage(score),
            style: CupertinoTheme.of(context).textTheme.textStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildImpossibleTasksCard() {
    return Column(
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
    );
  }

  Widget _buildReschedulingTasksCard() {
    return Column(
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
    final tasksCubit = context.read<TaskManagerCubit>();

    final trueTimeLeft = timeLeft - tasksCubit.getBusyTime(task.deadline);

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
          'more time to comlete this task before the deadline. ';
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

  // Schedule unscheduled tasks
  void _scheduleUnscheduledTasks() {
    if (_unscheduledTasksList.isEmpty) return;

    final tasksCubit = context.read<TaskManagerCubit>();

    // Schedule all tasks (including unscheduled ones)
    tasksCubit.scheduleTasks();

    // Refresh the statistics
    setState(() {
      _loadStatistics();
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

  // Build an expandable section with a header that can be toggled
  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return AnalyticsCard(
      title: title,
      child: Column(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onToggle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Show ${isExpanded ? 'Less' : 'More'}',
                  style: TextStyle(
                    color: CupertinoTheme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  isExpanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 16,
                  color: CupertinoTheme.of(context).primaryColor,
                ),
              ],
            ),
          ),
          if (isExpanded) child,
        ],
      ),
    );
  }
}
