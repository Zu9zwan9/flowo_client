import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/design/cupertino_form_theme.dart';
import 'package:flowo_client/design/cupertino_form_widgets.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/screens/home_screen.dart';
import 'package:flowo_client/utils/formatter/date_time_formatter.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/user_settings.dart';

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
      // Редактирование существующего события
      final event = widget.event!;
      _titleController.text = event.title;
      _notesController.text = event.notes ?? '';
      _locationController.text = event.location?.toString() ?? '';

      final scheduledTask = event.scheduledTasks.isNotEmpty ? event.scheduledTasks.first : null;
      _startTime = scheduledTask?.startTime ?? DateTime.fromMillisecondsSinceEpoch(event.deadline);
      _endTime = scheduledTask?.endTime ?? _startTime.add(const Duration(hours: 1));
      _selectedColor = event.color;
      _travelingTime = event.scheduledTasks.first.travelingTime ?? 0;
    } else {
      // Создание нового события
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

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoFormTheme(context);
    return CupertinoPageScaffold(
      navigationBar: widget.event != null
          ? CupertinoNavigationBar(
              middle: Text('Edit Event'),
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
                      validator: (value) => value!.isEmpty ? 'Required' : null,
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
                      onColorSelected: (color) => setState(() => _selectedColor = color),
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
                      value: '${(_travelingTime ~/ 3600000).toString().padLeft(2, '0')}h ${((_travelingTime % 3600000) ~/ 60000).toString().padLeft(2, '0')}m',
                      onTap: () async {
                        final duration = await CupertinoFormWidgets.showDurationPicker(
                          context: context,
                          initialHours: _travelingTime ~/ 3600000,
                          initialMinutes: (_travelingTime % 3600000) ~/ 60000,
                          maxHours: 12,
                        );
                        if (mounted) setState(() => _travelingTime = duration);
                      },
                      color: theme.accentColor,
                      icon: CupertinoIcons.timer,
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

  Future<void> _showDateTimePicker(BuildContext context, {required bool isStart}) async {
    final now = DateTime.now();
    DateTime initialDateTime = isStart ? _startTime : _endTime;
    if (initialDateTime.isBefore(now)) initialDateTime = now;

    DateTime? selectedDateTime = initialDateTime;

    final pickedDateTime = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) => Container(
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
                onDateTimeChanged: (dateTime) => selectedDateTime = dateTime,
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
      });
    }
  }

  void _saveEvent(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Validation Error'),
          content: const Text('Please fill in all required fields.'),
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

    if (_endTime.isBefore(_startTime)) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Invalid Time'),
          content: const Text('End time must be after start time.'),
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
        title: _titleController.text,
        start: _startTime,
        end: _endTime,
        location: _locationController.text.isNotEmpty ? _locationController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        color: _selectedColor,
        travelingTime: _travelingTime,
      );
      logInfo('Event updated: ${_titleController.text}');
    } else {
      taskManagerCubit.createEvent(
        title: _titleController.text,
        start: _startTime,
        end: _endTime,
        location: _locationController.text.isNotEmpty ? _locationController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        color: _selectedColor,
        travelingTime: _travelingTime,
      );
      logInfo('Saved Event: ${_titleController.text}');
    }

    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (_) => const HomeScreen()),
    ).then((_) => context.read<TaskManagerCubit>().state);
  }
}
