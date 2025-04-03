import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/design/cupertino_form_theme.dart';
import 'package:flowo_client/models/day.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/screens/home_screen.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../task/task_page_screen.dart';
import 'event_form_screen.dart';

// Constants for styling adhering to HIG
class EventScreenConstants {
  static const double padding = 16.0;
  static const double cornerRadius = 12.0;
  static const double shadowBlurRadius = 4.0;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );
}

// Utility for formatting dates and times
class EventDateTimeFormatter {
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static String formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '$hours hr${hours > 1 ? 's' : ''} ${minutes > 0 ? '$minutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }
}

// Main EventScreen for viewing event details
class EventScreen extends StatefulWidget {
  final Task event;

  const EventScreen({super.key, required this.event});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  late Task _event;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _notesController = TextEditingController(text: _event.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_event.title, style: theme.textTheme.navTitleTextStyle),
        trailing: SizedBox(
          width: 90,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _navigateToEditScreen(context),
                child: const Icon(CupertinoIcons.pencil),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _confirmDelete(context),
                child: const Icon(CupertinoIcons.trash),
              ),
            ],
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(EventScreenConstants.padding),
          children: [
            EventHeader(event: _event),
            const SizedBox(height: 24),
            EventDetails(event: _event),
            const SizedBox(height: 24),
            if (_event.notes != null && _event.notes!.isNotEmpty)
              EventNotes(controller: _notesController, event: _event),
            const SizedBox(height: 24),
            EventActions(
              event: _event,
              onEdit: () => _navigateToEditScreen(context),
              onDelete: () => _confirmDelete(context),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _navigateToEditScreen(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => EventFormScreen(event: _event)),
    ).then(
          (_) => setState(() {
        _event = widget.event;
        _notesController.text = _event.notes ?? '';
      }),
    );
  }

  void _confirmDelete(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Delete Event'),
            content: Text('Delete "${_event.title}"?'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  context.read<TaskManagerCubit>().deleteTask(_event);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}

// Event Header Widget
class EventHeader extends StatelessWidget {
  final Task event;

  const EventHeader({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Get the scheduled task for this event (assuming it's the first one)
    final scheduledTask =
        event.scheduledTasks.isNotEmpty ? event.scheduledTasks.first : null;

    final startTime =
        scheduledTask?.startTime ??
        DateTime.fromMillisecondsSinceEpoch(event.deadline);
    final endTime =
        scheduledTask?.endTime ?? startTime.add(const Duration(hours: 1));

    final eventColor =
        event.color != null ? Color(event.color!) : CupertinoColors.activeBlue;

    return Container(
      padding: const EdgeInsets.all(EventScreenConstants.padding),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(EventScreenConstants.cornerRadius),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.1),
            blurRadius: EventScreenConstants.shadowBlurRadius,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: eventColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryTag(categoryName: event.category.name),
              const Spacer(),
              Icon(CupertinoIcons.calendar, size: 18, color: eventColor),
              const SizedBox(width: 4),
              Text(
                EventDateTimeFormatter.formatDate(startTime),
                style: theme.textTheme.textStyle.copyWith(
                  color:
                      isDarkMode
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(CupertinoIcons.time, size: 18, color: eventColor),
              const SizedBox(width: 4),
              Text(
                '${EventDateTimeFormatter.formatTime(startTime)} - ${EventDateTimeFormatter.formatTime(endTime)}',
                style: theme.textTheme.textStyle.copyWith(
                  color:
                      isDarkMode
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: eventColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  EventDateTimeFormatter.formatDuration(startTime, endTime),
                  style: theme.textTheme.textStyle.copyWith(color: eventColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Event Details Widget
class EventDetails extends StatelessWidget {
  final Task event;

  const EventDetails({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(EventScreenConstants.padding),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(EventScreenConstants.cornerRadius),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.1),
            blurRadius: EventScreenConstants.shadowBlurRadius,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Details',
            style: theme.textTheme.navTitleTextStyle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          if (event.location != null && event.location.toString().isNotEmpty)
            DetailItem(
              icon: CupertinoIcons.location,
              label: 'Location',
              value: event.location?.toString() ?? '',
              color: CupertinoColors.activeOrange,
            ),
          if (event.color != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.circle_fill,
                    size: 18,
                    color: Color(event.color!),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Color',
                    style: theme.textTheme.textStyle.copyWith(
                      color:
                          isDarkMode
                              ? CupertinoColors.white
                              : CupertinoColors.black,
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

// Detail Item Widget
class DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const DetailItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color:
                    isDarkMode
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey2,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color:
                    isDarkMode ? CupertinoColors.white : CupertinoColors.black,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Event Notes Widget
class EventNotes extends StatelessWidget {
  final TextEditingController controller;
  final Task event;

  const EventNotes({super.key, required this.controller, required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(EventScreenConstants.padding),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(EventScreenConstants.cornerRadius),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.1),
            blurRadius: EventScreenConstants.shadowBlurRadius,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: theme.textTheme.navTitleTextStyle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: controller,
            placeholder: 'Add notes about this event...',
            minLines: 3,
            maxLines: 5,
            padding: const EdgeInsets.all(10),
            style: theme.textTheme.textStyle,
            decoration: BoxDecoration(
              border: Border.all(color: theme.barBackgroundColor),
              borderRadius: BorderRadius.circular(8),
            ),
            onChanged: (value) {
              event.notes = value.isEmpty ? null : value;
              event.save();
            },
          ),
        ],
      ),
    );
  }
}

// Event Actions Widget
class EventActions extends StatelessWidget implements EventFormValidator {
  final Task event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EventActions({
    super.key,
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CupertinoButton(
          padding: EventScreenConstants.buttonPadding,
          color: CupertinoColors.activeBlue,
          onPressed: onEdit,
          child: const Text('Edit'),
        ),
        CupertinoButton(
          padding: EventScreenConstants.buttonPadding,
          color: CupertinoColors.destructiveRed,
          onPressed: onDelete,
          child: const Text('Delete'),
        ),
      ],
    );
  }

  @override
  bool validateForm(GlobalKey<FormState> formKey) {
    return formKey.currentState?.validate() ?? false;
  }

  @override
  bool validateTimes(DateTime startTime, DateTime endTime) {
    return endTime.isAfter(startTime);
  }
}

abstract class EventFormValidator {
  bool validateForm(GlobalKey<FormState> formKey);
  bool validateTimes(DateTime startTime, DateTime endTime);
}

abstract class EventFormDataHandler {
  void saveEvent(BuildContext context, Task event);
  String formatDateKey(DateTime date);
}

class EventFormController implements EventFormValidator, EventFormDataHandler {
  @override
  bool validateForm(GlobalKey<FormState> formKey) {
    return formKey.currentState?.validate() ?? false;
  }

  @override
  bool validateTimes(DateTime startTime, DateTime endTime) {
    return endTime.isAfter(startTime);
  }

  @override
  void saveEvent(BuildContext context, Task event) {
    // Implementation will be in the saveEvent method of the screen
  }

  @override
  String formatDateKey(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}

// Main EventEditScreen widget
class EventEditScreen extends StatefulWidget {
  final Task event;

  const EventEditScreen({super.key, required this.event});

  @override
  EventEditScreenState createState() => EventEditScreenState();
}

class EventEditScreenState extends State<EventEditScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();
  final _formController = EventFormController();

  late AnimationController _animationController;
  late Animation<double> _buttonScaleAnimation;

  late DateTime _selectedDate;
  late DateTime _startTime;
  late DateTime _endTime;
  int? _selectedColor;

  final List<Color> _colorOptions = [
    CupertinoColors.systemRed,
    CupertinoColors.systemOrange,
    CupertinoColors.systemYellow,
    CupertinoColors.systemGreen,
    CupertinoColors.systemBlue,
    CupertinoColors.systemPurple,
    CupertinoColors.systemGrey,
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Initialize controllers and variables with event data
    _titleController.text = widget.event.title;
    _notesController.text = widget.event.notes ?? '';
    _locationController.text = widget.event.location?.toString() ?? '';

    // Get the scheduled task for this event (assuming it's the first one)
    final scheduledTask =
        widget.event.scheduledTasks.isNotEmpty
            ? widget.event.scheduledTasks.first
            : null;

    // Initialize date and time
    _selectedDate = DateTime.fromMillisecondsSinceEpoch(widget.event.deadline);

    if (scheduledTask != null) {
      _startTime = scheduledTask.startTime;
      _endTime = scheduledTask.endTime;
    } else {
      _startTime = _selectedDate;
      _endTime = _startTime.add(const Duration(hours: 1));
    }

    _selectedColor = widget.event.color;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoFormTheme(context);
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Edit Event'),
        backgroundColor: CupertinoTheme.of(context).barBackgroundColor,
      ),
      child: SafeArea(
        bottom: false,
        child: EventEditContent(
          formKey: _formKey,
          titleController: _titleController,
          notesController: _notesController,
          locationController: _locationController,
          selectedDate: _selectedDate,
          startTime: _startTime,
          endTime: _endTime,
          selectedColor: _selectedColor,
          colorOptions: _colorOptions,
          buttonScaleAnimation: _buttonScaleAnimation,
          onDateChanged: (date) {
            setState(() {
              _selectedDate = date;
              // Update start and end times to maintain the same time on the new date
              _startTime = DateTime(
                date.year,
                date.month,
                date.day,
                _startTime.hour,
                _startTime.minute,
              );
              _endTime = DateTime(
                date.year,
                date.month,
                date.day,
                _endTime.hour,
                _endTime.minute,
              );
            });
          },
          onStartTimeChanged: (time) {
            setState(() {
              _startTime = time;
              // If end time is before start time, adjust it
              if (_endTime.isBefore(_startTime)) {
                _endTime = _startTime.add(const Duration(hours: 1));
              }
            });
          },
          onEndTimeChanged: (time) {
            setState(() {
              if (time.isAfter(_startTime)) {
                _endTime = time;
              } else {
                _showErrorDialog('End time must be after start time');
              }
            });
          },
          onColorSelected: (color) {
            setState(() => _selectedColor = color);
          },
          onSave: () {
            _animationController.forward().then(
              (_) => _animationController.reverse(),
            );
            _saveEvent(context);
          },
          theme: theme,
          isDarkMode: isDarkMode,
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  void _saveEvent(BuildContext context) {
    // Arrange - Validate form
    if (!_formController.validateForm(_formKey)) {
      _showErrorDialog('Please fill in all required fields.');
      return;
    }

    // Act - Validate times
    if (!_formController.validateTimes(_startTime, _endTime)) {
      _showErrorDialog('End time must be after start time.');
      return;
    }

    // Calculate estimated time in milliseconds
    final estimatedTime = _endTime.difference(_startTime).inMilliseconds;

    // Act - Update the event
    context.read<TaskManagerCubit>().editTask(
      task: widget.event,
      title: _titleController.text,
      priority: 0, // Events always have priority 0
      estimatedTime: estimatedTime,
      deadline: _endTime.millisecondsSinceEpoch,
      category: widget.event.category, // Keep the existing category (Event)
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      color: _selectedColor,
    );

    // Act - Update the scheduled task
    if (widget.event.scheduledTasks.isNotEmpty) {
      final scheduledTask = widget.event.scheduledTasks.first;
      scheduledTask.startTime = _startTime;
      scheduledTask.endTime = _endTime;

      // Save the updated task
      widget.event.save();

      // Update the day that contains this scheduled task
      final dateKey = _formController.formatDateKey(_startTime);
      final daysBox = Hive.box<Day>('scheduled_tasks');
      final day = daysBox.get(dateKey) ?? Day(day: dateKey);

      // Find and update the scheduled task in the day
      for (var i = 0; i < day.scheduledTasks.length; i++) {
        if (day.scheduledTasks[i].scheduledTaskId ==
            scheduledTask.scheduledTaskId) {
          day.scheduledTasks[i] = scheduledTask;
          break;
        }
      }

      daysBox.put(dateKey, day);
    }

    logInfo('Event updated: ${_titleController.text}');

    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(
        builder:
            (_) => const HomeScreen(initialIndex: 0, initialExpanded: false),
      ),
    );
  }
}

class EventEditContent extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController notesController;
  final TextEditingController locationController;
  final DateTime selectedDate;
  final DateTime startTime;
  final DateTime endTime;
  final int? selectedColor;
  final List<Color> colorOptions;
  final Animation<double> buttonScaleAnimation;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<DateTime> onStartTimeChanged;
  final ValueChanged<DateTime> onEndTimeChanged;
  final ValueChanged<int?> onColorSelected;
  final VoidCallback onSave;
  final CupertinoFormTheme theme;
  final bool isDarkMode;

  const EventEditContent({
    super.key,
    required this.formKey,
    required this.titleController,
    required this.notesController,
    required this.locationController,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.selectedColor,
    required this.colorOptions,
    required this.buttonScaleAnimation,
    required this.onDateChanged,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
    required this.onColorSelected,
    required this.onSave,
    required this.theme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormGroup(
              context,
              title: 'Event Details',
              children: [
                _buildTextField(
                  context,
                  controller: titleController,
                  placeholder: 'Event Name *',
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  prefixIcon: CupertinoIcons.pencil,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  context,
                  controller: notesController,
                  placeholder: 'Notes',
                  maxLines: 3,
                  prefixIcon: CupertinoIcons.doc_text,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  context,
                  controller: locationController,
                  placeholder: 'Location',
                  prefixIcon: CupertinoIcons.location,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildFormGroup(
              context,
              title: 'Date & Time',
              children: [
                Text(
                  'When is your event happening?',
                  style: theme.helperTextStyle,
                ),
                const SizedBox(height: 12),
                _buildSelectionButton(
                  context,
                  label: 'Date',
                  value: _formatDate(selectedDate),
                  onTap: () => _showDatePicker(context),
                  color: theme.primaryColor,
                  icon: CupertinoIcons.calendar,
                ),
                const SizedBox(height: 16),
                _buildSelectionButton(
                  context,
                  label: 'Start',
                  value: _formatTime(startTime),
                  onTap: () => _showTimePicker(context, isStart: true),
                  color: CupertinoColors.activeGreen,
                  icon: CupertinoIcons.time,
                ),
                const SizedBox(height: 16),
                _buildSelectionButton(
                  context,
                  label: 'End',
                  value: _formatTime(endTime),
                  onTap: () => _showTimePicker(context, isStart: false),
                  color: CupertinoColors.activeOrange,
                  icon: CupertinoIcons.time_solid,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildFormGroup(
              context,
              title: 'Appearance',
              children: [
                Text(
                  'Select a color for your event',
                  style: theme.helperTextStyle,
                ),
                const SizedBox(height: 12),
                _buildColorSelector(context),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: ScaleTransition(
                scale: buttonScaleAnimation,
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  onPressed: onSave,
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildFormGroup(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: CupertinoTheme.of(
            context,
          ).textTheme.navLargeTitleTextStyle.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: CupertinoTheme.of(context).textTheme.textStyle.color,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String placeholder,
    IconData? prefixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      maxLines: maxLines,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      prefix:
          prefixIcon != null
              ? Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(
                  prefixIcon,
                  size: 20,
                  color: CupertinoTheme.of(context).primaryColor,
                ),
              )
              : null,
      decoration: BoxDecoration(
        color:
            isDark
                ? CupertinoColors.systemGrey6.darkColor
                : CupertinoColors.systemGrey6.color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              isDark
                  ? CupertinoColors.systemGrey5.darkColor
                  : CupertinoColors.systemGrey4.color,
        ),
      ),
      style: CupertinoTheme.of(
        context,
      ).textTheme.textStyle.copyWith(fontSize: 16),
      placeholderStyle: TextStyle(
        color:
            isDark
                ? CupertinoColors.systemGrey2.darkColor
                : CupertinoColors.systemGrey2.color,
        fontSize: 16,
      ),
    );
  }

  Widget _buildSelectionButton(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onTap,
    required Color color,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: CupertinoTheme.of(context).textTheme.textStyle.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: CupertinoTheme.of(
                context,
              ).textTheme.textStyle.color!.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSelector(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: colorOptions.length + 1, // +1 for "No color" option
        itemBuilder: (context, index) {
          if (index == 0) {
            // "No color" option
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => onColorSelected(null),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isDarkMode
                            ? CupertinoColors.darkBackgroundGray
                            : CupertinoColors.white,
                    border: Border.all(
                      color:
                          selectedColor == null
                              ? CupertinoTheme.of(context).primaryColor
                              : CupertinoColors.systemGrey.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child:
                      selectedColor == null
                          ? Icon(
                            CupertinoIcons.checkmark,
                            color: CupertinoTheme.of(context).primaryColor,
                            size: 24,
                          )
                          : null,
                ),
              ),
            );
          }

          final color = colorOptions[index - 1];
          final colorValue = color.value;
          final isSelected = selectedColor == colorValue;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onColorSelected(colorValue),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(
                    color:
                        isSelected
                            ? CupertinoTheme.of(context).primaryColor
                            : CupertinoColors.systemGrey.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child:
                    isSelected
                        ? const Icon(
                          CupertinoIcons.checkmark,
                          color: CupertinoColors.white,
                          size: 24,
                        )
                        : null,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _showDatePicker(BuildContext context) async {
    DateTime? pickedDate;
    final now = DateTime.now();
    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            color: CupertinoTheme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime:
                        selectedDate.isBefore(now) ? now : selectedDate,
                    minimumDate: now,
                    onDateTimeChanged: (val) => pickedDate = val,
                  ),
                ),
                _buildPickerActions(
                  context,
                  onDone: () {
                    if (pickedDate != null) {
                      onDateChanged(pickedDate!);
                    }
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _showTimePicker(
    BuildContext context, {
    required bool isStart,
  }) async {
    Duration? pickedDuration;
    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            color: CupertinoTheme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hm,
                    initialTimerDuration: Duration(
                      hours: (isStart ? startTime : endTime).hour,
                      minutes: (isStart ? startTime : endTime).minute,
                    ),
                    onTimerDurationChanged:
                        (duration) => pickedDuration = duration,
                  ),
                ),
                _buildPickerActions(
                  context,
                  onDone: () {
                    if (pickedDuration != null) {
                      final time = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        pickedDuration!.inHours,
                        pickedDuration!.inMinutes % 60,
                      );

                      if (isStart) {
                        onStartTimeChanged(time);
                      } else {
                        onEndTimeChanged(time);
                      }
                    }
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildPickerActions(
    BuildContext context, {
    required VoidCallback onDone,
  }) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: CupertinoColors.systemGrey5.resolveFrom(context),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: CupertinoColors.systemGrey.resolveFrom(context),
                fontSize: 17,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: onDone,
            child: Text(
              'Done',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: CupertinoTheme.of(context).primaryColor,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
