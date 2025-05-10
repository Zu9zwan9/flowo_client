import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/design/cupertino_form_theme.dart';
import 'package:flowo_client/design/cupertino_form_widgets.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/scheduled_task_type.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/utils/formatter/date_time_formatter.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flowo_client/utils/cupertino_hero_tag_resolver.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/user_settings.dart';
import '../home_screen.dart';

class EventFormScreen extends StatefulWidget {
  final DateTime? selectedDate;
  final Task? event;

  const EventFormScreen({super.key, this.selectedDate, this.event});

  @override
  EventFormScreenState createState() => EventFormScreenState();
}

class EventFormScreenState extends State<EventFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();

  // Notification settings
  int? _firstNotification = 5;
  int? _secondNotification = 0;

  late DateTime _startTime;
  late DateTime _endTime;
  late UserSettings _userSettings;
  int? _selectedColor;
  int _travelingTime = 0;

  final List<Color> _colorOptions = [
    const Color(0xFF4CAF50),
    const Color(0xFF2196F3),
    const Color(0xFFF44336),
    const Color(0xFFFF9800),
    const Color(0xFF9C27B0),
    const Color(0xFF795548),
    const Color(0xFF607D8B),
  ];

  late AnimationController _animationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _userSettings = context.read<TaskManagerCubit>().taskManager.userSettings;

    if (widget.event != null) {
      final event = widget.event!;
      _titleController.text = event.title;
      _notesController.text = event.notes ?? '';
      _locationController.text = event.location?.toString() ?? '';
      _firstNotification = event.firstNotification;
      _secondNotification = event.secondNotification;

      final scheduledTask =
          event.scheduledTasks.isNotEmpty ? event.scheduledTasks.first : null;
      _startTime =
          scheduledTask?.startTime ??
          DateTime.fromMillisecondsSinceEpoch(event.deadline);
      _endTime =
          scheduledTask?.endTime ?? _startTime.add(const Duration(hours: 1));
      _selectedColor = event.color;
      _travelingTime =
          event.scheduledTasks.isNotEmpty
              ? event.scheduledTasks.first.travelingTime
              : 0;
    } else {
      _startTime = widget.selectedDate ?? DateTime.now();
      _endTime = _startTime.add(const Duration(hours: 1));
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Validates all form fields and returns an error message if validation fails
  String? _validateForm() {
    // Check if title is empty
    if (_titleController.text.trim().isEmpty) {
      return 'Event name is required';
    }

    // Check if end time is before start time
    if (_endTime.isBefore(_startTime)) {
      return 'End time must be after start time';
    }

    // Check if start time is in the past
    final now = DateTime.now();
    if (_startTime.isBefore(now)) {
      return 'Start time cannot be in the past';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoFormTheme(context);
    return CupertinoPageScaffold(
      navigationBar:
          widget.event != null
              ? CupertinoHeroTagResolver.create(
                middle: Text('Edit Event'),
                uniqueIdentifier: 'edit-event-${widget.event!.id}',
              )
              : Navigator.canPop(context)
              ? CupertinoHeroTagResolver.create(
                middle: Text('Create Event'),
                uniqueIdentifier:
                    'create-event-${DateTime.now().millisecondsSinceEpoch}',
              )
              : null,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CupertinoFormTheme.horizontalSpacing),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CupertinoFormWidgets.formGroup(
                  context: context,
                  title: 'Event Details',
                  children: [
                    CupertinoFormWidgets.textField(
                      context: context,
                      controller: _titleController,
                      placeholder: 'Event Name *',
                      validator:
                          (value) => value!.trim().isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: CupertinoFormTheme.elementSpacing),
                    CupertinoFormWidgets.textField(
                      context: context,
                      controller: _notesController,
                      placeholder: 'Notes',
                      maxLines: 5,
                    ),
                    SizedBox(height: CupertinoFormTheme.elementSpacing),
                    CupertinoFormWidgets.textField(
                      context: context,
                      controller: _locationController,
                      placeholder: 'Location',
                    ),
                    SizedBox(height: CupertinoFormTheme.elementSpacing),
                  ],
                ),
                SizedBox(height: CupertinoFormTheme.sectionSpacing),
                CupertinoFormWidgets.formGroup(
                  context: context,
                  title: 'Time',
                  children: [
                    CupertinoFormWidgets.selectionButton(
                      context: context,
                      label: 'Starts',
                      value: DateTimeFormatter.formatDateTime(
                        _startTime,
                        dateFormat: _userSettings.dateFormat,
                        monthFormat: _userSettings.monthFormat,
                        is24HourFormat: _userSettings.is24HourFormat,
                      ),
                      onTap: () => _showDateTimePicker(context, isStart: true),
                      color: theme.primaryColor,
                      icon: CupertinoIcons.calendar,
                    ),
                    SizedBox(height: CupertinoFormTheme.elementSpacing),
                    CupertinoFormWidgets.selectionButton(
                      context: context,
                      label: 'Ends',
                      value: DateTimeFormatter.formatDateTime(
                        _endTime,
                        dateFormat: _userSettings.dateFormat,
                        monthFormat: _userSettings.monthFormat,
                        is24HourFormat: _userSettings.is24HourFormat,
                      ),
                      onTap: () => _showDateTimePicker(context, isStart: false),
                      color: theme.accentColor,
                      icon: CupertinoIcons.calendar,
                    ),
                  ],
                ),
                SizedBox(height: CupertinoFormTheme.sectionSpacing),
                CupertinoFormWidgets.formGroup(
                  context: context,
                  title: 'Event Color',
                  children: [
                    Text(
                      'Select a color for your event',
                      style: theme.helperTextStyle,
                    ),
                    SizedBox(height: CupertinoFormTheme.smallSpacing),
                    CupertinoFormWidgets.colorPicker(
                      context: context,
                      colors: _colorOptions,
                      selectedColor: _selectedColor,
                      onColorSelected:
                          (color) => setState(() => _selectedColor = color),
                    ),
                  ],
                ),
                SizedBox(height: CupertinoFormTheme.sectionSpacing),
                CupertinoFormWidgets.formGroup(
                  context: context,
                  title: 'Traveling Time',
                  children: [
                    Text(
                      'Optional time needed for travel to the event location',
                      style: theme.helperTextStyle,
                    ),
                    SizedBox(height: CupertinoFormTheme.smallSpacing),
                    CupertinoFormWidgets.selectionButton(
                      context: context,
                      label: 'Duration',
                      value:
                          '${(_travelingTime ~/ 3600000).toString().padLeft(2, '0')}h ${((_travelingTime % 3600000) ~/ 60000).toString().padLeft(2, '0')}m',
                      onTap: () async {
                        final duration =
                            await CupertinoFormWidgets.showDurationPicker(
                              context: context,
                              initialHours: _travelingTime ~/ 3600000,
                              initialMinutes:
                                  (_travelingTime % 3600000) ~/ 60000,
                              maxHours: 12,
                            );
                        if (mounted) {
                          setState(() {
                            _travelingTime = duration;
                            // Immediate validation after changing traveling time
                            final error = _validateForm();
                            if (error != null && error.contains('Traveling')) {
                              showCupertinoDialog(
                                context: context,
                                builder:
                                    (context) => CupertinoAlertDialog(
                                      title: const Text('Traveling Time Error'),
                                      content: Text(error),
                                      actions: [
                                        CupertinoDialogAction(
                                          child: const Text('OK'),
                                          onPressed:
                                              () => Navigator.pop(context),
                                        ),
                                      ],
                                    ),
                              );
                              _travelingTime = 0; // Reset if invalid
                            }
                          });
                        }
                      },
                      color: theme.accentColor,
                      icon: CupertinoIcons.timer,
                    ),
                  ],
                ),
                SizedBox(height: CupertinoFormTheme.sectionSpacing),
                CupertinoFormWidgets.formGroup(
                  context: context,
                  title: 'Notification Settings',
                  children: [
                    CupertinoFormWidgets.selectionButton(
                      context: context,
                      label: 'Alert',
                      value: _formatNotificationTime(_firstNotification),
                      onTap: () => _showNotificationTimePicker(context, true),
                      icon: CupertinoIcons.time,
                    ),
                    SizedBox(height: CupertinoFormTheme.elementSpacing),
                    CupertinoFormWidgets.selectionButton(
                      context: context,
                      label: 'Second Alert',
                      value: _formatNotificationTime(_secondNotification),
                      onTap: () => _showNotificationTimePicker(context, false),
                      icon: CupertinoIcons.time,
                    ),
                  ],
                ),
                SizedBox(height: CupertinoFormTheme.largeSpacing),
                ScaleTransition(
                  scale: _buttonScaleAnimation,
                  child: CupertinoFormWidgets.primaryButton(
                    context: context,
                    text: widget.event != null ? 'Save Changes' : 'Save Event',
                    onPressed: () {
                      _animationController.forward().then(
                        (_) => _animationController.reverse(),
                      );
                      _saveEvent(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Shows date picker with validation
  Future<void> _showDateTimePicker(
    BuildContext context, {
    required bool isStart,
  }) async {
    final now = DateTime.now();
    DateTime initialDateTime = isStart ? _startTime : _endTime;
    if (initialDateTime.isBefore(now)) initialDateTime = now;

    DateTime? selectedDateTime = initialDateTime;

    final pickedDateTime = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            color: CupertinoTheme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () => Navigator.pop(context, selectedDateTime),
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime,
                    initialDateTime: initialDateTime,
                    minimumDate: now,
                    maximumDate: DateTime.now().add(const Duration(days: 730)),
                    use24hFormat: _userSettings.is24HourFormat,
                    onDateTimeChanged:
                        (dateTime) => selectedDateTime = dateTime,
                  ),
                ),
              ],
            ),
          ),
    );

    if (pickedDateTime != null && mounted) {
      setState(() {
        if (isStart) {
          _startTime = pickedDateTime;
          if (_endTime.isBefore(_startTime)) {
            _endTime = _startTime.add(const Duration(hours: 1));
          }
        } else {
          _endTime = pickedDateTime;
        }

        // Immediate validation after changing time
        final error = _validateForm();
        if (error != null && error.contains('time')) {
          showCupertinoDialog(
            context: context,
            builder:
                (context) => CupertinoAlertDialog(
                  title: const Text('Time Error'),
                  content: Text(error),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('OK'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
          );
          if (isStart) {
            _startTime = now;
            _endTime = _startTime.add(const Duration(hours: 1));
          } else {
            _endTime = _startTime.add(const Duration(hours: 1));
          }
        }
      });
    }
  }

  String _formatNotificationTime(int? minutes) {
    if (minutes == null) {
      return 'None';
    }

    switch (minutes) {
      case 0:
        return 'At event time';
      case 1:
        return '1 minute before';
      case 5:
        return '5 minutes before';
      case 15:
        return '15 minutes before';
      case 30:
        return '30 minutes before';
      case 60:
        return '1 hour before';
      case 120:
        return '2 hours before';
      case 1440:
        return '1 day before';
      case 2880:
        return '2 days before';
      case 10080:
        return '1 week before';
      default:
        if (minutes < 60) {
          return '$minutes minutes before';
        } else if (minutes < 1440) {
          final hours = minutes ~/ 60;
          final mins = minutes % 60;

          if (mins == 0) {
            return '$hours hours before';
          } else {
            return '$hours hours $mins minutes before';
          }
        } else {
          final days = minutes ~/ 1440;
          return '$days days before';
        }
    }
  }

  Future<void> _showNotificationTimePicker(
    BuildContext context,
    bool isFirstNotification,
  ) async {
    // Define different notification time options for first and second alerts
    final List<int?> timeOptions = [
      null,
      0,
      5,
      15,
      30,
      60,
      120,
      1440,
      2880,
      10080,
    ];

    // Get current value and find its index
    final int? currentValue =
        isFirstNotification ? _firstNotification : _secondNotification;
    final int initialIndex =
        timeOptions.contains(currentValue)
            ? timeOptions.indexOf(currentValue)
            : 0;

    await showCupertinoModalPopup<void>(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            color: CupertinoTheme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(
                      initialItem: initialIndex,
                    ),
                    onSelectedItemChanged: (index) {
                      if (mounted) {
                        setState(() {
                          if (isFirstNotification) {
                            _firstNotification = timeOptions[index];
                          } else {
                            _secondNotification = timeOptions[index];
                          }
                        });
                      }
                    },
                    children:
                        timeOptions
                            .map((time) => Text(_formatNotificationTime(time)))
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<bool?> _showOverlapResolutionDialog(
    BuildContext context,
    List<ScheduledTask> overlappingTasks,
    bool isEdit,
  ) async {
    final taskManagerCubit = context.read<TaskManagerCubit>();

    // Get parent tasks for all overlapping tasks
    final overlappingParentTasks = <Task>[];
    for (var scheduledTask in overlappingTasks) {
      final parentTask = scheduledTask.parentTask;
      if (parentTask != null && !overlappingParentTasks.contains(parentTask)) {
        overlappingParentTasks.add(parentTask);
      }
    }

    // Format the list of overlapping tasks for display
    final overlappingTasksText = overlappingParentTasks
        .map((task) {
          final scheduledTask = task.scheduledTasks.firstWhere(
            (st) => overlappingTasks.any(
              (ot) => ot.scheduledTaskId == st.scheduledTaskId,
            ),
            orElse:
                () => overlappingTasks.firstWhere(
                  (ot) => ot.parentTaskId == task.id,
                ),
          );

          final startTime = scheduledTask.startTime;
          final endTime = scheduledTask.endTime;
          final formattedStart =
              '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
          final formattedEnd =
              '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

          String taskType = 'Task';
          if (scheduledTask.type == ScheduledTaskType.timeSensitive) {
            taskType = 'Event';
          } else if (scheduledTask.type == ScheduledTaskType.rest) {
            taskType = 'Break';
          } else if (scheduledTask.type == ScheduledTaskType.mealBreak) {
            taskType = 'Meal Break';
          } else if (scheduledTask.type == ScheduledTaskType.sleep) {
            taskType = 'Sleep Time';
          } else if (scheduledTask.type == ScheduledTaskType.freeTime) {
            taskType = 'Free Time';
          }

          return '• ${task.title} ($taskType, $formattedStart-$formattedEnd)';
        })
        .join('\n');

    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        final primaryColor = CupertinoTheme.of(context).primaryColor;
        final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;

        return CupertinoAlertDialog(
          title: Text(
            'Schedule Conflict',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This ${isEdit ? 'edit' : 'new event'} overlaps with:',
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 8),
              Text(overlappingTasksText, style: TextStyle(color: textColor)),
              const SizedBox(height: 12),
              Text(
                'What would you like to do?',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              isDestructiveAction: true,
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, true),
              isDefaultAction: true,
              child: const Text('Override Conflicts'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveEvent(BuildContext context) async {
    final validationError = _validateForm();

    if (validationError != null) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Validation Error'),
              content: Text(validationError),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
      return;
    }

    final taskManagerCubit = context.read<TaskManagerCubit>();
    List<ScheduledTask> overlappingTasks = [];

    if (widget.event != null) {
      // Editing existing event
      overlappingTasks = taskManagerCubit.editEvent(
        task: widget.event!,
        title: _titleController.text.trim(),
        start: _startTime,
        end: _endTime,
        location:
            _locationController.text.isNotEmpty
                ? _locationController.text.trim()
                : null,
        notes:
            _notesController.text.isNotEmpty
                ? _notesController.text.trim()
                : null,
        color: _selectedColor,
        travelingTime: _travelingTime,
        firstNotification: _firstNotification,
        secondNotification: _secondNotification,
      );
    } else {
      // Creating new event
      overlappingTasks = taskManagerCubit.createEvent(
        title: _titleController.text.trim(),
        start: _startTime,
        end: _endTime,
        location:
            _locationController.text.isNotEmpty
                ? _locationController.text.trim()
                : null,
        notes:
            _notesController.text.isNotEmpty
                ? _notesController.text.trim()
                : null,
        color: _selectedColor,
        travelingTime: _travelingTime,
        firstNotification: _firstNotification,
        secondNotification: _secondNotification,
      );
    }

    // If there are overlapping tasks, show the resolution dialog
    if (overlappingTasks.isNotEmpty) {
      logDebug(overlappingTasks.first.toString());

      final shouldOverride = await _showOverlapResolutionDialog(
        context,
        overlappingTasks,
        widget.event != null,
      );

      if (shouldOverride == true) {
        // User chose to override conflicts
        if (widget.event != null) {
          // Editing existing event with override
          taskManagerCubit.editEvent(
            task: widget.event!,
            title: _titleController.text.trim(),
            start: _startTime,
            end: _endTime,
            location:
                _locationController.text.isNotEmpty
                    ? _locationController.text.trim()
                    : null,
            notes:
                _notesController.text.isNotEmpty
                    ? _notesController.text.trim()
                    : null,
            color: _selectedColor,
            travelingTime: _travelingTime,
            firstNotification: _firstNotification,
            secondNotification: _secondNotification,
            overrideOverlaps: true,
          );
        } else {
          // Creating new event with override
          taskManagerCubit.createEvent(
            title: _titleController.text.trim(),
            start: _startTime,
            end: _endTime,
            location:
                _locationController.text.isNotEmpty
                    ? _locationController.text.trim()
                    : null,
            notes:
                _notesController.text.isNotEmpty
                    ? _notesController.text.trim()
                    : null,
            color: _selectedColor,
            travelingTime: _travelingTime,
            firstNotification: _firstNotification,
            secondNotification: _secondNotification,
            overrideOverlaps: true,
          );
        }

        // Close the form screen after successful save with override
        if (mounted) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        }
      }
      // If shouldOverride is false or null, do nothing (user canceled)
      return;
    }

    // No overlaps, close the form screen after successful save
    if (mounted) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }
}
