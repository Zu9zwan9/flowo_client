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

  // Navigate to calendar screen
  void _navigateToCalendar() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const CalendarScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Today'),
        backgroundColor: CupertinoColors.systemBackground,
        border: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _navigateToCalendar,
          child: const Icon(
            CupertinoIcons.calendar,
            color: CupertinoColors.activeBlue,
          ),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header with greeting
            SliverToBoxAdapter(child: _buildHeader()),

            // Morning tasks
            SliverToBoxAdapter(
              child: _buildTimeSection(
                'Morning',
                TimeOfDay(hour: 5, minute: 0),
                TimeOfDay(hour: 12, minute: 0),
              ),
            ),

            // Afternoon tasks
            SliverToBoxAdapter(
              child: _buildTimeSection(
                'Afternoon',
                TimeOfDay(hour: 12, minute: 0),
                TimeOfDay(hour: 17, minute: 0),
              ),
            ),

            // Evening tasks
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

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_greeting, $_userName',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formattedDate,
            style: const TextStyle(
              fontSize: 18,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'For today, we have the following tasks:',
            style: const TextStyle(
              fontSize: 16,
              color: CupertinoColors.secondaryLabel,
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
    TimeOfDay endTime,
  ) {
    return tasks.where((task) {
      final taskStartHour = task.startTime.hour;
      final taskStartMinute = task.startTime.minute;

      final startTimeMinutes = startTime.hour * 60 + startTime.minute;
      final endTimeMinutes = endTime.hour * 60 + endTime.minute;
      final taskTimeMinutes = taskStartHour * 60 + taskStartMinute;

      return taskTimeMinutes >= startTimeMinutes &&
          taskTimeMinutes < endTimeMinutes;
    }).toList();
  }

  Widget _buildSectionSkeleton(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title),
          const SizedBox(height: 10),
          const CupertinoActivityIndicator(),
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
            style: const TextStyle(
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
              style: const TextStyle(
                color: CupertinoColors.secondaryLabel,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...tasks.map((task) => _buildTaskItem(task)).toList(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: CupertinoColors.separator)),
      ],
    );
  }

  Widget _buildTaskItem(ScheduledTask scheduledTask) {
    final calendarCubit = context.read<CalendarCubit>();
    final task = calendarCubit.tasksDB.get(scheduledTask.parentTaskId);
    if (task == null) return const SizedBox.shrink();

    final startTime = DateTimeFormatter.formatTime(scheduledTask.startTime);
    final endTime = DateTimeFormatter.formatTime(scheduledTask.endTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _showTaskDetails(task, scheduledTask),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemGrey5.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$startTime - $endTime',
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel,
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
                        : CupertinoColors.systemGrey3,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return CupertinoColors.systemBlue;
      case 'personal':
        return CupertinoColors.systemGreen;
      case 'health':
        return CupertinoColors.systemRed;
      case 'education':
        return CupertinoColors.systemOrange;
      case 'social':
        return CupertinoColors.systemPurple;
      default:
        return CupertinoColors.systemIndigo;
    }
  }

  void _showTaskDetails(Task task, ScheduledTask scheduledTask) {
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (task.notes != null && task.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(task.notes!, style: const TextStyle(fontSize: 14)),
                ],
                const SizedBox(height: 8),
                Text(
                  'Category: ${task.category.name}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  // Mark task as done
                  task.isDone = !task.isDone;
                  context.read<CalendarCubit>().updateTask(task);
                },
                child: Text(task.isDone ? 'Mark as Undone' : 'Mark as Done'),
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
