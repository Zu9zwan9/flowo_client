import 'package:flowo_client/models/day.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/screens/home_screen.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../blocs/tasks_controller/task_manager_cubit.dart';

class EventEditScreen extends StatefulWidget {
  final Task event;

  const EventEditScreen({super.key, required this.event});

  @override
  EventEditScreenState createState() => EventEditScreenState();
}

class EventEditScreenState extends State<EventEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();

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
      _endTime = _selectedDate.add(const Duration(hours: 1));
    }

    _selectedColor = widget.event.color;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Edit Event')),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Event Details'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _titleController,
                  placeholder: 'Event Name *',
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _notesController,
                  placeholder: 'Notes',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _locationController,
                  placeholder: 'Location',
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Date'),
                const SizedBox(height: 12),
                _buildDateButton(context),
                const SizedBox(height: 20),
                _buildSectionTitle('Start Time'),
                const SizedBox(height: 12),
                _buildTimeButton(context, isStart: true),
                const SizedBox(height: 20),
                _buildSectionTitle('End Time'),
                const SizedBox(height: 12),
                _buildTimeButton(context, isStart: false),
                const SizedBox(height: 20),
                _buildSectionTitle('Color'),
                const SizedBox(height: 12),
                _buildColorSelector(),
                const SizedBox(height: 32),
                _buildSaveButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: CupertinoColors.label,
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) => CupertinoTextField(
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

  Widget _buildDateButton(BuildContext context) => GestureDetector(
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
          const Text(
            'Date',
            style: TextStyle(fontSize: 16, color: CupertinoColors.systemBlue),
          ),
          Text(
            _formatDate(_selectedDate),
            style: const TextStyle(fontSize: 16, color: CupertinoColors.label),
          ),
        ],
      ),
    ),
  );

  Widget _buildTimeButton(BuildContext context, {required bool isStart}) =>
      GestureDetector(
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
                'Time',
                style: TextStyle(
                  fontSize: 16,
                  color:
                      isStart
                          ? CupertinoColors.systemGreen
                          : CupertinoColors.systemOrange,
                ),
              ),
              Text(
                _formatTime(isStart ? _startTime : _endTime),
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.label,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildSaveButton(BuildContext context) => Center(
    child: CupertinoButton.filled(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      onPressed: () => _saveEvent(context),
      child: const Text(
        'Save Changes',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );

  Widget _buildColorSelector() => SizedBox(
    height: 50,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _colorOptions.length + 1, // +1 for "No color" option
      itemBuilder: (context, index) {
        if (index == 0) {
          // "No color" option
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = null;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CupertinoColors.white,
                  border: Border.all(
                    color:
                        _selectedColor == null
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.systemGrey,
                    width: 2,
                  ),
                ),
                child:
                    _selectedColor == null
                        ? const Icon(
                          CupertinoIcons.checkmark,
                          color: CupertinoColors.activeBlue,
                        )
                        : null,
              ),
            ),
          );
        }

        final color = _colorOptions[index - 1];
        final colorValue = color.value;
        final isSelected = _selectedColor == colorValue;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = colorValue;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color:
                      isSelected
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey,
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? const Icon(
                        CupertinoIcons.checkmark,
                        color: CupertinoColors.white,
                      )
                      : null,
            ),
          ),
        );
      },
    ),
  );

  Future<void> _showDatePicker(BuildContext context) async {
    DateTime? pickedDate;
    final now = DateTime.now();
    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            color: CupertinoColors.systemBackground,
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime:
                        _selectedDate.isBefore(now) ? now : _selectedDate,
                    minimumDate: now,
                    onDateTimeChanged: (val) => pickedDate = val,
                  ),
                ),
                _buildPickerActions(context),
              ],
            ),
          ),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _selectedDate = pickedDate!;

        // Update start and end times to maintain the same time on the new date
        _startTime = DateTime(
          pickedDate!.year,
          pickedDate!.month,
          pickedDate!.day,
          _startTime.hour,
          _startTime.minute,
        );

        _endTime = DateTime(
          pickedDate!.year,
          pickedDate!.month,
          pickedDate!.day,
          _endTime.hour,
          _endTime.minute,
        );
      });
    }
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
            color: CupertinoColors.systemBackground,
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hm,
                    initialTimerDuration: Duration(
                      hours: (isStart ? _startTime : _endTime).hour,
                      minutes: (isStart ? _startTime : _endTime).minute,
                    ),
                    onTimerDurationChanged:
                        (duration) => pickedDuration = duration,
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

          // If end time is before start time, adjust it
          if (_endTime.isBefore(_startTime)) {
            _endTime = _startTime.add(const Duration(hours: 1));
          }
        } else {
          // Ensure end time is after start time
          if (time.isAfter(_startTime)) {
            _endTime = time;
          } else {
            // Show error message
            _showErrorDialog('End time must be after start time');
          }
        }
      });
    }
  }

  Widget _buildPickerActions(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      CupertinoButton(
        child: const Text(
          'Cancel',
          style: TextStyle(color: CupertinoColors.systemGrey),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      CupertinoButton(
        child: const Text(
          'Done',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    ],
  );

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
    if (!_formKey.currentState!.validate()) {
      _showErrorDialog('Please fill in all required fields.');
      return;
    }

    if (_endTime.isBefore(_startTime)) {
      _showErrorDialog('End time must be after start time.');
      return;
    }

    // Calculate estimated time in milliseconds
    final estimatedTime = _endTime.difference(_startTime).inMilliseconds;

    // Update the event
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

    // Update the scheduled task
    if (widget.event.scheduledTasks.isNotEmpty) {
      final scheduledTask = widget.event.scheduledTasks.first;
      scheduledTask.startTime = _startTime;
      scheduledTask.endTime = _endTime;

      // Save the updated task
      widget.event.save();

      // Update the day that contains this scheduled task
      final dateKey = _formatDateKey(_startTime);
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

  String _formatDateKey(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
}
