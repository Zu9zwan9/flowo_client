// lib/screens/add_event_page.dart
import 'dart:io';

import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/blocs/tasks_controller/tasks_controller_cubit.dart';
import 'package:flowo_client/screens/home_screen.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class AddEventPage extends StatefulWidget {
  final DateTime? selectedDate;

  const AddEventPage({super.key, this.selectedDate});

  @override
  AddEventPageState createState() => AddEventPageState();
}

class AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();

  late DateTime _selectedDate;
  late DateTime _startTime;
  DateTime? _endTime;
  File? _image;
  int? _selectedColor;
  int _travelingTime = 0; // Default to 0 milliseconds
  // Events always use the 'Event' category

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _startTime = _selectedDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _formatTime(DateTime? time) =>
      time != null
          ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
          : 'Not set';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
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
                const SizedBox(height: 12),
                _buildImagePicker(),
                const SizedBox(height: 12),
                _buildSectionTitle('Event Color'),
                const Text(
                  'Select a color for your event',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                _buildColorPicker(),
                const SizedBox(height: 20),
                _buildSectionTitle('Traveling Time'),
                const Text(
                  'Optional time needed for travel to the event location',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTravelingTimeButton(context),
                const SizedBox(height: 20),
                _buildSectionTitle('Start'),
                const SizedBox(height: 12),
                _buildDateButton(context, isStart: true),
                const SizedBox(height: 12),
                _buildTimeButton(context, isStart: true),
                const SizedBox(height: 20),
                _buildSectionTitle('End'),
                const SizedBox(height: 12),
                _buildDateButton(context, isStart: false),
                const SizedBox(height: 12),
                _buildTimeButton(context, isStart: false),
                const SizedBox(height: 32),
                _buildSaveButton(context, 'Event'),
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

  Widget _buildDateButton(
    BuildContext context, {
    required bool isStart,
  }) => GestureDetector(
    onTap: () => _showDatePicker(context, isStart: isStart),
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

  Widget _buildColorPicker() {
    final colorOptions = [
      0xFF4CAF50, // Green
      0xFF2196F3, // Blue
      0xFFF44336, // Red
      0xFFFF9800, // Orange
      0xFF9C27B0, // Purple
      0xFF795548, // Brown
      0xFF607D8B, // Blue Grey
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: colorOptions.length + 1, // +1 for "No color" option
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

          final color = colorOptions[index - 1];
          final isSelected = _selectedColor == color;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(color),
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
  }

  Widget _buildTravelingTimeButton(BuildContext context) => GestureDetector(
    onTap: () async {
      final travelingTime = await _showTravelingTimePicker(context);
      if (mounted) {
        setState(() => _travelingTime = travelingTime);
      }
    },
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
            'Traveling Time',
            style: TextStyle(fontSize: 16, color: CupertinoColors.systemBlue),
          ),
          Text(
            '${(_travelingTime ~/ 3600000).toString().padLeft(2, '0')}h ${((_travelingTime % 3600000) ~/ 60000).toString().padLeft(2, '0')}m',
            style: const TextStyle(fontSize: 16, color: CupertinoColors.label),
          ),
        ],
      ),
    ),
  );

  Future<int> _showTravelingTimePicker(BuildContext context) async {
    int? pickedHours;
    int? pickedMinutes;
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
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 32,
                          onSelectedItemChanged: (index) {
                            pickedHours = index;
                          },
                          children: [
                            for (var i = 0; i <= 12; i++) Text('$i hours'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 32,
                          onSelectedItemChanged: (index) {
                            pickedMinutes = index * 15;
                          },
                          children: [
                            for (var i = 0; i < 4; i++)
                              Text('${i * 15} minutes'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
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
                      onPressed: () {
                        Navigator.pop(
                          context,
                          (pickedHours ?? 0) * 3600000 +
                              (pickedMinutes ?? 0) * 60000,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
    return (pickedHours ?? 0) * 3600000 + (pickedMinutes ?? 0) * 60000;
  }

  Widget _buildImagePicker() => GestureDetector(
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
                child: Image.file(
                  _image!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              )
              : const Icon(
                CupertinoIcons.photo,
                color: CupertinoColors.systemGrey,
              ),
        ],
      ),
    ),
  );

  Widget _buildSaveButton(BuildContext context, String type) => Center(
    child: CupertinoButton.filled(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      onPressed: () => _saveEvent(context, type),
      child: const Text(
        'Save',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );

  Future<void> _showDatePicker(
    BuildContext context, {
    required bool isStart,
  }) async {
    DateTime? pickedDate;
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
                        isStart ? _selectedDate : (_endTime ?? _startTime),
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
        if (isStart) {
          _selectedDate = pickedDate!;
          // Update start time to maintain the same date
          _startTime = DateTime(
            pickedDate!.year,
            pickedDate!.month,
            pickedDate!.day,
            _startTime.hour,
            _startTime.minute,
          );
        } else {
          // Update end time to the selected date while preserving time
          _endTime =
              _endTime != null
                  ? DateTime(
                    pickedDate!.year,
                    pickedDate!.month,
                    pickedDate!.day,
                    _endTime!.hour,
                    _endTime!.minute,
                  )
                  : DateTime(
                    pickedDate!.year,
                    pickedDate!.month,
                    pickedDate!.day,
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
                      hours:
                          (isStart ? _startTime : _endTime ?? _startTime).hour,
                      minutes:
                          (isStart ? _startTime : _endTime ?? _startTime)
                              .minute,
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
        } else {
          _endTime = time;
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

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null && mounted) {
        setState(() => _image = File(pickedFile.path));
        logInfo('Image picked: ${pickedFile.path}');
      }
    } catch (e) {
      logError('Failed to pick image: $e');
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder:
              (_) => CupertinoAlertDialog(
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

  void _saveEvent(BuildContext context, String type) {
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

    // Create the event with additional parameters
    context.read<TaskManagerCubit>().createEvent(
      title: _titleController.text,
      start: startTime,
      end: endTime,
      location: _locationController.text,
      notes: _notesController.text,
      color: _selectedColor,
      travelingTime: _travelingTime,
    );

    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (_) => const HomeScreen()),
    ).then((_) => context.read<CalendarCubit>().selectDate(startTime));
    logInfo('Created event: ${_titleController.text}');
  }
}
