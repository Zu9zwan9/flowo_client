import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../blocs/tasks_controller/tasks_controller_cubit.dart';
import '../models/scheduled_task.dart';
import '../models/task.dart';
import '../models/user_profile.dart';
import '../utils/date_time_formatter.dart';
import 'calendar_screen.dart';

class DailyOverviewScreen extends StatefulWidget {
  const DailyOverviewScreen({super.key});

  @override
  State<DailyOverviewScreen> createState() => _DailyOverviewScreenState();
}

class _DailyOverviewScreenState extends State<DailyOverviewScreen> {
  late DateTime _today;
  String _greeting = '';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _updateGreeting();
    _loadUserProfile();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good morning';
    } else if (hour < 17) {
      _greeting = 'Good afternoon';
    } else {
      _greeting = 'Good evening';
    }
  }

  void _loadUserProfile() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProfileBox = Provider.of<Box<UserProfile>>(
        context,
        listen: false,
      );
      final userProfile = userProfileBox.get('current');
      if (userProfile != null && mounted) {
        setState(() {
          _userName = userProfile.name;
        });
      }
    });
  }

  void _navigateToCalendar() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const CalendarScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(
              child: _buildTimeSection(
                'Morning',
                TimeOfDay(hour: 5, minute: 0),
                TimeOfDay(hour: 12, minute: 0),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildTimeSection(
                'Afternoon',
                TimeOfDay(hour: 12, minute: 0),
                TimeOfDay(hour: 17, minute: 0),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildTimeSection(
                'Evening',
                TimeOfDay(hour: 17, minute: 0),
                TimeOfDay(hour: 23, minute: 59),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final formattedDate = DateFormat('EEEE, MMMM d').format(_today);
    final textTheme = CupertinoTheme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_greeting, $_userName',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: CupertinoTheme.of(context).textTheme.textStyle.color,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _navigateToCalendar,
                child: Icon(
                  CupertinoIcons.calendar,
                  color: CupertinoTheme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formattedDate,
            style: TextStyle(
              fontSize: 18,
              color:
                  CupertinoTheme.of(context).textTheme.tabLabelTextStyle.color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'For today, we have the following tasks:',
            style: TextStyle(
              fontSize: 16,
              color:
                  CupertinoTheme.of(context).textTheme.tabLabelTextStyle.color,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTimeSection(
    String title,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) {
    return FutureBuilder<List<ScheduledTask>>(
      future: context.read<CalendarCubit>().getScheduledTasksForSelectedDate(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSectionSkeleton(title);
        }

        if (snapshot.hasError) {
          return _buildErrorSection(title, snapshot.error.toString());
        }

        final allTasks = snapshot.data ?? [];
        final filteredTasks = _filterTasksByTimeRange(
          allTasks,
          startTime,
          endTime,
        );

        return _buildTaskSection(title, filteredTasks);
      },
    );
  }

  List<ScheduledTask> _filterTasksByTimeRange(
    List<ScheduledTask> tasks,
    TimeOfDay startTime,
    TimeOfDay endTime, {
    bool filterByTaskStart = true,
  }) {
    final startTimeMinutes = startTime.hour * 60 + startTime.minute;
    final endTimeMinutes = endTime.hour * 60 + endTime.minute;
    List<ScheduledTask> filteredTasks;

    if (filterByTaskStart) {
      // Only include tasks that start within the given time range.
      filteredTasks =
          tasks.where((task) {
            final taskStartMinutes =
                task.startTime.hour * 60 + task.startTime.minute;
            return taskStartMinutes >= startTimeMinutes &&
                taskStartMinutes < endTimeMinutes;
          }).toList();
    } else {
      // Include tasks based on overlapping time intervals.
      filteredTasks =
          tasks.where((task) {
            final taskStartMinutes =
                task.startTime.hour * 60 + task.startTime.minute;
            final taskEndMinutes = task.endTime.hour * 60 + task.endTime.minute;
            return (taskStartMinutes >= startTimeMinutes &&
                    taskStartMinutes < endTimeMinutes) ||
                (taskStartMinutes < startTimeMinutes &&
                    taskEndMinutes > startTimeMinutes);
          }).toList();
    }

    // Sort tasks by start time.
    filteredTasks.sort((a, b) {
      final aStart = a.startTime.hour * 60 + a.startTime.minute;
      final bStart = b.startTime.hour * 60 + b.startTime.minute;
      return aStart.compareTo(bStart);
    });

    return filteredTasks;
  }

  Widget _buildSectionSkeleton(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title),
          const SizedBox(height: 10),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: CupertinoActivityIndicator(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection(String title, String error) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title),
          const SizedBox(height: 10),
          Text(
            'Error loading tasks: $error',
            style: TextStyle(
              color: CupertinoColors.destructiveRed,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskSection(String title, List<ScheduledTask> tasks) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title),
          const SizedBox(height: 10),
          if (tasks.isEmpty)
            Text(
              'No tasks scheduled for $title',
              style: TextStyle(
                color:
                    CupertinoTheme.of(
                      context,
                    ).textTheme.tabLabelTextStyle.color,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...tasks.map((task) => _buildTaskItem(task)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: CupertinoTheme.of(context).textTheme.textStyle.color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: CupertinoTheme.of(
              context,
            ).barBackgroundColor.withOpacity(0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(ScheduledTask scheduledTask) {
    final calendarCubit = context.read<CalendarCubit>();
    final task = calendarCubit.tasksDB.get(scheduledTask.parentTaskId);
    if (task == null) return const SizedBox.shrink();

    final startTime = DateTimeFormatter.formatTime(scheduledTask.startTime);
    final endTime = DateTimeFormatter.formatTime(scheduledTask.endTime);
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _showTaskDetails(task, scheduledTask),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoTheme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color:
                    isDarkMode
                        ? CupertinoColors.black.withOpacity(0.3)
                        : CupertinoColors.systemGrey5.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color:
                  isDarkMode
                      ? CupertinoColors.systemGrey4.withOpacity(0.2)
                      : CupertinoColors.systemGrey5,
              width: 0.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: _getCategoryColor(task.category.name),
                  borderRadius: BorderRadius.circular(2),
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
                        color:
                            CupertinoTheme.of(
                              context,
                            ).textTheme.textStyle.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$startTime - $endTime',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            CupertinoTheme.of(
                              context,
                            ).textTheme.tabLabelTextStyle.color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                task.isDone
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                color:
                    task.isDone
                        ? CupertinoColors.activeGreen
                        : CupertinoTheme.of(
                          context,
                        ).textTheme.tabLabelTextStyle.color,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    switch (category.toLowerCase()) {
      case 'work':
        return isDark
            ? CupertinoColors.systemBlue.darkColor
            : CupertinoColors.systemBlue;
      case 'personal':
        return isDark
            ? CupertinoColors.systemGreen.darkColor
            : CupertinoColors.systemGreen;
      case 'health':
        return isDark
            ? CupertinoColors.systemRed.darkColor
            : CupertinoColors.systemRed;
      case 'education':
        return isDark
            ? CupertinoColors.systemOrange.darkColor
            : CupertinoColors.systemOrange;
      case 'social':
        return isDark
            ? CupertinoColors.systemPurple.darkColor
            : CupertinoColors.systemPurple;
      default:
        return isDark
            ? CupertinoColors.systemIndigo.darkColor
            : CupertinoColors.systemIndigo;
    }
  }

  void _showTaskDetails(Task task, ScheduledTask scheduledTask) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: Text(task.title),
            message: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Text(
                  '${DateTimeFormatter.formatTime(scheduledTask.startTime)} - ${DateTimeFormatter.formatTime(scheduledTask.endTime)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
                if (task.notes != null && task.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.notes!,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          CupertinoTheme.of(context).textTheme.textStyle.color,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(task.category.name),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Category: ${task.category.name}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color:
                            CupertinoTheme.of(
                              context,
                            ).textTheme.textStyle.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  task.isDone = !task.isDone;
                  context.read<CalendarCubit>().updateTask(task);
                },
                child: Text(
                  task.isDone ? 'Mark as Undone' : 'Mark as Done',
                  style: TextStyle(
                    color: CupertinoTheme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
    );
  }
}
