import 'dart:ui';

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
import 'package:flutter/material.dart';
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
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor:
            isDarkMode
                ? CupertinoColors.systemBackground.darkColor.withOpacity(0.8)
                : CupertinoColors.systemBackground.withOpacity(0.8),
        border: const Border(
          bottom: BorderSide(color: CupertinoColors.separator, width: 0.0),
        ),
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.chart_bar_alt_fill,
              color: CupertinoColors.systemIndigo.resolveFrom(context),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Analytics Dashboard',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
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
        const SizedBox(height: 20),
        _buildTaskStatusCard(analyticsData),
        const SizedBox(height: 20),
        _buildTimeTrackingCard(),
        const SizedBox(height: 20),
        EfficiencyScoreCard(
          score: analyticsData.efficiencyScore,
          formatter: formatter,
        ),
        const SizedBox(height: 20),
        if (analyticsData.aiSuggestions.isNotEmpty) ...[
          AiSuggestionsCard(suggestions: analyticsData.aiSuggestions),
          const SizedBox(height: 20),
        ],
        if (_impossibleTasks.isNotEmpty) ...[
          _buildImpossibleTasksCard(),
          const SizedBox(height: 20),
        ],
        if (_needsReschedulingTasks.isNotEmpty) ...[
          _buildReschedulingTasksCard(),
          const SizedBox(height: 20),
        ],
        _buildScheduleActionsCard(),
        // Add some padding at the bottom for better scrolling experience
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSummaryCard(AnalyticsData analyticsData) {
    return AnalyticsCard(
      title: 'Task Summary',
      icon: CupertinoIcons.chart_pie_fill,
      accentColor: CupertinoColors.systemIndigo.resolveFrom(context),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StatItem(
                  icon: CupertinoIcons.list_bullet,
                  value: _totalScheduledTasks.toString(),
                  label: 'Scheduled',
                ),
                StatItem(
                  icon: CupertinoIcons.check_mark_circled_solid,
                  value: _completedTasks.toString(),
                  label: 'Completed',
                  color: CupertinoColors.activeGreen,
                ),
                StatItem(
                  icon: CupertinoIcons.exclamationmark_circle_fill,
                  value: _overdueTasks.toString(),
                  label: 'Overdue',
                  color: CupertinoColors.systemRed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StatItem(
                  icon: CupertinoIcons.clock_fill,
                  value: _upcomingTasks.toString(),
                  label: 'Upcoming',
                  color: CupertinoColors.activeBlue,
                ),
                StatItem(
                  icon: CupertinoIcons.exclamationmark_triangle_fill,
                  value: _impossibleTasks.length.toString(),
                  label: 'Impossible',
                  color: CupertinoColors.systemRed,
                ),
                StatItem(
                  icon: CupertinoIcons.arrow_2_circlepath_circle_fill,
                  value: _needsReschedulingTasks.length.toString(),
                  label: 'Need Reschedule',
                  color: CupertinoColors.systemOrange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStatusCard(AnalyticsData analyticsData) {
    return AnalyticsCard(
      title: 'Task Performance',
      icon: CupertinoIcons.graph_circle_fill,
      accentColor: CupertinoColors.systemTeal.resolveFrom(context),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
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
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTrackingCard() {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final accentColor = CupertinoColors.systemPurple.resolveFrom(context);

    return AnalyticsCard(
      title: 'Time Analytics',
      icon: CupertinoIcons.timer_fill,
      accentColor: accentColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                StatItem(
                  icon: CupertinoIcons.time_solid,
                  value:
                      Duration(milliseconds: _totalDuration).inHours > 0
                          ? '${Duration(milliseconds: _totalDuration).inHours}h ${Duration(milliseconds: _totalDuration).inMinutes.remainder(60)}m'
                          : '${Duration(milliseconds: _totalDuration).inMinutes}m',
                  label: 'Total Time',
                  color: CupertinoColors.activeBlue,
                ),
                StatItem(
                  icon: CupertinoIcons.timer_fill,
                  value:
                      Duration(milliseconds: _averageDuration).inHours > 0
                          ? '${Duration(milliseconds: _averageDuration).inHours}h ${Duration(milliseconds: _averageDuration).inMinutes.remainder(60)}m'
                          : '${Duration(milliseconds: _averageDuration).inMinutes}m',
                  label: 'Average Time',
                  color: CupertinoColors.systemPurple,
                ),
                StatItem(
                  icon: CupertinoIcons.number_circle_fill,
                  value: _tasksWithDuration.toString(),
                  label: 'Tasks Tracked',
                  color: CupertinoColors.systemTeal,
                ),
              ],
            ),
          ),
          if (_longestTaskDuration > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.clock_fill,
                        color: accentColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Longest Task',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              CupertinoTheme.of(
                                context,
                              ).textTheme.textStyle.color,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _longestTaskTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color:
                          CupertinoTheme.of(context).textTheme.textStyle.color,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Duration: ${Duration(milliseconds: _longestTaskDuration).inHours > 0 ? '${Duration(milliseconds: _longestTaskDuration).inHours}h ${Duration(milliseconds: _longestTaskDuration).inMinutes.remainder(60)}m' : '${Duration(milliseconds: _longestTaskDuration).inMinutes}m'}',
                      style: TextStyle(
                        fontSize: 15,
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
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
    final accentColor = CupertinoColors.systemRed.resolveFrom(context);

    return AnalyticsCard(
      title: 'Impossible Tasks',
      icon: CupertinoIcons.exclamationmark_octagon_fill,
      accentColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.info_circle_fill,
                  color: accentColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'These tasks cannot be completed before their deadlines due to time constraints:',
                    style: TextStyle(
                      color:
                          CupertinoTheme.of(context).textTheme.textStyle.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._impossibleTasks.map((task) => _buildTaskListItem(task, true)),
        ],
      ),
    );
  }

  Widget _buildTaskListItem(Task task, bool isImpossible) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;
    final secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    // Choose color based on task type
    final accentColor =
        isImpossible
            ? CupertinoColors.systemRed.resolveFrom(context)
            : CupertinoColors.systemOrange.resolveFrom(context);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _showTaskOptions(task, isImpossible),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isImpossible
                    ? CupertinoIcons.exclamationmark_circle_fill
                    : CupertinoIcons.arrow_2_circlepath_circle_fill,
                color: accentColor,
                size: 16,
              ),
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
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.clock_fill,
                              color: accentColor,
                              size: 10,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _formatDate(task.deadline),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBlue
                              .resolveFrom(context)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.timer_fill,
                              color: CupertinoColors.systemBlue.resolveFrom(
                                context,
                              ),
                              size: 10,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _formatDuration(task.estimatedTime),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors.systemBlue.resolveFrom(
                                  context,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right_circle_fill,
              color: accentColor.withOpacity(0.7),
              size: 20,
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

  Widget _buildReschedulingTasksCard() {
    final accentColor = CupertinoColors.systemOrange.resolveFrom(context);

    return AnalyticsCard(
      title: 'Needs Rescheduling',
      icon: CupertinoIcons.arrow_2_circlepath_circle_fill,
      accentColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.info_circle_fill,
                  color: accentColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'These tasks need to be rescheduled to ensure they can be completed on time:',
                    style: TextStyle(
                      color:
                          CupertinoTheme.of(context).textTheme.textStyle.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._needsReschedulingTasks.map(
            (task) => _buildTaskListItem(task, false),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleActionsCard() {
    final accentColor = CupertinoColors.activeBlue.resolveFrom(context);
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    return AnalyticsCard(
      title: 'Quick Actions',
      icon: CupertinoIcons.wand_stars_inverse,
      accentColor: accentColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.info_circle_fill,
                  color: accentColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Optimize your schedule with these quick actions:',
                    style: TextStyle(
                      color:
                          CupertinoTheme.of(context).textTheme.textStyle.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withOpacity(0.8),
                  CupertinoColors.systemIndigo
                      .resolveFrom(context)
                      .withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 16),
              onPressed: () {
                HapticFeedback.mediumImpact();
                _taskManagerCubit.scheduleTasks();
                _taskManagerCubit.scheduleHabits();
                setState(() {
                  _loadTaskStatistics();
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.arrow_2_circlepath_circle_fill,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Reschedule All Tasks',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_unscheduledTasks > 0) ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CupertinoColors.systemGreen
                        .resolveFrom(context)
                        .withOpacity(0.8),
                    CupertinoColors.systemTeal
                        .resolveFrom(context)
                        .withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGreen
                        .resolveFrom(context)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _scheduleUnscheduledTasks();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.calendar_badge_plus,
                      color: CupertinoColors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Schedule Unscheduled Tasks ($_unscheduledTasks)',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
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

    final accentColor =
        isImpossible
            ? CupertinoColors.systemRed.resolveFrom(context)
            : CupertinoColors.systemOrange.resolveFrom(context);

    String message;
    IconData messageIcon;
    if (isImpossible) {
      message =
          'This task is impossible to complete before the deadline. '
          'You need ${timeNeeded.inHours}h ${timeNeeded.inMinutes.remainder(60)}m '
          'more time than available before the deadline.';
      messageIcon = CupertinoIcons.exclamationmark_octagon_fill;
    } else {
      message =
          'This task is possible to complete if you reschedule some other tasks. '
          'You need ${timeNeeded.inHours}h ${timeNeeded.inMinutes.remainder(60)}m '
          'more time to complete this task before the deadline.';
      messageIcon = CupertinoIcons.arrow_2_circlepath_circle_fill;
    }

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(messageIcon, color: accentColor, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            CupertinoTheme.of(
                              context,
                            ).textTheme.textStyle.color,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            message: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accentColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  height: 1.3,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _editTask(task);
                },
                isDefaultAction: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.pencil_circle_fill,
                      color: CupertinoColors.activeBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Edit Task',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.arrow_2_circlepath_circle_fill,
                        color: CupertinoColors.systemOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Reschedule Other Tasks',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: CupertinoColors.systemGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
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

    // Show confirmation with modern styling
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  color: CupertinoColors.activeGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tasks Scheduled',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${_unscheduledTasksList.length} unscheduled tasks have been successfully added to your schedule.',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                isDefaultAction: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: CupertinoColors.activeBlue,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}

/// Card widget with iOS styling and glassmorphic effect
class AnalyticsCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;
  final Color? accentColor;

  const AnalyticsCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    final resolvedAccentColor = accentColor ?? primaryColor;

    // Glassmorphic effect colors
    final backgroundColor =
        isDarkMode
            ? CupertinoColors.systemBackground.darkColor.withOpacity(0.7)
            : CupertinoColors.systemBackground.withOpacity(0.7);
    final borderColor =
        isDarkMode
            ? CupertinoColors.white.withOpacity(0.1)
            : CupertinoColors.white.withOpacity(0.3);
    final shadowColor =
        isDarkMode
            ? CupertinoColors.black.withOpacity(0.2)
            : CupertinoColors.systemGrey.withOpacity(0.15);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDarkMode
                ? CupertinoColors.systemBackground.darkColor.withOpacity(0.8)
                : CupertinoColors.white.withOpacity(0.8),
            isDarkMode
                ? CupertinoColors.darkBackgroundGray.withOpacity(0.7)
                : CupertinoColors.systemBackground.withOpacity(0.7),
          ],
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: resolvedAccentColor, size: 22),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      title,
                      style: CupertinoTheme.of(
                        context,
                      ).textTheme.navTitleTextStyle.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget for displaying a statistic with an icon in a modern, high-tech style
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
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final resolvedColor =
        color != null
            ? CupertinoDynamicColor.resolve(color!, context)
            : CupertinoTheme.of(context).primaryColor;

    // Glassmorphic effect colors
    final containerColor =
        isDarkMode
            ? resolvedColor.withOpacity(0.15)
            : resolvedColor.withOpacity(0.1);
    final borderColor =
        isDarkMode
            ? resolvedColor.withOpacity(0.3)
            : resolvedColor.withOpacity(0.2);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: resolvedColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: resolvedColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CupertinoTheme.of(context).textTheme.textStyle.color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color:
                  CupertinoTheme.of(context).textTheme.tabLabelTextStyle.color,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying a circular progress indicator with modern styling
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
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final resolvedColor = CupertinoDynamicColor.resolve(color, context);
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;

    // Ensure value is finite and between 0-100
    final safeValue = value.isFinite ? value.clamp(0.0, 100.0) : 0.0;

    // Glassmorphic effect colors
    final containerColor =
        isDarkMode
            ? resolvedColor.withOpacity(0.15)
            : resolvedColor.withOpacity(0.1);
    final borderColor =
        isDarkMode
            ? resolvedColor.withOpacity(0.3)
            : resolvedColor.withOpacity(0.2);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: safeValue / 100,
                  backgroundColor:
                      isDarkMode
                          ? CupertinoColors.darkBackgroundGray.withOpacity(0.3)
                          : CupertinoColors.systemGrey5.resolveFrom(context),
                  valueColor: AlwaysStoppedAnimation<Color>(resolvedColor),
                  strokeWidth: 10,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatter.formatPercent(safeValue),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Complete',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Card for displaying AI suggestions with modern styling
class AiSuggestionsCard extends StatelessWidget {
  final List<String> suggestions;

  const AiSuggestionsCard({super.key, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    final accentColor = CupertinoColors.systemYellow.resolveFrom(context);

    return AnalyticsCard(
      title: 'AI Insights',
      icon: CupertinoIcons.lightbulb_fill,
      accentColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              "Here are some personalized suggestions based on your task patterns:",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ),
          ...suggestions.map((suggestion) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.lightbulb_fill,
                      color: accentColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        letterSpacing: -0.2,
                        color:
                            CupertinoTheme.of(
                              context,
                            ).textTheme.textStyle.color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

/// Card for displaying efficiency score with modern styling
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
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;

    // Determine color based on score
    Color scoreColor;
    if (score >= 80) {
      scoreColor = CupertinoColors.systemGreen.resolveFrom(context);
    } else if (score >= 60) {
      scoreColor = CupertinoColors.systemBlue.resolveFrom(context);
    } else if (score >= 40) {
      scoreColor = CupertinoColors.systemOrange.resolveFrom(context);
    } else {
      scoreColor = CupertinoColors.systemRed.resolveFrom(context);
    }

    return AnalyticsCard(
      title: 'Efficiency Score',
      icon: CupertinoIcons.chart_bar_fill,
      accentColor: scoreColor,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: scoreColor.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: scoreColor.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      score.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                        letterSpacing: -1.0,
                      ),
                    ),
                    Text(
                      '/100',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color:
                            isDarkMode
                                ? CupertinoColors.systemGrey.resolveFrom(
                                  context,
                                )
                                : CupertinoColors.systemGrey2.resolveFrom(
                                  context,
                                ),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scoreColor.withOpacity(0.2), width: 1),
            ),
            child: Text(
              formatter.getEfficiencyMessage(score),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
                height: 1.3,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// This class is no longer needed as we've moved its functionality to _buildTaskListItem method
