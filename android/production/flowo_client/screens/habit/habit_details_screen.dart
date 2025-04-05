import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/utils/category_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'add_habit_page.dart';

class HabitDetailsScreen extends StatefulWidget {
  final Task habit;

  const HabitDetailsScreen({super.key, required this.habit});

  @override
  State<HabitDetailsScreen> createState() => _HabitDetailsScreenState();
}

class _HabitDetailsScreenState extends State<HabitDetailsScreen> {
  late Task _habit;
  final Map<DateTime, bool> _completionData = {};
  int _totalInstances = 0;
  int _completedInstances = 0;
  double _completionRate = 0.0;

  @override
  void initState() {
    super.initState();
    _habit = widget.habit;
    _loadCompletionData();
  }

  void _loadCompletionData() {
    // Process scheduled tasks to get completion data
    final scheduledTasks = _habit.scheduledTasks;
    _totalInstances = scheduledTasks.length;

    // Count completed instances and build completion data map
    for (var task in scheduledTasks) {
      final date = DateTime(
        task.startTime.year,
        task.startTime.month,
        task.startTime.day,
      );

      // For this example, we'll consider the parent task's isDone status
      // In a real implementation, you might want to track completion per instance
      _completionData[date] = _habit.isDone;

      if (_habit.isDone) {
        _completedInstances++;
      }
    }

    // Calculate completion rate
    _completionRate =
        _totalInstances > 0 ? _completedInstances / _totalInstances * 100 : 0.0;

    setState(() {});
  }

  void _toggleHabitCompletion() {
    final tasksCubit = context.read<TaskManagerCubit>();
    tasksCubit.toggleTaskCompletion(_habit).then((isCompleted) {
      setState(() {
        _habit.isDone = isCompleted;
        _loadCompletionData();
      });

      // Show feedback
      _showCompletionFeedback(isCompleted);
    });
  }

  void _showCompletionFeedback(bool isCompleted) {
    final message =
        isCompleted
            ? 'Habit "${_habit.title}" marked as completed'
            : 'Habit "${_habit.title}" marked as incomplete';

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CupertinoAlertDialog(content: Text(message)),
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (Navigator.canPop(context)) Navigator.pop(context);
    });
  }

  void _editHabit() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => AddHabitPage(habit: _habit)),
    ).then((_) {
      setState(() {
        _habit = widget.habit;
        _loadCompletionData();
      });
    });
  }

  void _editHabitInstance(ScheduledTask instance) {
    // TODO: Implement editing of individual habit instances
    // This would be similar to editing a task, but for a specific instance
  }

  String _getFrequencyText() {
    if (_habit.frequency == null) {
      return 'No repeat';
    }

    final frequency = _habit.frequency!;
    final type = frequency.type.toLowerCase();
    final interval = frequency.interval;

    switch (type) {
      case 'daily':
        return interval > 1 ? 'Every $interval days' : 'Daily';
      case 'weekly':
        return interval > 1 ? 'Every $interval weeks' : 'Weekly';
      case 'monthly':
        return interval > 1 ? 'Every $interval months' : 'Monthly';
      case 'yearly':
        return interval > 1 ? 'Every $interval years' : 'Yearly';
      default:
        return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_habit.title, style: theme.textTheme.navTitleTextStyle),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _editHabit,
          child: const Icon(CupertinoIcons.pencil),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Habit Header
            _buildHabitHeader(theme, isDarkMode),
            const SizedBox(height: 24),

            // Completion Statistics
            _buildCompletionStats(theme, isDarkMode),
            const SizedBox(height: 24),

            // GitHub-like Commit Visualization
            _buildCommitVisualization(theme, isDarkMode),
            const SizedBox(height: 24),

            // Habit Instances
            _buildHabitInstances(theme, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitHeader(CupertinoThemeData theme, bool isDarkMode) {
    final categoryColor = CategoryUtils.getCategoryColor(_habit.category.name);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.barBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? CupertinoColors.black.withOpacity(0.2)
                    : CupertinoColors.systemGrey5.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Category Tag
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _habit.category.name,
                  style: TextStyle(
                    color: categoryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              // Completion Toggle
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _toggleHabitCompletion,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _habit.isDone
                          ? CupertinoIcons.check_mark_circled_solid
                          : CupertinoIcons.circle,
                      color:
                          _habit.isDone
                              ? CupertinoColors.activeGreen
                              : CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _habit.isDone ? 'Completed' : 'Mark as completed',
                      style: TextStyle(
                        color:
                            _habit.isDone
                                ? CupertinoColors.activeGreen
                                : CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Habit Details
          if (_habit.notes != null && _habit.notes!.isNotEmpty) ...[
            Text(_habit.notes!, style: theme.textTheme.textStyle),
            const SizedBox(height: 12),
          ],
          // Frequency
          Row(
            children: [
              const Icon(
                CupertinoIcons.repeat,
                size: 16,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 4),
              Text(
                _getFrequencyText(),
                style: theme.textTheme.textStyle.copyWith(
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionStats(CupertinoThemeData theme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.barBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? CupertinoColors.black.withOpacity(0.2)
                    : CupertinoColors.systemGrey5.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completion Statistics',
            style: theme.textTheme.navTitleTextStyle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                theme,
                'Total',
                '$_totalInstances',
                CupertinoColors.systemBlue,
              ),
              _buildStatItem(
                theme,
                'Completed',
                '$_completedInstances',
                CupertinoColors.activeGreen,
              ),
              _buildStatItem(
                theme,
                'Completion Rate',
                '${_completionRate.toStringAsFixed(1)}%',
                CupertinoColors.systemOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    CupertinoThemeData theme,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.navTitleTextStyle.copyWith(
            fontSize: 24,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.textStyle.copyWith(
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildCommitVisualization(CupertinoThemeData theme, bool isDarkMode) {
    // Get dates for the last 4 weeks
    final today = DateTime.now();
    final fourWeeksAgo = today.subtract(const Duration(days: 28));

    // Generate all dates between fourWeeksAgo and today
    final allDates = List.generate(
      29,
      (index) => fourWeeksAgo.add(Duration(days: index)),
    );

    // Group dates by week
    final weeks = <List<DateTime>>[];
    for (var i = 0; i < allDates.length; i += 7) {
      final end = i + 7 < allDates.length ? i + 7 : allDates.length;
      weeks.add(allDates.sublist(i, end));
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.barBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? CupertinoColors.black.withOpacity(0.2)
                    : CupertinoColors.systemGrey5.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completion History',
            style: theme.textTheme.navTitleTextStyle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          // Days of week labels
          Row(
            children: [
              const SizedBox(width: 24), // Space for week labels
              ...['M', 'T', 'W', 'T', 'F', 'S', 'S']
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: theme.textTheme.textStyle.copyWith(
                            color: CupertinoColors.systemGrey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),
          const SizedBox(height: 8),

          // Commit grid
          Column(
            children:
                weeks.map((week) {
                  final weekLabel = '${week.first.month}/${week.first.day}';
                  return Row(
                    children: [
                      // Week label
                      SizedBox(
                        width: 24,
                        child: Text(
                          weekLabel,
                          style: theme.textTheme.textStyle.copyWith(
                            color: CupertinoColors.systemGrey,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      // Days of the week
                      ...week.map((date) {
                        final isCompleted = _completionData[date] ?? false;
                        final color =
                            isCompleted
                                ? CupertinoColors.activeGreen
                                : CupertinoColors.systemGrey.withOpacity(0.2);
                        final intensity = isCompleted ? 1.0 : 0.2;

                        return Expanded(
                          child: Center(
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: color.withOpacity(intensity),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      // Fill empty days for incomplete weeks
                      ...List.generate(
                        7 - week.length,
                        (_) => Expanded(child: Container()),
                      ),
                    ],
                  );
                }).toList(),
          ),

          // Legend
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Not Completed',
                style: theme.textTheme.textStyle.copyWith(
                  color: CupertinoColors.systemGrey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: CupertinoColors.activeGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Completed',
                style: theme.textTheme.textStyle.copyWith(
                  color: CupertinoColors.systemGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHabitInstances(CupertinoThemeData theme, bool isDarkMode) {
    final scheduledTasks = _habit.scheduledTasks;

    if (scheduledTasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.barBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color:
                  isDarkMode
                      ? CupertinoColors.black.withOpacity(0.2)
                      : CupertinoColors.systemGrey5.withOpacity(0.5),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Center(
          child: Text('No scheduled instances for this habit'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.barBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? CupertinoColors.black.withOpacity(0.2)
                    : CupertinoColors.systemGrey5.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scheduled Instances',
            style: theme.textTheme.navTitleTextStyle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ...scheduledTasks.map((task) {
            final date = task.startTime;
            final formattedDate =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            final formattedTime =
                '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  // Date and time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: theme.textTheme.textStyle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formattedTime,
                          style: theme.textTheme.textStyle.copyWith(
                            color: CupertinoColors.systemGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Edit button
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.pencil, size: 20),
                    onPressed: () => _editHabitInstance(task),
                  ),
                  // Completion status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _habit.isDone
                              ? CupertinoColors.activeGreen.withOpacity(0.2)
                              : CupertinoColors.systemGrey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _habit.isDone ? 'Completed' : 'Pending',
                      style: TextStyle(
                        color:
                            _habit.isDone
                                ? CupertinoColors.activeGreen
                                : CupertinoColors.systemGrey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
