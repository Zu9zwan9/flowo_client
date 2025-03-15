import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/tasks_controller/task_manager_cubit.dart';
import '../blocs/tasks_controller/tasks_controller_cubit.dart';
import '../design/cupertino_form_theme.dart';
import '../design/cupertino_form_widgets.dart';
import '../screens/home_screen.dart';
import '../utils/logger.dart';

class AddEventPage extends StatefulWidget {
  final DateTime? selectedDate;

  const AddEventPage({super.key, this.selectedDate});

  @override
  AddEventPageState createState() => AddEventPageState();
}

class AddEventPageState extends State<AddEventPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();

  late DateTime _selectedDate;
  late DateTime _startTime;
  DateTime? _endTime;
  File? _image;
  int? _selectedColor;
  int _travelingTime = 0;
  final List<Color> _colorOptions = [
    const Color(0xFF4CAF50), // Green
    const Color(0xFF2196F3), // Blue
    const Color(0xFFF44336), // Red
    const Color(0xFFFF9800), // Orange
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF795548), // Brown
    const Color(0xFF607D8B), // Blue Grey
  ];

  late AnimationController _animationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _startTime = _selectedDate;

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
    return CupertinoPageScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CupertinoFormTheme.horizontalSpacing),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CupertinoFormWidgets.formGroup(
                  title: 'Event Details',
                  children: [
                    CupertinoFormWidgets.textField(
                      controller: _titleController,
                      placeholder: 'Event Name *',
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: CupertinoFormTheme.elementSpacing),
                    CupertinoFormWidgets.textField(
                      controller: _notesController,
                      placeholder: 'Notes',
                      maxLines: 3,
                    ),
                    SizedBox(height: CupertinoFormTheme.elementSpacing),
                    CupertinoFormWidgets.textField(
                      controller: _locationController,
                      placeholder: 'Location',
                    ),
                    SizedBox(height: CupertinoFormTheme.elementSpacing),
                    CupertinoFormWidgets.imagePicker(
                      image: _image,
                      onPickImage: _pickImage,
                    ),
                  ],
                ),
                SizedBox(height: CupertinoFormTheme.sectionSpacing),
                CupertinoFormWidgets.formGroup(
                  title: 'Event Color',
                  children: [
                    Text(
                      'Select a color for your event',
                      style: CupertinoFormTheme.helperTextStyle,
                    ),
                    SizedBox(height: CupertinoFormTheme.smallSpacing),
                    CupertinoFormWidgets.colorPicker(
                      colors: _colorOptions,
                      selectedColor: _selectedColor,
                      onColorSelected:
                          (color) => setState(() => _selectedColor = color),
                    ),
                  ],
                ),
                SizedBox(height: CupertinoFormTheme.sectionSpacing),
                CupertinoFormWidgets.formGroup(
                  title: 'Traveling Time',
                  children: [
                    Text(
                      'Optional time needed for travel to the event location',
                      style: CupertinoFormTheme.helperTextStyle,
                    ),
                    SizedBox(height: CupertinoFormTheme.smallSpacing),
                    CupertinoFormWidgets.selectionButton(
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
                        if (mounted) setState(() => _travelingTime = duration);
                      },
                      color: CupertinoFormTheme.accentColor,
                      icon: CupertinoIcons.timer,
                    ),
                  ],
                ),
                SizedBox(height: CupertinoFormTheme.sectionSpacing),
                CupertinoFormWidgets.formGroup(
                  title: 'Start',
                  children: [
                    CupertinoFormWidgets.selectionButton(
                      label: 'Date',
                      value: CupertinoFormTheme.formatDate(_selectedDate),
                      onTap: () => _showDatePicker(context, isStart: true),
                      color: CupertinoFormTheme.primaryColor,
                      icon: CupertinoIcons.calendar,
                    ),
                    SizedBox(height: CupertinoFormTheme.elementSpacing),
                    CupertinoFormWidgets.selectionButton(
                      label: 'Time',
                      value: CupertinoFormTheme.formatTime(_startTime),
                      onTap: () => _showTimePicker(context, isStart: true),
                      color: CupertinoFormTheme.secondaryColor,
                      icon: CupertinoIcons.time,
                    ),
                  ],
                ),
                SizedBox(height: CupertinoFormTheme.sectionSpacing),
                CupertinoFormWidgets.formGroup(
                  title: 'End',
                  children: [
                    CupertinoFormWidgets.selectionButton(
                      label: 'Date',
                      value: CupertinoFormTheme.formatDate(
                        _endTime ?? _selectedDate,
                      ),
                      onTap: () => _showDatePicker(context, isStart: false),
                      color: CupertinoFormTheme.primaryColor,
                      icon: CupertinoIcons.calendar,
                    ),
                    SizedBox(height: CupertinoFormTheme.elementSpacing),
                    CupertinoFormWidgets.selectionButton(
                      label: 'Time',
                      value: CupertinoFormTheme.formatTime(_endTime),
                      onTap: () => _showTimePicker(context, isStart: false),
                      color: CupertinoFormTheme.accentColor,
                      icon: CupertinoIcons.time_solid,
                    ),
                  ],
                ),
                SizedBox(height: CupertinoFormTheme.largeSpacing),
                ScaleTransition(
                  scale: _buttonScaleAnimation,
                  child: CupertinoFormWidgets.primaryButton(
                    text: 'Save Event',
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

  Future<void> _showDatePicker(
    BuildContext context, {
    required bool isStart,
  }) async {
    final pickedDate = await CupertinoFormWidgets.showDatePicker(
      context: context,
      initialDate: isStart ? _selectedDate : (_endTime ?? _startTime),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        if (isStart) {
          _selectedDate = pickedDate;
          _startTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            _startTime.hour,
            _startTime.minute,
          );
        } else {
          _endTime =
              _endTime != null
                  ? DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    _endTime!.hour,
                    _endTime!.minute,
                  )
                  : DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    _startTime.hour + 1,
                    _startTime.minute,
                  );
        }
      });
    }
  }

  Future<void> _showTimePicker(
    BuildContext context, {
    required bool isStart,
  }) async {
    final pickedTime = await CupertinoFormWidgets.showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : (_endTime ?? _startTime),
    );
    if (pickedTime != null && mounted) {
      setState(() {
        if (isStart) {
          _startTime = pickedTime;
        } else {
          _endTime = pickedTime;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final image = await CupertinoFormWidgets.pickImage(context);
    if (image != null && mounted) {
      setState(() => _image = image);
      logInfo('Image picked: ${image.path}');
    }
  }

  void _saveEvent(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
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

    final startTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endTime =
        _endTime != null
            ? DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              _endTime!.hour,
              _endTime!.minute,
            )
            : startTime.add(const Duration(minutes: 60));

    if (endTime.isBefore(startTime)) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
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

    context.read<TaskManagerCubit>().createEvent(
      title: _titleController.text,
      start: startTime,
      end: endTime,
      location:
          _locationController.text.isNotEmpty ? _locationController.text : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      color: _selectedColor,
      travelingTime: _travelingTime,
    );

    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (_) => const HomeScreen()),
    ).then((_) => context.read<CalendarCubit>().selectDate(startTime));
    logInfo('Saved Event: ${_titleController.text}');
  }
}
