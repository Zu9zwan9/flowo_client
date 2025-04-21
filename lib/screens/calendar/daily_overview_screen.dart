import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart'; // Import for SfCalendar

import '../../blocs/tasks_controller/task_manager_cubit.dart';
import '../../blocs/tasks_controller/tasks_controller_cubit.dart';
import '../../models/scheduled_task.dart';
import '../../models/scheduled_task_type.dart';
import '../../models/task.dart';
import '../../models/user_profile.dart';
import '../../models/user_settings.dart';
import '../../utils/formatter/date_time_formatter.dart';
import '../widgets/calendar_widgets.dart';
import '../widgets/task_timer_controls.dart';

class DailyOverviewScreen extends StatefulWidget {
  const DailyOverviewScreen({super.key});

  @override
  State<DailyOverviewScreen> createState() => _DailyOverviewScreenState();
}

class _DailyOverviewScreenState extends State<DailyOverviewScreen> with TickerProviderStateMixin {
  late DateTime _selectedDate;
  late UserSettings _userSettings;
  String _greeting = '';
  String _userName = '';
  bool _isCalendarVisible = false; // Tracks calendar visibility
  late AnimationController _calendarAnimationController; // Controller for slide animation
  late Animation<Offset> _slideAnimation; // Slide animation for calendar
  late CalendarController _calendarController; // Controller for SfCalendar
  final double _calendarHeight = 350.0; // Fixed height for the calendar

  @override
  void initState() {
    super.initState();
    _userSettings = context.read<TaskManagerCubit>().taskManager.userSettings;
    _selectedDate = DateTime.now();

    // Initialize animation controller and slide animation
    _calendarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.1), // Slightly further off-screen to avoid partial visibility
      end: const Offset(0, 0),      // End at normal position
    ).animate(CurvedAnimation(
      parent: _calendarAnimationController,
      curve: Curves.easeInOut,
    ));

    // Initialize calendar controller
    _calendarController = CalendarController();

    // Set initial date in CalendarCubit after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CalendarCubit>().selectDate(_selectedDate);
      }
    });
    _updateGreeting();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _calendarAnimationController.dispose(); // Dispose animation controller
    _calendarController.dispose();          // Dispose calendar controller
    super.dispose();
  }

  void _updateGreeting() {
    // Set greeting based on time of day
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
    // Load user profile data after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProfileBox = Provider.of<Box<UserProfile>>(context, listen: false);
      final userProfile = userProfileBox.get('current');
      if (userProfile != null && mounted) {
        setState(() {
          _userName = userProfile.name;
        });
      }
    });
  }

  void _navigateToPreviousDay() {
    // Move to previous day and update CalendarCubit
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    context.read<CalendarCubit>().selectDate(_selectedDate);
    _calendarController.selectedDate = _selectedDate; // Sync calendar
    _calendarController.displayDate = _selectedDate;
  }

  void _navigateToNextDay() {
    // Move to next day and update CalendarCubit
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    context.read<CalendarCubit>().selectDate(_selectedDate);
    _calendarController.selectedDate = _selectedDate; // Sync calendar
    _calendarController.displayDate = _selectedDate;
  }

  bool _isToday(DateTime date) {
    // Check if the given date is today
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _toggleCalendarVisibility() {
    // Toggle calendar visibility with animation
    setState(() {
      if (_isCalendarVisible) {
        _calendarAnimationController.reverse();
        _isCalendarVisible = false;
      } else {
        _calendarAnimationController.forward();
        _isCalendarVisible = true;
      }
    });
  }

  void _handleSwipe(DragUpdateDetails details) {
    // Handle vertical swipe gestures
    final delta = details.primaryDelta ?? 0;
    if (delta > 5 && !_isCalendarVisible) {
      // Swipe down to show calendar
      _toggleCalendarVisibility();
    } else if (delta < -5 && _isCalendarVisible) {
      // Swipe up to hide calendar
      _toggleCalendarVisibility();
    }
  }

  Widget _buildHandle() {
    // Build the swipe handle icon
    return Container(
      height: 32,
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          _isCalendarVisible ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
          key: ValueKey(_isCalendarVisible),
          color: CupertinoTheme.of(context).textTheme.textStyle.color?.withOpacity(0.6),
          size: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      child: SafeArea(
        child: GestureDetector(
          onVerticalDragUpdate: _handleSwipe, // Detect swipe gestures
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Calendar or handle sliver
              _isCalendarVisible
                  ? SliverToBoxAdapter(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    height: _calendarHeight,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: textTheme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: SfCalendar(
                            view: CalendarView.month, // Month view only
                            controller: _calendarController,
                            dataSource: CalendarTaskDataSource(
                              context.read<TaskManagerCubit>().getScheduledTasks(),
                            ),
                            initialSelectedDate: _selectedDate, // Set initial date
                            initialDisplayDate: _selectedDate, // Set initial display
                            onSelectionChanged: (details) {
                              // Defer state update to avoid setState during build
                              if (details.date != null) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    setState(() {
                                      _selectedDate = details.date!;
                                    });
                                    context.read<CalendarCubit>().selectDate(_selectedDate);
                                  }
                                });
                              }
                            },
                            showNavigationArrow: true, // Show navigation arrows
                            allowViewNavigation: false, // Disable view switching
                            headerStyle: CalendarHeaderStyle(
                              textStyle: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: textTheme.textTheme.textStyle.color,
                              ),
                            ),
                            monthViewSettings: MonthViewSettings(
                              appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
                              showAgenda: false, // Disable agenda
                              monthCellStyle: MonthCellStyle(
                                textStyle: TextStyle(
                                  color: textTheme.textTheme.textStyle.color,
                                  fontSize: 14,
                                ),
                                todayTextStyle: TextStyle(
                                  color: CupertinoColors.activeBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                backgroundColor: CupertinoColors.transparent,
                                todayBackgroundColor: CupertinoColors.activeBlue.withOpacity(0.1),
                              ),
                            ),
                            todayHighlightColor: CupertinoColors.activeBlue,
                            selectionDecoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              color: CupertinoColors.activeBlue.withOpacity(0.2),
                              border: Border.all(
                                color: CupertinoColors.activeBlue,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        _buildHandle(), // Handle at the bottom of the calendar
                      ],
                    ),
                  ),
                ),
              )
                  : SliverToBoxAdapter(child: _buildHandle()),
              // Add padding to prevent gaps
              SliverPadding(padding: const EdgeInsets.only(bottom: 8)),
              // Header and task sections
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(
                child: _buildTimeSection(
                  'Night',
                  const TimeOfDay(hour: 0, minute: 0),
                  const TimeOfDay(hour: 5, minute: 0),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildTimeSection(
                  'Morning',
                  const TimeOfDay(hour: 5, minute: 0),
                  const TimeOfDay(hour: 12, minute: 0),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildTimeSection(
                  'Afternoon',
                  const TimeOfDay(hour: 12, minute: 0),
                  const TimeOfDay(hour: 17, minute: 0),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildTimeSection(
                  'Evening',
                  const TimeOfDay(hour: 17, minute: 0),
                  const TimeOfDay(hour: 23, minute: 59),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Build header with greeting and date navigation
    final formattedDate = DateFormat('EEEE, MMMM d').format(_selectedDate);
    final textTheme = CupertinoTheme.of(context);
    final isToday = _isToday(_selectedDate);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_greeting, $_userName',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textTheme.textTheme.textStyle.color,
            ),
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _navigateToPreviousDay,
                child: Icon(
                  CupertinoIcons.chevron_left,
                  color: textTheme.primaryColor,
                ),
              ),
              Expanded(
                child: Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 18,
                    color: textTheme.textTheme.tabLabelTextStyle.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _navigateToNextDay,
                child: Icon(
                  CupertinoIcons.chevron_right,
                  color: textTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isToday
                ? 'For today, we have the following tasks:'
                : 'For this day, we have the following tasks:',
            style: TextStyle(
              fontSize: 16,
              color: textTheme.textTheme.tabLabelTextStyle.color,
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
    // Build section for tasks within a specific time range
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
    // Filter tasks by time range and sort by start time
    final startTimeMinutes = startTime.hour * 60 + startTime.minute;
    final endTimeMinutes = endTime.hour * 60 + endTime.minute;
    List<ScheduledTask> filteredTasks;

    if (filterByTaskStart) {
      // Include tasks starting within the time range
      filteredTasks = tasks.where((task) {
        final taskStartMinutes = task.startTime.hour * 60 + task.startTime.minute;
        return taskStartMinutes >= startTimeMinutes &&
            taskStartMinutes < endTimeMinutes;
      }).toList();
    } else {
      // Include tasks overlapping the time range
      filteredTasks = tasks.where((task) {
        final taskStartMinutes = task.startTime.hour * 60 + task.startTime.minute;
        final taskEndMinutes = task.endTime.hour * 60 + task.endTime.minute;
        return (taskStartMinutes >= startTimeMinutes &&
            taskStartMinutes < endTimeMinutes) ||
            (taskStartMinutes < startTimeMinutes &&
                taskEndMinutes > startTimeMinutes);
      }).toList();
    }

    // Sort tasks by start time
    filteredTasks.sort((a, b) {
      final aStart = a.startTime.hour * 60 + a.startTime.minute;
      final bStart = b.startTime.hour * 60 + b.startTime.minute;
      return aStart.compareTo(bStart);
    });

    return filteredTasks;
  }

  Widget _buildSectionSkeleton(String title) {
    // Build placeholder UI while loading tasks
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
    // Build error UI for failed task loading
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
    // Build section with tasks or empty state
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
                color: CupertinoTheme.of(context).textTheme.tabLabelTextStyle.color,
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
    // Build header for time section
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
            color: CupertinoTheme.of(context).barBackgroundColor.withOpacity(0.4),
          ),
        ),
      ],
    );
  }

  // Helper method to get icon and label for free time task types
  Map<String, dynamic> _getFreeTimeTaskInfo(ScheduledTaskType type) {
    switch (type) {
      case ScheduledTaskType.sleep:
        return {
          'icon': CupertinoIcons.moon_zzz_fill,
          'label': 'Sleep',
          'color': CupertinoColors.systemIndigo,
        };
      case ScheduledTaskType.mealBreak:
        return {
          'icon': CupertinoIcons.cart_fill,
          'label': 'Meal Break',
          'color': CupertinoColors.systemOrange,
        };
      case ScheduledTaskType.rest:
        return {
          'icon': CupertinoIcons.game_controller_solid,
          'label': 'Rest',
          'color': CupertinoColors.systemTeal,
        };
      default:
        return {
          'icon': CupertinoIcons.clock_fill,
          'label': 'Free Time',
          'color': CupertinoColors.systemBlue,
        };
    }
  }

  Widget _buildTaskItem(ScheduledTask scheduledTask) {
    // Build individual task item
    final calendarCubit = context.read<CalendarCubit>();
    final task = calendarCubit.tasksDB.get(scheduledTask.parentTaskId);
    if (task == null) return const SizedBox.shrink();

    final startTime = DateTimeFormatter.formatTime(
      scheduledTask.startTime,
      is24HourFormat: _userSettings.is24HourFormat,
    );
    final endTime = DateTimeFormatter.formatTime(
      scheduledTask.endTime,
      is24HourFormat: _userSettings.is24HourFormat,
    );
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    // Check if this is a free time task
    final isFreeTimeTask = [
      ScheduledTaskType.sleep,
      ScheduledTaskType.mealBreak,
      ScheduledTaskType.rest,
      ScheduledTaskType.freeTime,
    ].contains(scheduledTask.type);

    // Get free time task info if applicable
    final freeTimeInfo = isFreeTimeTask ? _getFreeTimeTaskInfo(scheduledTask.type) : null;

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
                color: isDarkMode
                    ? CupertinoColors.black.withOpacity(0.3)
                    : CupertinoColors.systemGrey5.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isDarkMode
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
                  color: isFreeTimeTask
                      ? (isDarkMode
                      ? freeTimeInfo!['color'].darkColor
                      : freeTimeInfo!['color'])
                      : _getCategoryColor(task.category.name),
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
                        if (isFreeTimeTask) ...[
                          Icon(
                            freeTimeInfo!['icon'],
                            color: isDarkMode
                                ? freeTimeInfo['color'].darkColor
                                : freeTimeInfo['color'],
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            isFreeTimeTask
                                ? freeTimeInfo!['label']
                                : getHabitName(scheduledTask) ?? task.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: CupertinoTheme.of(context).textTheme.textStyle.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$startTime - $endTime',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoTheme.of(context).textTheme.tabLabelTextStyle.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isFreeTimeTask)
                Icon(
                  task.isDone
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.circle,
                  color: task.isDone
                      ? CupertinoColors.activeGreen
                      : CupertinoTheme.of(context).textTheme.tabLabelTextStyle.color,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    // Get color based on task category and theme brightness
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    switch (category.toLowerCase()) {
      case 'work':
        return isDark ? CupertinoColors.systemBlue.darkColor : CupertinoColors.systemBlue;
      case 'personal':
        return isDark ? CupertinoColors.systemGreen.darkColor : CupertinoColors.systemGreen;
      case 'health':
        return isDark ? CupertinoColors.systemRed.darkColor : CupertinoColors.systemRed;
      case 'education':
        return isDark ? CupertinoColors.systemOrange.darkColor : CupertinoColors.systemOrange;
      case 'social':
        return isDark ? CupertinoColors.systemPurple.darkColor : CupertinoColors.systemPurple;
      default:
        return isDark ? CupertinoColors.systemIndigo.darkColor : CupertinoColors.systemIndigo;
    }
  }

  String? getHabitName(ScheduledTask scheduledTask) {
    // Get habit name based on task frequency
    Task? task = context.read<CalendarCubit>().tasksDB.get(scheduledTask.parentTaskId);

    if (task == null || task.frequency == null) {
      return null;
    }

    var frequencyType = task.frequency!.type.toLowerCase();

    switch (frequencyType) {
      case 'daily':
        return task.frequency!.byDay?.isNotEmpty == true
            ? task.frequency!.byDay!.first.name
            : 'Daily Habit';

      case 'weekly':
        final scheduledDay = _getWeekdayName(scheduledTask.startTime.weekday);
        final weeklyInstance = task.frequency!.byDay?.firstWhere(
              (instance) => instance.selectedDay == scheduledDay,
        );
        return weeklyInstance != null ? weeklyInstance.name : 'Weekly Habit';

      case 'monthly':
        if (task.frequency!.byMonthDay != null && task.frequency!.byMonthDay!.isNotEmpty) {
          final scheduledDay = scheduledTask.startTime.day;
          final monthlyInstance = task.frequency!.byMonthDay?.firstWhere(
                (instance) => int.parse(instance.selectedDay) == scheduledDay,
          );
          return monthlyInstance != null ? monthlyInstance.name : 'Monthly Habit';
        } else if (task.frequency!.bySetPos != null && task.frequency!.byDay != null) {
          final scheduledDay = _getWeekdayName(scheduledTask.startTime.weekday);
          final patternInstance = task.frequency!.byDay?.firstWhere(
                (instance) => instance.selectedDay == scheduledDay,
          );
          return patternInstance != null ? patternInstance.name : 'Monthly Pattern Habit';
        }
        return 'Monthly Habit';

      case 'yearly':
        return task.frequency!.byDay?.isNotEmpty == true
            ? task.frequency!.byDay!.first.name
            : 'Yearly Habit';

      default:
        return task.frequency!.byDay?.isNotEmpty == true
            ? task.frequency!.byDay!.first.name
            : task.title; // Fallback to task title
    }
  }

  String _getWeekdayName(int weekday) {
    // Get weekday name from index
    const weekdays = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return weekdays[weekday - 1];
  }

  void _showTaskDetails(Task task, ScheduledTask scheduledTask) {
    // Show task details in a modal popup
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    // Check if this is a free time task
    final isFreeTimeTask = [
      ScheduledTaskType.sleep,
      ScheduledTaskType.mealBreak,
      ScheduledTaskType.rest,
      ScheduledTaskType.freeTime,
    ].contains(scheduledTask.type);

    // Get free time task info if applicable
    final freeTimeInfo = isFreeTimeTask ? _getFreeTimeTaskInfo(scheduledTask.type) : null;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: isFreeTimeTask
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              freeTimeInfo!['icon'],
              color: isDark ? freeTimeInfo['color'].darkColor : freeTimeInfo['color'],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(freeTimeInfo['label']),
          ],
        )
            : Text(getHabitName(scheduledTask) ?? task.title),
        message: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              '${DateTimeFormatter.formatTime(scheduledTask.startTime, is24HourFormat: _userSettings.is24HourFormat)}'
                  ' - ${DateTimeFormatter.formatTime(scheduledTask.endTime, is24HourFormat: _userSettings.is24HourFormat)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: CupertinoTheme.of(context).textTheme.textStyle.color,
              ),
            ),
            if (!isFreeTimeTask && task.notes != null && task.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.notes!,
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoTheme.of(context).textTheme.textStyle.color,
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
                    color: isFreeTimeTask
                        ? (isDark ? freeTimeInfo!['color'].darkColor : freeTimeInfo?['color'])
                        : _getCategoryColor(task.category.name),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isFreeTimeTask ? 'Type: ${freeTimeInfo!['label']}' : 'Category: ${task.category.name}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: CupertinoTheme.of(context).textTheme.textStyle.color,
                  ),
                ),
              ],
            ),
            if (isFreeTimeTask) ...[
              const SizedBox(height: 8),
              Text(
                'This is scheduled free time from your settings.',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: CupertinoTheme.of(context).textTheme.tabLabelTextStyle.color,
                ),
              ),
            ],
            if (!isFreeTimeTask) ...[
              const SizedBox(height: 16),
              Container(height: 1, color: CupertinoColors.separator),
              const SizedBox(height: 16),
              TaskTimerControls(task: task, isDarkMode: isDark),
            ],
          ],
        ),
        actions: [
          if (!isFreeTimeTask)
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