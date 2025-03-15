import 'dart:core';

import 'package:flowo_client/blocs/tasks_controller/tasks_controller_cubit.dart';
import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/models/repeat_rule.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/screens/home_screen.dart';
import 'package:flowo_client/utils/date_time_formatter.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : "${this[0].toUpperCase()}${substring(1)}";
  }
}

class AddHabitPage extends StatefulWidget {
  final DateTime? selectedDate;

  const AddHabitPage({super.key, this.selectedDate});

  @override
  AddHabitPageState createState() => AddHabitPageState();
}

class AddHabitPageState extends State<AddHabitPage> {
  // Form controllers and keys
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _intervalController = TextEditingController(text: '1');

  // Date and time variables
  late DateTime _selectedDate;
  late DateTime _startTime;
  DateTime? _endTime;

  // Category and priority selections
  String _selectedCategory = 'Brainstorm';
  String _priority = 'Normal';
  final List<String> _categoryOptions = [
    'Brainstorm',
    'Design',
    'Workout',
    'Add',
  ];

  // Frequency settings
  String _selectedFrequencyType = 'weekly';
  int _intervalValue = 1;

  // Weekly frequency tracking
  final List<Map<String, dynamic>> _frequency = [];

  // Monthly frequency tracking
  final List<int> _monthlyDays = [];
  String _monthlyType =
      'specific'; // 'specific' for dates or 'pattern' for "first Monday", etc.
  int? _monthlyDayOfMonth;
  String? _monthlyWeek; // 'first', 'second', 'third', 'fourth', 'last'
  String? _monthlyDayOfWeek;

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
    _intervalController.dispose();
    super.dispose();
  }

  int _dayNameToInt(String dayName) {
    const Map<String, int> dayMap = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };
    return dayMap[dayName] ?? 1;
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _formatTime(DateTime? time) =>
      time != null ? DateTimeFormatter.formatTime(time) : 'Not set';

  int _mapPriorityToInt(String priority) =>
      {'Low': 0, 'Normal': 1, 'High': 2}[priority] ?? 1;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Add Habit')),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Habit Details'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _titleController,
                  placeholder: 'Habit Name *',
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _notesController,
                  placeholder: 'Notes',
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Deadline'),
                const SizedBox(height: 12),
                _buildDateButton(context),
                const SizedBox(height: 12),
                _buildTimeButton(context, isStart: true),
                const SizedBox(height: 12),
                _buildTimeButton(context, isStart: false),
                const SizedBox(height: 20),
                _buildSectionTitle('Frequency'),
                const SizedBox(height: 12),
                _buildAdvancedFrequencySelector(context),
                const SizedBox(height: 20),
                _buildSectionTitle('Category'),
                const SizedBox(height: 12),
                _buildSegmentedControl(
                  options: _categoryOptions,
                  value: _selectedCategory,
                  onChanged: _handleCategoryChange,
                ),
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
                _buildSaveButton(context, 'Habit'),
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
                isStart ? 'Start Time' : 'End Time',
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

  Widget _buildSegmentedControl({
    required List<String> options,
    required String value,
    required ValueChanged<String> onChanged,
    Color selectedColor = CupertinoColors.activeBlue,
  }) => CupertinoSegmentedControl<String>(
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

  Widget _buildAdvancedFrequencySelector(BuildContext context) {
    final List<String> frequencyTypes = [
      'daily',
      'weekly',
      'monthly',
      'yearly',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Repeat Type'),
        const SizedBox(height: 8),
        CupertinoSegmentedControl<String>(
          children: {
            for (var item in frequencyTypes)
              item: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(item.capitalize()),
              ),
          },
          groupValue: _selectedFrequencyType,
          onValueChanged: (value) {
            setState(() {
              _selectedFrequencyType = value;
            });
          },
        ),
        const SizedBox(height: 16),
        const Text('Repeat Every'),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 60,
              child: CupertinoTextField(
                controller: _intervalController,
                keyboardType: TextInputType.number,
                placeholder: '1',
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      _intervalValue = int.tryParse(value) ?? 1;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _selectedFrequencyType == 'daily'
                  ? 'days'
                  : _selectedFrequencyType == 'weekly'
                  ? 'weeks'
                  : _selectedFrequencyType == 'monthly'
                  ? 'months'
                  : 'years',
            ),
          ],
        ),

        // Weekly frequency options
        if (_selectedFrequencyType == 'weekly') ...[
          const SizedBox(height: 16),
          const Text('On Days'),
          const SizedBox(height: 8),
          if (_frequency.isNotEmpty)
            ..._frequency.map((freq) => _buildFrequencyItem(freq['day'])),
          const SizedBox(height: 8),
          CupertinoButton(
            color: CupertinoColors.systemBlue,
            child: const Text('Add Day'),
            onPressed: () => _showWeeklyFrequencyDialog(context),
          ),
        ],

        // Monthly frequency options
        if (_selectedFrequencyType == 'monthly') ...[
          const SizedBox(height: 16),
          _buildMonthlyOptions(context),
        ],
      ],
    );
  }

  Widget _buildMonthlyOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Type'),
        const SizedBox(height: 8),
        CupertinoSegmentedControl<String>(
          children: const {
            'specific': Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text('Specific Days'),
            ),
            'pattern': Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text('Pattern'),
            ),
          },
          groupValue: _monthlyType,
          onValueChanged: (value) {
            setState(() {
              _monthlyType = value;
            });
          },
        ),
        const SizedBox(height: 16),

        // Specific days selection
        if (_monthlyType == 'specific') ...[
          const Text('On Days'),
          const SizedBox(height: 8),
          if (_monthlyDays.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _monthlyDays.map((day) => _buildDayChip(day)).toList(),
            ),
          const SizedBox(height: 8),
          CupertinoButton(
            color: CupertinoColors.systemBlue,
            child: const Text('Add Day'),
            onPressed: () => _showMonthlyDayPicker(context),
          ),
        ],

        // Pattern selection (e.g., "first Monday")
        if (_monthlyType == 'pattern') ...[
          const Text('Pattern'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showMonthlyWeekPicker(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: CupertinoColors.systemGrey4),
                    ),
                    child: Text(
                      _monthlyWeek?.capitalize() ?? 'Select week',
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            _monthlyWeek == null
                                ? CupertinoColors.systemGrey2
                                : CupertinoColors.label,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showMonthlyDayOfWeekPicker(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: CupertinoColors.systemGrey4),
                    ),
                    child: Text(
                      _monthlyDayOfWeek?.capitalize() ?? 'Select day',
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            _monthlyDayOfWeek == null
                                ? CupertinoColors.systemGrey2
                                : CupertinoColors.label,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDayChip(int day) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            day.toString(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _monthlyDays.remove(day);
              });
            },
            child: const Icon(
              CupertinoIcons.xmark_circle_fill,
              size: 16,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyItem(String day) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(day),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.trash,
                size: 20,
                color: CupertinoColors.systemRed,
              ),
              onPressed:
                  () => setState(
                    () => _frequency.removeWhere((item) => item['day'] == day),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, String type) => Center(
    child: CupertinoButton.filled(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      onPressed: () => _saveTask(context, type),
      child: const Text(
        'Save',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );

  Future<void> _showDatePicker(BuildContext context) async {
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

  Future<void> _showWeeklyFrequencyDialog(BuildContext context) async {
    String? selectedDay;
    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Text('Add Day'),
            actions: [
              CupertinoActionSheetAction(
                child: const Text('Select Day'),
                onPressed: () async {
                  Navigator.pop(context);
                  await _showDayOfWeekPicker(context, (day) {
                    selectedDay = day;
                    if (selectedDay != null && mounted) {
                      // Check if the day already exists
                      if (!_frequency.any(
                        (item) => item['day'] == selectedDay,
                      )) {
                        setState(() => _frequency.add({'day': selectedDay!}));
                        logInfo('Added frequency: $selectedDay');
                      }
                    }
                  });
                },
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
          ),
    );
  }

  Future<void> _showDayOfWeekPicker(
    BuildContext context,
    Function(String) onSelected,
  ) async {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    String selectedDay = days[0];

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
                  child: CupertinoPicker(
                    itemExtent: 32,
                    onSelectedItemChanged: (index) {
                      selectedDay = days[index];
                    },
                    children: days.map((day) => Text(day)).toList(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text('Select'),
                      onPressed: () {
                        onSelected(selectedDay);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _showMonthlyDayPicker(BuildContext context) async {
    int selectedDay = 1;

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
                  child: CupertinoPicker(
                    itemExtent: 32,
                    onSelectedItemChanged: (index) {
                      selectedDay = index + 1;
                    },
                    children: List.generate(
                      31,
                      (index) => Text('${index + 1}'),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text('Add'),
                      onPressed: () {
                        setState(() {
                          if (!_monthlyDays.contains(selectedDay)) {
                            _monthlyDays.add(selectedDay);
                            _monthlyDays.sort();
                          }
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _showMonthlyWeekPicker(BuildContext context) async {
    final weeks = ['first', 'second', 'third', 'fourth', 'last'];
    String selectedWeek = weeks[0];

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
                  child: CupertinoPicker(
                    itemExtent: 32,
                    onSelectedItemChanged: (index) {
                      selectedWeek = weeks[index];
                    },
                    children:
                        weeks.map((week) => Text(week.capitalize())).toList(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text('Select'),
                      onPressed: () {
                        setState(() {
                          _monthlyWeek = selectedWeek;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _showMonthlyDayOfWeekPicker(BuildContext context) async {
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    String selectedDay = days[0];

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
                  child: CupertinoPicker(
                    itemExtent: 32,
                    onSelectedItemChanged: (index) {
                      selectedDay = days[index];
                    },
                    children:
                        days.map((day) => Text(day.capitalize())).toList(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text('Select'),
                      onPressed: () {
                        setState(() {
                          _monthlyDayOfWeek = selectedDay;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
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

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
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
                          _categoryOptions.length - 1,
                          newCategory,
                        );
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

  void _handleCategoryChange(String value) {
    if (value == 'Add') {
      _showAddCategoryDialog(context);
    } else {
      setState(() => _selectedCategory = value);
    }
  }

  void _saveTask(BuildContext context, String type) {
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

    // Create a RepeatRule object
    RepeatRule repeatRule;

    if (_selectedFrequencyType == 'weekly' && _frequency.isNotEmpty) {
      repeatRule = RepeatRule(
        frequency: _selectedFrequencyType,
        interval: _intervalValue,
        byDay:
            _frequency.map((f) => _dayNameToInt(f['day'] as String)).toList(),
      );
    } else {
      // For other frequency types
      repeatRule = RepeatRule(
        frequency: _selectedFrequencyType,
        interval: _intervalValue,
      );
    }

    final task = Task(
      id: UniqueKey().toString(),
      title: _titleController.text,
      priority: _mapPriorityToInt(_priority),
      deadline: startTime.millisecondsSinceEpoch,
      estimatedTime: endTime.difference(startTime).inMilliseconds,
      category: Category(name: _selectedCategory),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      frequency: repeatRule,
      subtasks: const [],
      scheduledTasks: const [],
      isDone: false,
      order: 0,
      overdue: false,
    );

    context.read<CalendarCubit>().addTask(task);
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (_) => const HomeScreen()),
    ).then((_) => context.read<CalendarCubit>().selectDate(startTime));
    logInfo('Saved $type: ${task.title}');
  }
}
