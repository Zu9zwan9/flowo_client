import 'package:flutter/cupertino.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../models/scheduled_task.dart';
import '../../utils/date_time_formatter.dart';

/// A collection of reusable widgets for the calendar screen
/// following iOS design guidelines and best practices for Cupertino UI

/// Represents a segmented control for switching between calendar views
class CalendarViewSelector extends StatefulWidget {
  final CalendarView selectedView;
  final ValueChanged<CalendarView> onViewChanged;
  final EdgeInsetsGeometry padding;

  const CalendarViewSelector({
    super.key,
    required this.selectedView,
    required this.onViewChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  });

  @override
  State<CalendarViewSelector> createState() => _CalendarViewSelectorState();
}

class _CalendarViewSelectorState extends State<CalendarViewSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.value = 1.0; // Start fully visible
  }

  @override
  void didUpdateWidget(CalendarViewSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedView != widget.selectedView) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, Widget> children = {
      'Month': const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Text('Month'),
      ),
      'Week': const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Text('Week'),
      ),
      'Day': const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Text('Day'),
      ),
    };

    String groupValue;
    switch (widget.selectedView) {
      case CalendarView.month:
        groupValue = 'Month';
        break;
      case CalendarView.week:
        groupValue = 'Week';
        break;
      case CalendarView.day:
        groupValue = 'Day';
        break;
      default:
        groupValue = 'Month';
    }

    return Padding(
      padding: widget.padding,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: CupertinoSlidingSegmentedControl<String>(
          groupValue: groupValue,
          children: children,
          onValueChanged: (value) {
            if (value != null) {
              CalendarView newView;
              switch (value) {
                case 'Month':
                  newView = CalendarView.month;
                  break;
                case 'Week':
                  newView = CalendarView.week;
                  break;
                case 'Day':
                  newView = CalendarView.day;
                  break;
                default:
                  newView = CalendarView.month;
              }
              widget.onViewChanged(newView);
            }
          },
        ),
      ),
    );
  }
}

/// A custom calendar header with iOS styling
class CalendarHeader extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTodayPressed;
  final VoidCallback? onPreviousPressed;
  final VoidCallback? onNextPressed;
  final EdgeInsetsGeometry padding;

  const CalendarHeader({
    super.key,
    required this.selectedDate,
    required this.onTodayPressed,
    this.onPreviousPressed,
    this.onNextPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  });

  @override
  Widget build(BuildContext context) {
    final month = _getMonthName(selectedDate.month);
    final year = selectedDate.year.toString();

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Month and year
          Flexible(
            child: Text(
              '$month $year',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Navigation buttons
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: onTodayPressed,
                    child: const Text('Today'),
                  ),
                  if (onPreviousPressed != null)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: onPreviousPressed,
                      child: const Icon(
                        CupertinoIcons.chevron_left,
                        color: CupertinoColors.systemBlue,
                      ),
                    ),
                  if (onNextPressed != null)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: onNextPressed,
                      child: const Icon(
                        CupertinoIcons.chevron_right,
                        color: CupertinoColors.systemBlue,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
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
}

/// A custom agenda item with iOS styling
class AgendaItem extends StatefulWidget {
  final String title;
  final String? subtitle;
  final DateTime startTime;
  final DateTime endTime;
  final Color categoryColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool showDivider;

  const AgendaItem({
    super.key,
    required this.title,
    this.subtitle,
    required this.startTime,
    required this.endTime,
    required this.categoryColor,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    this.showDivider = true,
  });

  @override
  State<AgendaItem> createState() => _AgendaItemState();
}

class _AgendaItemState extends State<AgendaItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isTapped = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isTapped = false);
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isTapped = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final containerColor =
        brightness == Brightness.dark
            ? CupertinoColors.darkBackgroundGray
            : CupertinoColors.white;
    final textColor =
        brightness == Brightness.dark
            ? CupertinoColors.white
            : CupertinoColors.black;
    final secondaryTextColor =
        brightness == Brightness.dark
            ? CupertinoColors.systemGrey
            : CupertinoColors.systemGrey;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: Padding(
          padding: widget.padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time column
              SizedBox(
                width: 50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      DateTimeFormatter.formatTime(widget.startTime),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      DateTimeFormatter.formatTime(widget.endTime),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 1),
              // Content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        _isTapped
                            ? CupertinoColors.systemGrey6
                            : containerColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CupertinoColors.systemGrey4),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Category color indicator
                      Container(
                        width: 4,
                        height: 40,
                        color: widget.categoryColor,
                      ),
                      const SizedBox(width: 12),
                      // Title and subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: CupertinoTheme.of(
                                context,
                              ).textTheme.textStyle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (widget.subtitle != null &&
                                widget.subtitle!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.subtitle!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: secondaryTextColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A custom empty state widget with iOS styling
///
/// This widget displays a message when there are no events or when an error occurs.
/// It includes an icon, a title, an optional message, and an optional action button.
///
/// The widget uses a SingleChildScrollView to prevent overflow issues on smaller screens
/// or when the content is too large to fit within the available space. This ensures
/// that all content is accessible even on constrained layouts.
class EmptyStateView extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final EdgeInsetsGeometry padding;

  const EmptyStateView({
    super.key,
    required this.title,
    this.message,
    this.icon = CupertinoIcons.calendar_badge_plus,
    this.onActionPressed,
    this.actionLabel,
    this.padding = const EdgeInsets.all(32.0),
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final textColor =
        brightness == Brightness.dark
            ? CupertinoColors.white
            : CupertinoColors.black;
    final secondaryTextColor =
        brightness == Brightness.dark
            ? CupertinoColors.systemGrey
            : CupertinoColors.systemGrey;

    return Padding(
      padding: padding,
      child: Center(
        child: SingleChildScrollView(
          // SingleChildScrollView prevents RenderFlex overflow errors by allowing
          // the content to scroll if it doesn't fit within the available space
          // This is especially important for smaller screens or when the content
          // includes multiple elements like icon, title, message, and button
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Use minimum space needed
            children: [
              Icon(icon, size: 64, color: CupertinoColors.systemGrey),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  style: TextStyle(fontSize: 16, color: secondaryTextColor),
                  textAlign: TextAlign.center,
                ),
              ],
              if (onActionPressed != null && actionLabel != null) ...[
                const SizedBox(height: 24),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  color: CupertinoColors.systemBlue,
                  onPressed: onActionPressed,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A custom calendar data source for the SfCalendar widget
class CalendarTaskDataSource extends CalendarDataSource {
  CalendarTaskDataSource(List<ScheduledTask> scheduledTasks) {
    appointments = scheduledTasks;
  }

  @override
  DateTime getStartTime(int index) => appointments![index].startTime;

  @override
  DateTime getEndTime(int index) => appointments![index].endTime;

  @override
  String getSubject(int index) =>
      appointments![index].parentTask?.title ?? 'Untitled';

  @override
  Color getColor(int index) => _getCategoryColor(
    appointments![index].parentTask?.category.name ?? 'default',
  );

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
}

/// A custom date selector with iOS styling
class DateSelector extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final EdgeInsetsGeometry padding;

  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  });

  @override
  State<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.value = 1.0; // Start fully visible
  }

  @override
  void didUpdateWidget(DateSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 216,
          padding: const EdgeInsets.only(top: 6.0),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: CupertinoTheme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: widget.selectedDate,
                    onDateTimeChanged: widget.onDateSelected,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.selectedDate.day.toString();
    final month = _getShortMonthName(widget.selectedDate.month);
    final year = widget.selectedDate.year.toString();
    final weekday = _getWeekdayName(widget.selectedDate.weekday);

    return Padding(
      padding: widget.padding,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showDatePicker,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$weekday, $month $day, $year',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.calendar,
                  color: CupertinoColors.systemBlue,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getShortMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday - 1];
  }
}

/// A floating action button for adding new tasks, events, or habits
class CalendarActionButton extends StatelessWidget {
  final VoidCallback onAddTask;
  final VoidCallback onAddEvent;
  final VoidCallback onAddHabit;

  const CalendarActionButton({
    super.key,
    required this.onAddTask,
    required this.onAddEvent,
    required this.onAddHabit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showActionSheet(context),
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBlue,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          CupertinoIcons.add,
          color: CupertinoColors.white,
          size: 32,
        ),
      ),
    );
  }

  VoidCallback _showActionSheet(BuildContext context) {
    return () {
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
                    onAddTask();
                  },
                ),
                CupertinoActionSheetAction(
                  child: const Text('Add Event'),
                  onPressed: () {
                    Navigator.pop(context);
                    onAddEvent();
                  },
                ),
                CupertinoActionSheetAction(
                  child: const Text('Add Habit'),
                  onPressed: () {
                    Navigator.pop(context);
                    onAddHabit();
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
    };
  }
}
