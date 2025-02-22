// lib/screens/add_task_form.dart
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flowo_client/blocs/calendar/calendar_cubit.dart';
import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/screens/home_screen.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flowo_client/models/day.dart';
import 'package:flowo_client/utils/date_time_formatter.dart';

class AddTaskForm extends StatefulWidget {
  final DateTime? selectedDate;
  final Task? task;

  const AddTaskForm({super.key, this.selectedDate, this.task});

  @override
  AddTaskFormState createState() => AddTaskFormState();
}

class AddTaskFormState extends State<AddTaskForm> {
  // Instead of TabController, we store the current index.
  int _currentTabIndex = 0;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();

  late DateTime _selectedDate;
  late DateTime _startTime;
  DateTime? _endTime;
  String _selectedCategory = 'Brainstorm';
  String _priority = 'Normal';
  File? _image;
  List<Map<String, dynamic>> _frequency = [];
  final List<String> _categoryOptions = [
    'Brainstorm',
    'Design',
    'Workout',
    'Add'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _startTime = _selectedDate;

    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _notesController.text = widget.task!.notes ?? '';
      _selectedDate =
          DateTime.fromMillisecondsSinceEpoch(widget.task!.deadline);
      _startTime = DateTime.fromMillisecondsSinceEpoch(widget.task!.deadline);
      _endTime = DateTime.fromMillisecondsSinceEpoch(
          widget.task!.deadline + widget.task!.estimatedTime);
      _selectedCategory = widget.task!.category.name;
      _priority = _intToPriority(widget.task!.priority);
      _locationController.text = widget.task!.location?.toString() ?? '';
      _image = widget.task!.image != null ? File(widget.task!.image!) : null;
      _frequency = widget.task!.frequency
              ?.map((day) => {
                    // Use Day constructor with parameter "day" instead of name, start, end.
                    // If more fields are needed, update the Day model accordingly.
                    'day': day.day,
                  })
              .toList() ??
          [];
      if (!_categoryOptions.contains(_selectedCategory) &&
          _selectedCategory != 'Add') {
        _categoryOptions.insert(_categoryOptions.length - 1, _selectedCategory);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _intToPriority(int priority) {
    switch (priority) {
      case 0:
        return 'Low';
      case 2:
        return 'High';
      default:
        return 'Normal';
    }
  }

  int _mapPriorityToInt(String priority) {
    switch (priority) {
      case 'Low':
        return 0;
      case 'High':
        return 2;
      default:
        return 1;
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
  String _formatTime(DateTime? time) => time != null
      ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
      : 'Not set';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('New Item'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Replacing CupertinoFloatingTabBar with a segmented control.
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CupertinoSegmentedControl<int>(
                groupValue: _currentTabIndex,
                onValueChanged: (value) =>
                    setState(() => _currentTabIndex = value),
                children: const {
                  0: Padding(padding: EdgeInsets.all(8.0), child: Text('Task')),
                  1: Padding(
                      padding: EdgeInsets.all(8.0), child: Text('Event')),
                  2: Padding(
                      padding: EdgeInsets.all(8.0), child: Text('Habit')),
                },
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: _buildFormContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    if (_currentTabIndex == 0) return _buildTaskForm();
    if (_currentTabIndex == 1) return _buildEventForm();
    return _buildHabitForm();
  }

  Widget _buildTaskForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Task Details'),
        const SizedBox(height: 12),
        _buildTextField(
            controller: _titleController, placeholder: 'Task Name *'),
        const SizedBox(height: 12),
        _buildTextField(
            controller: _notesController, placeholder: 'Notes', maxLines: 3),
        const SizedBox(height: 20),
        _buildSectionTitle('Timing'),
        const SizedBox(height: 12),
        _buildDateButton(context),
        const SizedBox(height: 12),
        _buildTimeButton(context, isStart: true),
        const SizedBox(height: 12),
        _buildTimeButton(context, isStart: false),
        const SizedBox(height: 20),
        _buildSectionTitle('Category'),
        const SizedBox(height: 12),
        _buildSegmentedControl(
            options: _categoryOptions,
            value: _selectedCategory,
            onChanged: _handleCategoryChange),
        const SizedBox(height: 20),
        _buildSectionTitle('Priority'),
        const SizedBox(height: 12),
        _buildSegmentedControl(
          options: const ['Low', 'Normal', 'High'],
          value: _priority,
          onChanged: (value) => setState(() => _priority = value),
          selectedColor: CupertinoColors.systemOrange,
        ),
        const SizedBox(height: 32),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildEventForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Event Details'),
        const SizedBox(height: 12),
        _buildTextField(
            controller: _titleController, placeholder: 'Event Name *'),
        const SizedBox(height: 12),
        _buildTextField(
            controller: _notesController, placeholder: 'Notes', maxLines: 3),
        const SizedBox(height: 12),
        _buildTextField(
            controller: _locationController, placeholder: 'Location'),
        const SizedBox(height: 12),
        _buildImagePicker(),
        const SizedBox(height: 20),
        _buildSectionTitle('Timing'),
        const SizedBox(height: 12),
        _buildDateButton(context),
        const SizedBox(height: 12),
        _buildTimeButton(context, isStart: true),
        const SizedBox(height: 12),
        _buildTimeButton(context, isStart: false),
        const SizedBox(height: 20),
        _buildSectionTitle('Category'),
        const SizedBox(height: 12),
        _buildSegmentedControl(
            options: _categoryOptions,
            value: _selectedCategory,
            onChanged: _handleCategoryChange),
        const SizedBox(height: 20),
        _buildSectionTitle('Priority'),
        const SizedBox(height: 12),
        _buildSegmentedControl(
          options: const ['Low', 'Normal', 'High'],
          value: _priority,
          onChanged: (value) => setState(() => _priority = value),
          selectedColor: CupertinoColors.systemOrange,
        ),
        const SizedBox(height: 32),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildHabitForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Habit Details'),
        const SizedBox(height: 12),
        _buildTextField(
            controller: _titleController, placeholder: 'Habit Name *'),
        const SizedBox(height: 12),
        _buildTextField(
            controller: _notesController, placeholder: 'Notes', maxLines: 3),
        const SizedBox(height: 20),
        _buildSectionTitle('Timing'),
        const SizedBox(height: 12),
        _buildDateButton(context),
        const SizedBox(height: 12),
        _buildTimeButton(context, isStart: true),
        const SizedBox(height: 12),
        _buildTimeButton(context, isStart: false),
        const SizedBox(height: 20),
        _buildSectionTitle('Frequency'),
        const SizedBox(height: 12),
        _buildFrequencySelector(),
        const SizedBox(height: 20),
        _buildSectionTitle('Category'),
        const SizedBox(height: 12),
        _buildSegmentedControl(
            options: _categoryOptions,
            value: _selectedCategory,
            onChanged: _handleCategoryChange),
        const SizedBox(height: 20),
        _buildSectionTitle('Priority'),
        const SizedBox(height: 12),
        _buildSegmentedControl(
          options: const ['Low', 'Normal', 'High'],
          value: _priority,
          onChanged: (value) => setState(() => _priority = value),
          selectedColor: CupertinoColors.systemOrange,
        ),
        const SizedBox(height: 32),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    int maxLines = 1,
  }) {
    // Removed the validator parameter since CupertinoTextField does not support it.
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      maxLines: maxLines,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CupertinoColors.systemGrey4),
      ),
      style: const TextStyle(fontSize: 16),
      placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey2),
    );
  }

  Widget _buildDateButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDatePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Date',
                style:
                    TextStyle(fontSize: 16, color: CupertinoColors.systemBlue)),
            Text(_formatDate(_selectedDate),
                style: const TextStyle(
                    fontSize: 16, color: CupertinoColors.label)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton(BuildContext context, {required bool isStart}) {
    return GestureDetector(
      onTap: () => _showTimePicker(context, isStart: isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: (isStart
                  ? CupertinoColors.systemGreen
                  : CupertinoColors.systemOrange)
              .withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isStart ? 'Start Time' : 'End Time',
              style: TextStyle(
                  fontSize: 16,
                  color: isStart
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemOrange),
            ),
            Text(
              _formatTime(isStart ? _startTime : _endTime),
              style:
                  const TextStyle(fontSize: 16, color: CupertinoColors.label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl({
    required List<String> options,
    required String value,
    required ValueChanged<String> onChanged,
    Color selectedColor = CupertinoColors.activeBlue,
  }) {
    return CupertinoSegmentedControl<String>(
      children: {
        for (var item in options)
          item: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(item, style: const TextStyle(fontSize: 14)),
          ),
      },
      groupValue: options.contains(value) ? value : null,
      onValueChanged: onChanged,
      borderColor: CupertinoColors.systemGrey4,
      selectedColor: selectedColor,
      unselectedColor: CupertinoColors.systemGrey6,
      pressedColor: selectedColor.withOpacity(0.2),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CupertinoColors.systemGrey4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Image', style: TextStyle(fontSize: 16)),
            _image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_image!,
                        width: 50, height: 50, fit: BoxFit.cover))
                : const Icon(CupertinoIcons.photo,
                    color: CupertinoColors.systemGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return Column(
      children: [
        if (_frequency.isNotEmpty)
          ..._frequency.map((freq) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${freq['day']}'),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(CupertinoIcons.trash,
                          size: 20, color: CupertinoColors.systemRed),
                      onPressed: () => setState(() => _frequency.remove(freq)),
                    ),
                  ],
                ),
              )),
        const SizedBox(height: 8),
        CupertinoButton(
          color: CupertinoColors.systemBlue,
          child: const Text('Add Frequency'),
          onPressed: () => _showFrequencyDialog(context),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: CupertinoButton.filled(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        onPressed: _saveTask,
        child: const Text('Save',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    DateTime? pickedDate;
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                onDateTimeChanged: (val) => pickedDate = val,
              ),
            ),
            _buildPickerActions(context),
          ],
        ),
      ),
    );
    if (pickedDate != null && mounted) {
      setState(() => _selectedDate = pickedDate!);
    }
  }

  Future<void> _showTimePicker(BuildContext context,
      {required bool isStart}) async {
    Duration? pickedDuration;
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: CupertinoTimerPicker(
                mode: CupertinoTimerPickerMode.hm,
                initialTimerDuration: Duration(
                  hours: (isStart ? _startTime : _endTime ?? _startTime).hour,
                  minutes:
                      (isStart ? _startTime : _endTime ?? _startTime).minute,
                ),
                onTimerDurationChanged: (duration) => pickedDuration = duration,
              ),
            ),
            _buildPickerActions(context),
          ],
        ),
      ),
    );
    if (pickedDuration != null && mounted) {
      setState(() {
        final time = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          pickedDuration!.inHours,
          pickedDuration!.inMinutes % 60,
        );
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  Future<void> _showFrequencyDialog(BuildContext context) async {
    String? selectedDay;
    DateTime? freqStartTime;
    DateTime? freqEndTime;

    await showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add Frequency'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Select Day'),
            onPressed: () async {
              await showCupertinoModalPopup(
                context: context,
                builder: (context) => Container(
                  height: 300,
                  color: CupertinoColors.systemBackground,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: CupertinoPicker(
                          itemExtent: 32,
                          onSelectedItemChanged: (index) {
                            selectedDay = [
                              'Monday',
                              'Tuesday',
                              'Wednesday',
                              'Thursday',
                              'Friday',
                              'Saturday',
                              'Sunday'
                            ][index];
                          },
                          children: const [
                            Text('Monday'),
                            Text('Tuesday'),
                            Text('Wednesday'),
                            Text('Thursday'),
                            Text('Friday'),
                            Text('Saturday'),
                            Text('Sunday'),
                          ],
                        ),
                      ),
                      _buildPickerActions(context),
                    ],
                  ),
                ),
              );
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Set Start Time'),
            onPressed: () async {
              await showCupertinoModalPopup(
                context: context,
                builder: (context) => Container(
                  height: 300,
                  color: CupertinoColors.systemBackground,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: CupertinoTimerPicker(
                          mode: CupertinoTimerPickerMode.hm,
                          initialTimerDuration: const Duration(hours: 9),
                          onTimerDurationChanged: (duration) {
                            freqStartTime = DateTime(
                              _selectedDate.year,
                              _selectedDate.month,
                              _selectedDate.day,
                              duration.inHours,
                              duration.inMinutes % 60,
                            );
                          },
                        ),
                      ),
                      _buildPickerActions(context),
                    ],
                  ),
                ),
              );
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Set End Time'),
            onPressed: () async {
              await showCupertinoModalPopup(
                context: context,
                builder: (context) => Container(
                  height: 300,
                  color: CupertinoColors.systemBackground,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: CupertinoTimerPicker(
                          mode: CupertinoTimerPickerMode.hm,
                          initialTimerDuration: const Duration(hours: 10),
                          onTimerDurationChanged: (duration) {
                            freqEndTime = DateTime(
                              _selectedDate.year,
                              _selectedDate.month,
                              _selectedDate.day,
                              duration.inHours,
                              duration.inMinutes % 60,
                            );
                          },
                        ),
                      ),
                      _buildPickerActions(context),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Done'),
          onPressed: () {
            if (selectedDay != null &&
                freqStartTime != null &&
                freqEndTime != null &&
                mounted) {
              setState(() {
                _frequency.add({
                  'day': selectedDay!,
                  // Removed mapping for start and end since Day requires only a day.
                });
              });
              logInfo(
                  'Added frequency: $selectedDay, ${DateTimeFormatter.formatTime(freqStartTime!)} - ${DateTimeFormatter.formatTime(freqEndTime!)}');
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildPickerActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CupertinoButton(
          child: const Text('Cancel',
              style: TextStyle(color: CupertinoColors.systemGrey)),
          onPressed: () => Navigator.pop(context),
        ),
        CupertinoButton(
          child:
              const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Add Custom Category'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Category Name',
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Add'),
            onPressed: () {
              final newCategory = controller.text.trim();
              if (newCategory.isNotEmpty && mounted) {
                setState(() {
                  if (!_categoryOptions.contains(newCategory)) {
                    _categoryOptions.insert(
                        _categoryOptions.length - 1, newCategory);
                  }
                  _selectedCategory = newCategory;
                });
                logInfo('Custom category added: $newCategory');
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        setState(() => _image = File(pickedFile.path));
        logInfo('Image picked: ${pickedFile.path}');
      }
    } catch (e) {
      logError('Failed to pick image: $e');
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to pick image.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  void _handleCategoryChange(String value) {
    if (value == 'Add') {
      _showAddCategoryDialog(context);
    } else {
      setState(() => _selectedCategory = value);
    }
  }

  void _saveTask() {
    // Perform form validation manually if needed.
    if (_titleController.text.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Validation Error'),
          content: const Text('Task Name is required.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
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
    final endTime = _endTime != null
        ? DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day,
            _endTime!.hour, _endTime!.minute)
        : startTime.add(const Duration(minutes: 60));

    if (endTime.isBefore(startTime)) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Invalid Time'),
          content: const Text('End time must be after start time.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    final task = Task(
      id: widget.task?.id ?? UniqueKey().toString(),
      title: _titleController.text,
      priority: _mapPriorityToInt(_priority),
      deadline: startTime.millisecondsSinceEpoch,
      estimatedTime: endTime.difference(startTime).inMilliseconds,
      category: Category(name: _selectedCategory),
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      image: _image?.path,
      frequency: _currentTabIndex == 2
          ? _frequency
              .map((f) => Day(day: f['day'])) // Map using the correct parameter
              .toList()
          : null,
      subtasks: widget.task?.subtasks ?? [],
      scheduledTasks: widget.task?.scheduledTasks ?? [],
      isDone: widget.task?.isDone ?? false,
      order: widget.task?.order ?? 0,
      overdue: widget.task?.overdue ?? false,
    );

    final cubit = context.read<CalendarCubit>();
    widget.task != null ? cubit.updateTask(task) : cubit.addTask(task);
    Navigator.pushReplacement(
            context, CupertinoPageRoute(builder: (_) => const HomeScreen()))
        .then((_) => cubit.selectDate(startTime));
    logInfo(
        'Saved ${_currentTabIndex == 0 ? 'Task' : _currentTabIndex == 1 ? 'Event' : 'Habit'}: ${task.title}');
  }
}

// Placeholder Coordinates class (adjust based on your actual model)
class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({required this.latitude, required this.longitude});

  static Coordinates? fromString(String text) {
    final parts = text.split(',');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0].trim());
      final lon = double.tryParse(parts[1].trim());
      if (lat != null && lon != null) {
        return Coordinates(latitude: lat, longitude: lon);
      }
    }
    return null;
  }

  @override
  String toString() => '$latitude, $longitude';
}
