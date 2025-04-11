import 'dart:math';

import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/design/cupertino_form_theme.dart';
import 'package:flowo_client/design/cupertino_form_widgets.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/screens/home_screen.dart';
import 'package:flowo_client/utils/formatter/date_time_formatter.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/notification_type.dart';
import '../../models/user_settings.dart';
import '../../services/notification/test_notification_service.dart';

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
  final NotiService _notiService = NotiService();

  late DateTime _startTime;
  late DateTime _endTime;
  late UserSettings _userSettings;
  int? _selectedColor;
  int _travelingTime = 0;

  // Notification settings
  late NotificationType _selectedNotificationType;
  late int _notificationTime; // Time in minutes before the event start
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
              ? event.scheduledTasks.first.travelingTime ?? 0
              : 0;

      // Initialize notification settings from event if available
      if (event.notificationType != null) {
        _selectedNotificationType = event.notificationType!;
      } else {
        _selectedNotificationType = _userSettings.defaultNotificationType;
      }

      if (event.notificationTime != null) {
        _notificationTime = event.notificationTime!;
      } else {
        _notificationTime = 30; // Default: 30 minutes before event start
      }
    } else {
      _startTime = widget.selectedDate ?? DateTime.now();
      _endTime = _startTime.add(const Duration(hours: 1));

      // Initialize with default notification settings
      _selectedNotificationType = _userSettings.defaultNotificationType;
      _notificationTime = 30; // Default: 30 minutes before event start
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
              ? CupertinoNavigationBar(middle: Text('Edit Event'))
              : Navigator.canPop(context)
              ? CupertinoNavigationBar(middle: Text('Create Event'))
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
                      label: 'Notification Type',
                      value: _getNotificationTypeLabel(
                        _selectedNotificationType,
                      ),
                      onTap: () => _showNotificationTypePicker(context),
                      color: theme.primaryColor,
                      icon: CupertinoIcons.bell,
                    ),
                    SizedBox(height: CupertinoFormTheme.elementSpacing),
                    CupertinoFormWidgets.selectionButton(
                      context: context,
                      label: 'Notification Time',
                      value: _formatNotificationTime(_notificationTime),
                      onTap: () => _showNotificationTimePicker(context),
                      color: theme.accentColor,
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

  // Saves the event after validation
  // Helper methods for notification settings
  String _getNotificationTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.push:
        return 'Push Notification';
      case NotificationType.disabled:
        return 'Disabled';
      default:
        return 'Unknown';
    }
  }

  String _formatNotificationTime(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes before';
    } else if (minutes == 60) {
      return '1 hour before';
    } else if (minutes % 60 == 0) {
      return '${minutes ~/ 60} hours before';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '$hours hours $mins minutes before';
    }
  }

  Future<void> _showNotificationTypePicker(BuildContext context) async {
    final pickedType = await showCupertinoModalPopup<NotificationType>(
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
                      onPressed:
                          () =>
                              Navigator.pop(context, _selectedNotificationType),
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
                      initialItem: NotificationType.values.indexOf(
                        _selectedNotificationType,
                      ),
                    ),
                    onSelectedItemChanged: (index) {
                      if (mounted) {
                        setState(() {
                          _selectedNotificationType =
                              NotificationType.values[index];
                        });
                      }
                    },
                    children:
                        NotificationType.values
                            .map(
                              (type) => Text(_getNotificationTypeLabel(type)),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
    );

    if (pickedType != null && mounted) {
      setState(() {
        _selectedNotificationType = pickedType;
      });
    }
  }

  Future<void> _showNotificationTimePicker(BuildContext context) async {
    // Define common notification time options in minutes
    final List<int> timeOptions = [5, 15, 30, 60, 120, 180, 360, 720, 1440];

    // Find the closest option to the current notification time
    int initialIndex = 0;
    int minDifference = (timeOptions[0] - _notificationTime).abs();

    for (int i = 1; i < timeOptions.length; i++) {
      final difference = (timeOptions[i] - _notificationTime).abs();
      if (difference < minDifference) {
        minDifference = difference;
        initialIndex = i;
      }
    }

    final pickedTime = await showCupertinoModalPopup<int>(
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
                      onPressed:
                          () => Navigator.pop(context, _notificationTime),
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
                          _notificationTime = timeOptions[index];
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

    if (pickedTime != null && mounted) {
      setState(() {
        _notificationTime = pickedTime;
      });
    }
  }

  void _saveEvent(BuildContext context) {
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
    if (widget.event != null) {
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
        notificationType: _selectedNotificationType,
        notificationTime: _notificationTime,
      );
      logInfo('Event updated: ${_titleController.text}');
    } else {
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
        notificationType: _selectedNotificationType,
        notificationTime: _notificationTime,
      );

      _notiService.scheduleNotification(
        id: Random().nextInt(2147483647),
        title: _titleController.text,
        body: 'Test Notification',
        hour: _startTime.hour,
        minute: _startTime.minute - (_notificationTime),
      );
      logInfo(
        'Scheduled Notification: ${_titleController.text} for hour: ${_startTime.hour}, minute: ${_startTime.minute - _notificationTime}',
      );

      logInfo('Saved Event: ${_titleController.text}');
    }

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
