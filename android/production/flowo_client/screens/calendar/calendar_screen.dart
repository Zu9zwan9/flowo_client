import 'package:flowo_client/blocs/tasks_controller/tasks_controller_cubit.dart';
import 'package:flowo_client/screens/event/event_form_screen.dart';
import 'package:flowo_client/screens/widgets/calendar_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../blocs/tasks_controller/task_manager_cubit.dart';
import '../../blocs/tasks_controller/task_manager_state.dart';
import '../../models/scheduled_task.dart';
import '../../models/task.dart';
import '../../models/user_settings.dart';
import '../habit/habit_form_screen.dart';
import '../task/task_form_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  final ScrollController _scrollController = ScrollController();
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  CalendarView _calendarView = CalendarView.month;
  bool _isRefreshing = false;
  bool _isLoading = false;
  String? _errorMessage;
  late UserSettings _userSettings;

  Future<List<TaskWithSchedules>>? _scheduledTasksFuture;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadInitialData();
    _userSettings = context.read<TaskManagerCubit>().taskManager.userSettings;
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      context.read<CalendarCubit>().selectDate(_selectedDate);

      _scheduledTasksFuture = context
          .read<TaskManagerCubit>()
          .getScheduledTasksForDate(_selectedDate);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load calendar data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  void _onDateSelected(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      // Update the Future when the selected date changes
      _scheduledTasksFuture = context
          .read<TaskManagerCubit>()
          .getScheduledTasksForDate(newDate);
    });
    context.read<CalendarCubit>().selectDate(newDate);
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      context.read<TaskManagerCubit>().scheduleTasks();

      _scheduledTasksFuture = context
          .read<TaskManagerCubit>()
          .getScheduledTasksForDate(_selectedDate);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to refresh data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _onViewChanged(CalendarView newView) {
    setState(() {
      _calendarView = newView;

      _scheduledTasksFuture = context
          .read<TaskManagerCubit>()
          .getScheduledTasksForDate(_selectedDate);
    });
  }

  void _goToToday() {
    _onDateSelected(DateTime.now());
  }

  void _goToPreviousPeriod() {
    DateTime newDate;
    switch (_calendarView) {
      case CalendarView.month:
        newDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
        break;
      case CalendarView.week:
        newDate = _selectedDate.subtract(const Duration(days: 7));
        break;
      case CalendarView.day:
        newDate = _selectedDate.subtract(const Duration(days: 1));
        break;
      default:
        newDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
    }
    _onDateSelected(newDate);
  }

  void _goToNextPeriod() {
    DateTime newDate;
    switch (_calendarView) {
      case CalendarView.month:
        newDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
        break;
      case CalendarView.week:
        newDate = _selectedDate.add(const Duration(days: 7));
        break;
      case CalendarView.day:
        newDate = _selectedDate.add(const Duration(days: 1));
        break;
      default:
        newDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
    }
    _onDateSelected(newDate);
  }

  void _navigateToAddEvent() {
    _showAddActionSheet();
  }

  void _showAddActionSheet() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: const Text('Add New'),
            message: const Text('Choose what you want to create'),
            actions: <CupertinoActionSheetAction>[
              CupertinoActionSheetAction(
                child: const Text('Add Task'),
                onPressed: () {
                  Navigator.pop(context);
                  _addTask();
                },
              ),
              CupertinoActionSheetAction(
                child: const Text('Add Event'),
                onPressed: () {
                  Navigator.pop(context);
                  _addEvent();
                },
              ),
              CupertinoActionSheetAction(
                child: const Text('Add Habit'),
                onPressed: () {
                  Navigator.pop(context);
                  _addHabit();
                },
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
    );
  }

  void _addTask() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => TaskFormScreen(selectedDate: _selectedDate),
      ),
    ).then((_) => _refreshData());
  }

  void _addEvent() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => EventFormScreen(selectedDate: _selectedDate),
      ),
    ).then((_) => _refreshData());
  }

  void _addHabit() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => HabitFormScreen(selectedDate: _selectedDate),
      ),
    ).then((_) => _refreshData());
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(child: SafeArea(child: _buildContent()));
  }

  Widget _buildContent() {
    final textColor =
        CupertinoTheme.of(context).textTheme.textStyle.color ??
        CupertinoColors.label;

    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 16));
    }

    if (_errorMessage != null) {
      return Center(
        child: EmptyStateView(
          title: 'Error Loading Calendar',
          message: _errorMessage,
          icon: CupertinoIcons.exclamationmark_circle,
          actionLabel: 'Retry',
          onActionPressed: _loadInitialData,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Calendar view selector
                  Center(
                    child: CalendarViewSelector(
                      selectedView: _calendarView,
                      onViewChanged: _onViewChanged,
                    ),
                  ),

                  // Calendar header
                  CalendarHeader(
                    selectedDate: _selectedDate,
                    onTodayPressed: _goToToday,
                    onPreviousPressed: _goToPreviousPeriod,
                    onNextPressed: _goToNextPeriod,
                  ),

                  SizedBox(
                    height:
                        MediaQuery.of(context).size.height *
                        0.4, // 40% of screen height
                    child: _buildCalendar(),
                  ),

                  // Selected date header
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    child: Text(
                      '${_weekdayName(_selectedDate.weekday)}, ${_monthName(_selectedDate.month)} ${_selectedDate.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: CupertinoSearchTextField(
                      controller: _searchController,
                      placeholder: 'Search events',
                      onChanged: (value) => setState(() {}),
                    ),
                  ),

                  // Agenda view
                  Flexible(
                    child: SizedBox(
                      height:
                          MediaQuery.of(context).size.height *
                          0.35, // 35% of screen height
                      child: _buildAgendaView(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendar() {
    return BlocBuilder<TaskManagerCubit, TaskManagerState>(
      builder: (context, state) {
        // Create a key that changes when the view changes to force a rebuild
        final calendarKey = ValueKey(
          '${_calendarView}_${_selectedDate.millisecondsSinceEpoch}',
        );

        return SfCalendar(
          key: calendarKey,
          view: _calendarView,
          showNavigationArrow: true,
          showDatePickerButton: true,
          dataSource: CalendarTaskDataSource(
            context.read<TaskManagerCubit>().getScheduledTasks(),
          ),
          initialSelectedDate: _selectedDate,
          initialDisplayDate: _selectedDate,
          onViewChanged: (ViewChangedDetails details) {
            // Don't call setState during build
            if (details.visibleDates.isNotEmpty) {
              final newDate =
                  details.visibleDates[details.visibleDates.length ~/ 2];
              if (newDate.month != _selectedDate.month ||
                  newDate.year != _selectedDate.year) {
                // Schedule state update for after the build is complete
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _selectedDate = DateTime(
                        newDate.year,
                        newDate.month,
                        newDate.day,
                      );
                    });
                    context.read<CalendarCubit>().selectDate(_selectedDate);

                    // Update the Future for scheduled tasks
                    _scheduledTasksFuture = context
                        .read<TaskManagerCubit>()
                        .getScheduledTasksForDate(_selectedDate);
                  }
                });
              }
            }
          },
          onTap: (details) {
            if (details.date != null) {
              _onDateSelected(details.date!);
            }
          },
          monthViewSettings: const MonthViewSettings(
            appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
            showAgenda: false,
            navigationDirection:
                MonthNavigationDirection.horizontal, // Enable horizontal swipe
          ),
          timeSlotViewSettings: const TimeSlotViewSettings(
            startHour: 6,
            endHour: 22,
            timeFormat: 'h:mm a',
            timeInterval: Duration(minutes: 30),
            timeIntervalHeight: 80,
            timeTextStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
          selectionDecoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: CupertinoColors.activeBlue.withOpacity(0.2),
          ),
          todayHighlightColor: CupertinoColors.activeBlue,
          headerHeight: 0,
          viewHeaderStyle: ViewHeaderStyle(
            dayTextStyle: TextStyle(
              fontSize: 12,
              color:
                  CupertinoTheme.of(context).textTheme.textStyle.color ??
                  CupertinoColors.label,
            ),
          ),
          appointmentTextStyle: const TextStyle(fontSize: 14),
          allowViewNavigation: true,
          // Enable view navigation
          allowedViews: const [
            // Define allowed views
            CalendarView.day,
            CalendarView.week,
            CalendarView.month,
          ],
        );
      },
    );
  }

  Widget _buildAgendaView() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _refreshData),
        SliverFillRemaining(child: _buildAgendaContent()),
      ],
    );
  }

  /// Builds the agenda content showing scheduled tasks for the selected date
  ///
  /// This method uses a cached Future (_scheduledTasksFuture) to avoid unnecessary
  /// data fetching when the widget rebuilds. The Future is only updated when:
  /// - The selected date changes (_onDateSelected method)
  /// - The user refreshes the data (_refreshData method)
  /// - The app first loads (_loadInitialData method)
  ///
  /// This optimization improves performance and reduces database queries.
  Widget _buildAgendaContent() {
    // If _scheduledTasksFuture is null, initialize it
    // This is a fallback in case it wasn't initialized elsewhere
    _scheduledTasksFuture ??= context
        .read<TaskManagerCubit>()
        .getScheduledTasksForDate(_selectedDate);

    return FutureBuilder<List<TaskWithSchedules>>(
      future: _scheduledTasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: EmptyStateView(
              title: 'Error Loading Events',
              message: 'Pull down to refresh and try again',
              icon: CupertinoIcons.exclamationmark_circle,
              actionLabel: 'Retry',
              onActionPressed: _refreshData,
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: EmptyStateView(
              title: 'No Events For This Day',
              message:
                  'Your schedule is clear. Tap the + button to add a new event or activity.',
              icon: CupertinoIcons.calendar_badge_plus,
              actionLabel: 'Add Event',
              onActionPressed: _navigateToAddEvent,
            ),
          );
        } else {
          // Extract and prepare tasks for display
          var taskSchedulePairs = _prepareTaskSchedulePairs(snapshot.data!);

          // Filter tasks based on search query
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            taskSchedulePairs =
                taskSchedulePairs.where((pair) {
                  final task = pair.task;
                  final name = getHabitName(pair.scheduledTask) ?? task.title;
                  return name.toLowerCase().contains(query) ||
                      (task.notes != null &&
                          task.notes!.toLowerCase().contains(query)) ||
                      task.category.name.toLowerCase().contains(query);
                }).toList();
          }

          return CupertinoScrollbar(
            controller: _scrollController,
            child:
                taskSchedulePairs.isEmpty
                    ? Center(
                      child: EmptyStateView(
                        title: 'No Matching Events',
                        message: 'Try changing your search query',
                        icon: CupertinoIcons.search,
                        actionLabel: 'Clear Search',
                        onActionPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      itemCount: taskSchedulePairs.length,
                      itemBuilder: (context, index) {
                        final pair = taskSchedulePairs[index];
                        final task = pair.task;
                        final scheduledTask = pair.scheduledTask;

                        return AgendaItem(
                          title:
                              task.title == 'Free Time'
                                  ? _freeTimeName(
                                    scheduledTask.type
                                        .toString()
                                        .split('.')
                                        .last,
                                  )
                                  : getHabitName(scheduledTask) ?? task.title,
                          subtitle: task.notes,
                          startTime: scheduledTask.startTime,
                          endTime: scheduledTask.endTime,
                          categoryColor: _getCategoryColor(task.category.name),
                          //onTap: () => _showEventDetails(task, scheduledTask),
                        );
                      },
                    ),
          );
        }
      },
    );
  }

  // Moving these method definitions up so they can be used earlier in the code
  String _freeTimeName(String type) {
    switch (type) {
      case 'sleep':
        return 'Sleep';
      case 'mealBreak':
        return 'Meal break';
      case 'rest':
        return 'Rest';
      default:
        return 'Free Time';
    }
  }

  String _weekdayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String? getHabitName(ScheduledTask scheduledTask) {
    Task? task = context.read<CalendarCubit>().tasksDB.get(
      scheduledTask.parentTaskId,
    );

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
        if (task.frequency!.byMonthDay != null &&
            task.frequency!.byMonthDay!.isNotEmpty) {
          // Handle specific day of month
          final scheduledDay = scheduledTask.startTime.day;
          final monthlyInstance = task.frequency!.byMonthDay?.firstWhere(
            (instance) => int.parse(instance.selectedDay) == scheduledDay,
          );
          return monthlyInstance != null
              ? monthlyInstance.name
              : 'Monthly Habit';
        } else if (task.frequency!.bySetPos != null &&
            task.frequency!.byDay != null) {
          // Handle pattern (e.g., "first Monday")
          final scheduledDay = _getWeekdayName(scheduledTask.startTime.weekday);
          final patternInstance = task.frequency!.byDay?.firstWhere(
            (instance) => instance.selectedDay == scheduledDay,
          );
          return patternInstance != null
              ? patternInstance.name
              : 'Monthly Pattern Habit';
        }
        return 'Monthly Habit';

      case 'yearly':
        return task.frequency!.byDay?.isNotEmpty == true
            ? task.frequency!.byDay!.first.name
            : 'Yearly Habit';

      default:
        return task.frequency!.byDay?.isNotEmpty == true
            ? task.frequency!.byDay!.first.name
            : task.title; // Fallback to task title if no specific name
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

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'brainstorm':
        return CupertinoColors.systemBlue;
      case 'design':
        return CupertinoColors.systemGreen;
      case 'workout':
        return CupertinoColors.systemRed;
      case 'meeting':
        return CupertinoColors.systemOrange;
      case 'presentation':
        return CupertinoColors.systemPurple;
      case 'event':
        return CupertinoColors.systemIndigo;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  /// Prepares the task-schedule pairs from raw data for display
  /// Transforms nested data structure into a flat list and sorts by start time
  List<({Task task, ScheduledTask scheduledTask})> _prepareTaskSchedulePairs(
    List<TaskWithSchedules> tasksWithSchedules,
  ) {
    final pairs =
        tasksWithSchedules
            .expand(
              (taskWithSchedules) => taskWithSchedules.scheduledTasks.map(
                (scheduledTask) => (
                  task: taskWithSchedules.task,
                  scheduledTask: scheduledTask,
                ),
              ),
            )
            .toList();

    // Sort by start time for chronological display
    pairs.sort(
      (a, b) => a.scheduledTask.startTime.compareTo(b.scheduledTask.startTime),
    );

    return pairs;
  }
}
