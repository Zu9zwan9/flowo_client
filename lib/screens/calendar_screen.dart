import 'package:flowo_client/blocs/tasks_controller/tasks_controller_cubit.dart';
import 'package:flowo_client/screens/widgets/calendar_widgets.dart';
import 'package:flowo_client/utils/date_time_formatter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../blocs/tasks_controller/task_manager_cubit.dart';
import '../blocs/tasks_controller/task_manager_state.dart';
import '../models/scheduled_task.dart';
import '../models/task.dart';

/// An improved Calendar screen with enhanced UI/UX following iOS design guidelines
/// and implementing best practices, SOLID principles, and proper error handling.
///
/// This screen displays a calendar with events and allows users to:
/// - View events in different calendar views (month, week, day)
/// - Navigate between dates
/// - Search for events
/// - View event details
/// - Add new events
///
/// The implementation follows iOS design guidelines and best practices:
/// - Uses Cupertino widgets for iOS look and feel
/// - Implements proper error handling and loading states
/// - Uses responsive design for different screen sizes
/// - Follows SOLID principles for maintainable code
/// - Optimizes performance by reducing unnecessary data fetching
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

  // Store the Future to avoid unnecessary data fetching
  // This improves performance by preventing redundant database queries
  // when the widget rebuilds but the selected date hasn't changed
  Future<List<TaskWithSchedules>>? _scheduledTasksFuture;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Select the current date in the calendar cubit
      context.read<CalendarCubit>().selectDate(_selectedDate);;

      // Ensure tasks are scheduled
      // Select the current date in the calendar cubit

      // Initialize the Future for scheduled tasks
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
      // Reload data
      context.read<TaskManagerCubit>().scheduleTasks();

      // Update the Future for scheduled tasks
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

  void _showEventDetails(Task task, ScheduledTask scheduledTask) {
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
                  // Navigate to edit event screen
                  // This would be implemented in a real app
                },
                child: const Text('Edit Event'),
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(task);
                },
                child: const Text('Delete Event'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  void _showDeleteConfirmation(Task task) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Delete Event'),
            content: Text('Are you sure you want to delete "${task.title}"?'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _deleteTask(task);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteTask(Task task) async {
    try {
      context.read<TaskManagerCubit>().deleteTask(task);
      _showSuccessMessage('Event deleted successfully');
    } catch (e) {
      _showErrorMessage('Failed to delete event: ${e.toString()}');
    }
  }

  void _showSuccessMessage(String message) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            message: Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ),
    );
  }

  void _showErrorMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _navigateToAddEvent() {
    // This would navigate to the add event screen in a real app
    _showSuccessMessage('Add Event functionality would be implemented here');
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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Calendar'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _navigateToAddEvent,
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
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
                  CalendarViewSelector(
                    selectedView: _calendarView,
                    onViewChanged: _onViewChanged,
                  ),

                  // Calendar header
                  CalendarHeader(
                    selectedDate: _selectedDate,
                    onTodayPressed: _goToToday,
                    onPreviousPressed: _goToPreviousPeriod,
                    onNextPressed: _goToNextPeriod,
                  ),

                  // Calendar view with responsive height
                  // Using a percentage of screen height instead of fixed height
                  // This prevents layout issues on smaller screens and different orientations
                  // and ensures the calendar scales appropriately on all devices
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
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
                          0.3, // 30% of screen height
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
        return SfCalendar(
          view: _calendarView,
          showNavigationArrow: false,
          showDatePickerButton: false,
          dataSource: CalendarTaskDataSource(
            context.read<TaskManagerCubit>().getScheduledTasks(),
          ),
          initialSelectedDate: _selectedDate,
          onTap: (details) {
            if (details.date != null) {
              _onDateSelected(details.date!);
            }
          },
          monthViewSettings: const MonthViewSettings(
            appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
            showAgenda: false,
          ),
          timeSlotViewSettings: const TimeSlotViewSettings(
            startHour: 6,
            endHour: 22,
            timeFormat: 'h:mm a',
            timeInterval: Duration(minutes: 30),
            timeIntervalHeight: 80,
            timeTextStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
          ),
          selectionDecoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: CupertinoColors.activeBlue.withOpacity(0.2),
          ),
          todayHighlightColor: CupertinoColors.activeBlue,
          headerHeight: 0, // Hide the default header
          viewHeaderStyle: const ViewHeaderStyle(
            dayTextStyle: TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
          ),
          appointmentTextStyle: const TextStyle(fontSize: 14),
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
                  return task.title.toLowerCase().contains(query) ||
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
                                  : task.title,
                          subtitle: task.notes,
                          startTime: scheduledTask.startTime,
                          endTime: scheduledTask.endTime,
                          categoryColor: _getCategoryColor(task.category.name),
                          onTap: () => _showEventDetails(task, scheduledTask),
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
