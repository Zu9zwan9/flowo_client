import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

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

class _DailyOverviewScreenState extends State<DailyOverviewScreen>
    with TickerProviderStateMixin {
  late DateTime _selectedDate;
  late UserSettings _userSettings;
  String _greeting = '';
  String _userName = '';
  bool _isCalendarVisible = false;
  late AnimationController _calendarAnimationController;
  late Animation<Offset> _slideAnimation;
  late CalendarController _calendarController;
  late ScrollController _scrollController;
  late AnimationController _lottieController;
  final double _calendarHeight = 350.0;
  bool isAnimationActive = false;

  @override
  void initState() {
    super.initState();
    _userSettings = context.read<TaskManagerCubit>().taskManager.userSettings;
    _selectedDate = DateTime.now();

    // Initialize animation controller
    _calendarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: const Offset(0, 0),
    ).animate(
      CurvedAnimation(
        parent: _calendarAnimationController,
        curve: Curves.easeOutQuart,
      ),
    );

    // Initialize calendar controller
    _calendarController = CalendarController();

    _lottieController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scrollController = ScrollController();

    // Set initial date in CalendarCubit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CalendarCubit>().selectDate(_selectedDate);
        _calendarController
          ..selectedDate = _selectedDate
          ..displayDate = _selectedDate;
      }
    });

    _updateGreeting();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _calendarAnimationController.dispose();
    _calendarController.dispose();
    _lottieController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    _greeting =
        hour < 12
            ? 'Good morning'
            : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
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

  void _navigateToPreviousDay() {
    _scrollController.jumpTo(0.0);
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    context.read<CalendarCubit>().selectDate(_selectedDate);
    _calendarController
      ..selectedDate = _selectedDate
      ..displayDate = _selectedDate;
  }

  void _navigateToNextDay() {
    _scrollController.jumpTo(0.0);
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    context.read<CalendarCubit>().selectDate(_selectedDate);
    _calendarController
      ..selectedDate = _selectedDate
      ..displayDate = _selectedDate;
  }

  void hideCalendar() async {
    if (_isCalendarVisible) {
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          350.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
      if (!mounted)
        return; // Check if widget is still mounted after async operation
      setState(() {
        _isCalendarVisible = false;
        _scrollController.jumpTo(0.0);
        _calendarAnimationController.reset();
        _lottieController.reset();
        isAnimationActive = false;
      });
    }
  }

  void _handlePull(double offset) {
    if (!_isCalendarVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return; // Check if widget is still mounted
        if (offset > 80 && !isAnimationActive) {
          _lottieController.forward();
          isAnimationActive = true;
        } else if (offset <= 20 && !_lottieController.isAnimating) {
          _lottieController.reset();
          isAnimationActive = false;
        }
      });
    }
  }

  Future<void> _showCalendar() async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Show calendar and refresh tasks data
    if (mounted && !_isCalendarVisible) {
      setState(() {
        _isCalendarVisible = true;
        _calendarAnimationController.forward();
        _lottieController.forward().then((_) {
          if (mounted) {
            // Check if widget is still mounted
            _lottieController.reset();
            isAnimationActive = false;
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: EasyRefresh(
                spring: const SpringDescription(
                  mass: 1.0,
                  stiffness: 200.0,
                  damping: 20.0,
                ),
                header: BuilderHeader(
                  triggerOffset: 80.0,
                  clamping: false,
                  position: IndicatorPosition.behind,
                  builder: (context, state) {
                    _handlePull(state.offset);
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color:
                            CupertinoTheme.of(context).scaffoldBackgroundColor,
                      ),
                    );
                  },
                ),
                onRefresh: _showCalendar,
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(height: _isCalendarVisible ? 7 : 0),
                    ),
                    _isCalendarVisible
                        ? SliverToBoxAdapter(
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                Container(
                                  height: _calendarHeight,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  decoration: BoxDecoration(
                                    color: textTheme.scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: CupertinoColors.black
                                            .withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: SfCalendar(
                                    view: CalendarView.month,
                                    controller: _calendarController,
                                    dataSource: CalendarTaskDataSource(
                                      context
                                          .read<TaskManagerCubit>()
                                          .getScheduledTasks(),
                                    ),
                                    initialSelectedDate: _selectedDate,
                                    initialDisplayDate: _selectedDate,
                                    onSelectionChanged: (details) {
                                      if (details.date != null && mounted) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              setState(() {
                                                _selectedDate = details.date!;
                                              });
                                              context
                                                  .read<CalendarCubit>()
                                                  .selectDate(_selectedDate);
                                            });
                                      }
                                    },
                                    showNavigationArrow: true,
                                    allowViewNavigation: false,
                                    headerStyle: CalendarHeaderStyle(
                                      textStyle: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            textTheme.textTheme.textStyle.color,
                                      ),
                                    ),
                                    monthViewSettings: MonthViewSettings(
                                      appointmentDisplayMode:
                                          MonthAppointmentDisplayMode.indicator,
                                      showAgenda: false,
                                      monthCellStyle: MonthCellStyle(
                                        textStyle: TextStyle(
                                          color:
                                              textTheme
                                                  .textTheme
                                                  .textStyle
                                                  .color,
                                          fontSize: 14,
                                        ),
                                        todayTextStyle: TextStyle(
                                          color: CupertinoColors.activeBlue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        backgroundColor:
                                            CupertinoColors.transparent,
                                        todayBackgroundColor: CupertinoColors
                                            .activeBlue
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                    todayHighlightColor:
                                        CupertinoColors.activeBlue,
                                    selectionDecoration: BoxDecoration(
                                      shape: BoxShape.rectangle,
                                      color: CupertinoColors.activeBlue
                                          .withOpacity(0.2),
                                      border: Border.all(
                                        color: CupertinoColors.activeBlue,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                CupertinoButton(
                                  padding: const EdgeInsets.all(4),
                                  onPressed: hideCalendar,
                                  child: const Icon(
                                    CupertinoIcons.chevron_up,
                                    color: CupertinoColors.inactiveGray,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        : SliverToBoxAdapter(child: const SizedBox()),

                    !_isCalendarVisible
                        ? SliverToBoxAdapter(
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              _scrollController.hasClients
                                  ? _scrollController.offset - 55
                                  : -55,
                            ),
                            child: Container(
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color:
                                    CupertinoTheme.of(
                                      context,
                                    ).scaffoldBackgroundColor,
                              ),
                              child: SizedBox(
                                height: 36,
                                width: 36,
                                child: ColorFiltered(
                                  colorFilter: const ColorFilter.mode(
                                    CupertinoColors.activeBlue,
                                    BlendMode.srcIn,
                                  ),
                                  child: Lottie.asset(
                                    'lib/assets/lottifile/calendarAnimation.json',
                                    frameRate: FrameRate.composition,
                                    controller: _lottieController,
                                    onLoaded: (composition) {
                                      _lottieController.duration =
                                          composition.duration;
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        : SliverToBoxAdapter(child: const SizedBox(height: 3)),
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final formattedDate = DateFormat('EEEE, MMMM d').format(_selectedDate);
    final textTheme = CupertinoTheme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      // Уменьшен верхний отступ
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
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _navigateToPreviousDay,
                child: Icon(
                  CupertinoIcons.chevron_left,
                  color: textTheme.primaryColor,
                  semanticLabel: 'Previous day',
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 18,
                    color: textTheme.textTheme.tabLabelTextStyle.color,
                  ),
                  textAlign: TextAlign.center,
                  semanticsLabel: formattedDate,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _navigateToNextDay,
                child: Icon(
                  CupertinoIcons.chevron_right,
                  color: textTheme.primaryColor,
                  semanticLabel: 'Next day',
                ),
              ),
            ],
          ),
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

    final filteredTasks =
        tasks.where((task) {
          final taskStartMinutes =
              task.startTime.hour * 60 + task.startTime.minute;
          final taskEndMinutes = task.endTime.hour * 60 + task.endTime.minute;
          if (filterByTaskStart) {
            return taskStartMinutes >= startTimeMinutes &&
                taskStartMinutes < endTimeMinutes;
          }
          return (taskStartMinutes >= startTimeMinutes &&
                  taskStartMinutes < endTimeMinutes) ||
              (taskStartMinutes < startTimeMinutes &&
                  taskEndMinutes > startTimeMinutes);
        }).toList();

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Error loading tasks: $error',
                  style: TextStyle(
                    color: CupertinoColors.destructiveRed,
                    fontSize: 14,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text('Retry'),
                onPressed: () => setState(() {}), // Trigger rebuild
              ),
            ],
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

    final isFreeTimeTask = [
      ScheduledTaskType.sleep,
      ScheduledTaskType.mealBreak,
      ScheduledTaskType.rest,
      ScheduledTaskType.freeTime,
    ].contains(scheduledTask.type);

    final freeTimeInfo =
        isFreeTimeTask ? _getFreeTimeTaskInfo(scheduledTask.type) : null;

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
                constraints: BoxConstraints(
                  minHeight: 40,
                  maxHeight: double.infinity,
                ),
                decoration: BoxDecoration(
                  color:
                      isFreeTimeTask
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
                            color:
                                isDarkMode
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
                                : getHabitName(scheduledTask) ??
                                    '(${task.parentTask?.title} ${task.order}) ${task.title}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color:
                                  CupertinoTheme.of(
                                    context,
                                  ).textTheme.textStyle.color,
                            ),
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
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
              if (!isFreeTimeTask)
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
                  semanticLabel:
                      task.isDone ? 'Task completed' : 'Task not completed',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
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

  String? getHabitName(ScheduledTask scheduledTask) {
    final task = context.read<CalendarCubit>().tasksDB.get(
      scheduledTask.parentTaskId,
    );
    if (task == null || task.frequency == null) return null;

    final frequencyType = task.frequency!.type.toLowerCase();
    switch (frequencyType) {
      case 'daily':
        return task.frequency!.byDay?.isNotEmpty ?? false
            ? task.frequency!.byDay!.first.name
            : 'Daily Habit';
      case 'weekly':
        final scheduledDay = _getWeekdayName(scheduledTask.startTime.weekday);
        final weeklyInstance = task.frequency!.byDay?.firstWhere(
          (instance) => instance.selectedDay == scheduledDay,
          orElse: () => task.frequency!.byDay!.first,
        );
        return weeklyInstance?.name ?? 'Weekly Habit';
      case 'monthly':
        if (task.frequency!.byMonthDay?.isNotEmpty ?? false) {
          final scheduledDay = scheduledTask.startTime.day;
          final monthlyInstance = task.frequency!.byMonthDay?.firstWhere(
            (instance) => int.parse(instance.selectedDay) == scheduledDay,
            orElse: () => task.frequency!.byMonthDay!.first,
          );
          return monthlyInstance?.name ?? 'Monthly Habit';
        } else if (task.frequency!.bySetPos != null &&
            task.frequency!.byDay?.isNotEmpty == true) {
          final scheduledDay = _getWeekdayName(scheduledTask.startTime.weekday);
          final patternInstance = task.frequency!.byDay?.firstWhere(
            (instance) => instance.selectedDay == scheduledDay,
            orElse: () => task.frequency!.byDay!.first,
          );
          return patternInstance?.name ?? 'Monthly Pattern Habit';
        }
        return 'Monthly Habit';
      case 'yearly':
        return task.frequency!.byDay?.isNotEmpty ?? false
            ? task.frequency!.byDay!.first.name
            : 'Yearly Habit';
      default:
        return task.frequency!.byDay?.isNotEmpty ?? false
            ? task.frequency!.byDay!.first.name
            : task.title;
    }
  }

  String _getWeekdayName(int weekday) {
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
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final isFreeTimeTask = [
      ScheduledTaskType.sleep,
      ScheduledTaskType.mealBreak,
      ScheduledTaskType.rest,
      ScheduledTaskType.freeTime,
    ].contains(scheduledTask.type);

    final freeTimeInfo =
        isFreeTimeTask ? _getFreeTimeTaskInfo(scheduledTask.type) : null;

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title:
                isFreeTimeTask
                    ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          freeTimeInfo!['icon'],
                          color:
                              isDark
                                  ? freeTimeInfo['color'].darkColor
                                  : freeTimeInfo['color'],
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
                if (!isFreeTimeTask && task.notes?.isNotEmpty == true) ...[
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
                        color:
                            isFreeTimeTask
                                ? (isDark
                                    ? freeTimeInfo!['color'].darkColor
                                    : freeTimeInfo?['color'])
                                : _getCategoryColor(task.category.name),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isFreeTimeTask
                          ? 'Type: ${freeTimeInfo!['label']}'
                          : 'Category: ${task.category.name}',
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
                if (isFreeTimeTask) ...[
                  const SizedBox(height: 8),
                  Text(
                    'This is scheduled free time from your settings.',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color:
                          CupertinoTheme.of(
                            context,
                          ).textTheme.tabLabelTextStyle.color,
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
