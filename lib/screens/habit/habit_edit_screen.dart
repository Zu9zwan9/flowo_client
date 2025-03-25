import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/models/repeat_rule.dart';
import 'package:flowo_client/models/repeat_rule_instance.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/tasks_controller/task_manager_cubit.dart';

class HabitEditScreen extends StatefulWidget {
  final Task habit;

  const HabitEditScreen({super.key, required this.habit});

  @override
  HabitEditScreenState createState() => HabitEditScreenState();
}

class HabitEditScreenState extends State<HabitEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  late int _estimatedTime;
  late DateTime _startDate;
  DateTime? _endDate;
  late String _selectedCategory;
  late int _priority;
  int? _selectedColor;

  // RepeatRule properties
  String _frequency = 'daily'; // daily, weekly, monthly, yearly
  int _interval = 1;
  List<int> _daysOfWeek = [];
  List<int> _daysOfMonth = [];
  List<int> _months = [];
  int? _weekOfMonth;

  final List<String> _categoryOptions = ['Habit', 'Workout', 'Health', 'Add'];
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

    // Initialize controllers and variables with habit data
    _titleController.text = widget.habit.title;
    _notesController.text = widget.habit.notes ?? '';
    _estimatedTime = widget.habit.estimatedTime;
    _startDate = DateTime.fromMillisecondsSinceEpoch(widget.habit.deadline);
    _selectedCategory = widget.habit.category.name;
    _priority = widget.habit.priority;
    _selectedColor = widget.habit.color;

    // Initialize repeat rule properties
    if (widget.habit.frequency != null) {
      _frequency = widget.habit.frequency!.type.toLowerCase();
      _interval = widget.habit.frequency!.interval;
      _endDate = widget.habit.frequency!.endRepeat;
      _weekOfMonth = widget.habit.frequency!.bySetPos;

      // Process byDay, byMonthDay, byMonth as lists of int
      _daysOfWeek =
          widget.habit.frequency!.byDay
              ?.map((e) => int.parse(e.selectedDay))
              .toList() ??
          [];
      _daysOfMonth =
          widget.habit.frequency!.byMonthDay
              ?.map((e) => int.parse(e.selectedDay))
              .toList() ??
          [];
      _months =
          widget.habit.frequency!.byMonth
              ?.map((e) => int.parse(e.selectedDay))
              .toList() ??
          [];
    }

    // Add the habit's category to the options if it's not already there
    if (!_categoryOptions.contains(_selectedCategory) &&
        _selectedCategory != 'Add') {
      _categoryOptions.insert(_categoryOptions.length - 1, _selectedCategory);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Edit Habit')),
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
                _buildSectionTitle('Schedule'),
                const SizedBox(height: 12),
                _buildDateButton(context, 'Start Date', _startDate, (date) {
                  setState(() => _startDate = date);
                }),
                const SizedBox(height: 12),
                _buildDateButton(context, 'End Date (Optional)', _endDate, (
                  date,
                ) {
                  setState(() => _endDate = date);
                }, allowNull: true),
                const SizedBox(height: 20),
                _buildSectionTitle('Recurrence'),
                const SizedBox(height: 12),
                _buildFrequencySelector(),
                const SizedBox(height: 12),
                _buildIntervalSelector(),
                const SizedBox(height: 12),
                if (_frequency == 'weekly') _buildDaysOfWeekSelector(),
                if (_frequency == 'monthly') _buildDaysOfMonthSelector(),
                if (_frequency == 'yearly') _buildMonthsSelector(),
                const SizedBox(height: 20),
                _buildSectionTitle('Estimated Time'),
                const SizedBox(height: 12),
                _buildEstimatedTimeButton(context),
                const SizedBox(height: 20),
                _buildSectionTitle('Category'),
                const SizedBox(height: 12),
                _buildSegmentedControl(
                  options: _categoryOptions,
                  value: _selectedCategory,
                  onChanged: _handleCategoryChange,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildSectionTitle('Priority '),
                    Text(
                      _priority.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPrioritySlider(),
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

  Widget _buildDateButton(
    BuildContext context,
    String label,
    DateTime? date,
    Function(DateTime) onDateSelected, {
    bool allowNull = false,
  }) => GestureDetector(
    onTap: () => _showDatePicker(context, date, onDateSelected, allowNull),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: CupertinoColors.systemBlue,
            ),
          ),
          Text(
            date != null ? _formatDate(date) : 'Not set',
            style: const TextStyle(fontSize: 16, color: CupertinoColors.label),
          ),
        ],
      ),
    ),
  );

  Widget _buildFrequencySelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Frequency',
        style: TextStyle(fontSize: 16, color: CupertinoColors.systemBlue),
      ),
      const SizedBox(height: 8),
      CupertinoSlidingSegmentedControl<String>(
        groupValue: _frequency,
        children: const {
          'daily': Text('Daily'),
          'weekly': Text('Weekly'),
          'monthly': Text('Monthly'),
          'yearly': Text('Yearly'),
        },
        onValueChanged: (value) {
          if (value != null) {
            setState(() {
              _frequency = value;
              // Reset dependent fields when frequency changes
              _daysOfWeek.clear();
              _daysOfMonth.clear();
              _months.clear();
              _weekOfMonth = null;
            });
          }
        },
      ),
    ],
  );

  Widget _buildIntervalSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        _getIntervalLabel(),
        style: const TextStyle(fontSize: 16, color: CupertinoColors.systemBlue),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _interval > 1 ? () => setState(() => _interval--) : null,
            child: const Icon(CupertinoIcons.minus_circle),
          ),
          Expanded(
            child: Text(
              _interval.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.plus_circle),
            onPressed: () => setState(() => _interval++),
          ),
        ],
      ),
    ],
  );

  String _getIntervalLabel() {
    switch (_frequency) {
      case 'daily':
        return 'Every $_interval day(s)';
      case 'weekly':
        return 'Every $_interval week(s)';
      case 'monthly':
        return 'Every $_interval month(s)';
      case 'yearly':
        return 'Every $_interval year(s)';
      default:
        return 'Interval';
    }
  }

  Widget _buildDaysOfWeekSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Days of Week',
        style: TextStyle(fontSize: 16, color: CupertinoColors.systemBlue),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          _buildDayOfWeekChip('Mon', 1),
          _buildDayOfWeekChip('Tue', 2),
          _buildDayOfWeekChip('Wed', 3),
          _buildDayOfWeekChip('Thu', 4),
          _buildDayOfWeekChip('Fri', 5),
          _buildDayOfWeekChip('Sat', 6),
          _buildDayOfWeekChip('Sun', 0),
        ],
      ),
    ],
  );

  Widget _buildDayOfWeekChip(String label, int dayValue) {
    final isSelected = _daysOfWeek.contains(dayValue);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _daysOfWeek.remove(dayValue);
          } else {
            _daysOfWeek.add(dayValue);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey4,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? CupertinoColors.white : CupertinoColors.label,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDaysOfMonthSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Days of Month',
        style: TextStyle(fontSize: 16, color: CupertinoColors.systemBlue),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 120,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 31,
          itemBuilder: (context, index) {
            final day = index + 1;
            final isSelected = _daysOfMonth.contains(day);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _daysOfMonth.remove(day);
                  } else {
                    _daysOfMonth.add(day);
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey6,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isSelected
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.systemGrey4,
                  ),
                ),
                child: Center(
                  child: Text(
                    day.toString(),
                    style: TextStyle(
                      color:
                          isSelected
                              ? CupertinoColors.white
                              : CupertinoColors.label,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );

  Widget _buildMonthsSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Months',
        style: TextStyle(fontSize: 16, color: CupertinoColors.systemBlue),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (int i = 0; i < 12; i++) _buildMonthChip(_getMonthName(i), i),
        ],
      ),
    ],
  );

  String _getMonthName(int month) {
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
    return months[month];
  }

  Widget _buildMonthChip(String label, int monthValue) {
    final isSelected = _months.contains(monthValue);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _months.remove(monthValue);
          } else {
            _months.add(monthValue);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey4,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? CupertinoColors.white : CupertinoColors.label,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedControl({
    required List<String> options,
    required String value,
    required ValueChanged<String> onChanged,
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
    selectedColor: CupertinoColors.activeBlue,
    unselectedColor: CupertinoColors.systemGrey6,
  );

  Widget _buildSaveButton(BuildContext context) => Center(
    child: CupertinoButton.filled(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      onPressed: () => _saveHabit(context),
      child: const Text(
        'Save Changes',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );

  Widget _buildEstimatedTimeButton(BuildContext context) => GestureDetector(
    onTap: () async {
      final estimatedTime = await _showEstimatedTimePicker(context);
      if (mounted) {
        setState(() => _estimatedTime = estimatedTime);
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
            'Estimated Time',
            style: TextStyle(fontSize: 16, color: CupertinoColors.systemBlue),
          ),
          Text(
            '${(_estimatedTime ~/ 3600000).toString().padLeft(2, '0')}h ${((_estimatedTime % 3600000) ~/ 60000).toString().padLeft(2, '0')}m',
            style: const TextStyle(fontSize: 16, color: CupertinoColors.label),
          ),
        ],
      ),
    ),
  );

  Widget _buildPrioritySlider() => SizedBox(
    width: double.infinity,
    child: CupertinoSlider(
      min: 1,
      max: 10,
      divisions: 9,
      value: _priority.toDouble(),
      onChanged: (value) => setState(() => _priority = value.toInt()),
      activeColor: CupertinoColors.systemOrange,
    ),
  );

  Widget _buildColorSelector() => SizedBox(
    height: 50,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _colorOptions.length + 1, // +1 for "No color" option
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedColor = null),
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
            onTap: () => setState(() => _selectedColor = colorValue),
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

  Future<void> _showDatePicker(
    BuildContext context,
    DateTime? initialDate,
    Function(DateTime) onDateSelected,
    bool allowNull,
  ) async {
    DateTime? pickedDate;
    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            color: CupertinoColors.systemBackground,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (allowNull)
                      CupertinoButton(
                        child: const Text('Clear'),
                        onPressed: () {
                          Navigator.pop(context);
                          pickedDate = null;
                        },
                      ),
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
                SizedBox(
                  height: 220,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate ?? DateTime.now(),
                    onDateTimeChanged: (val) => pickedDate = val,
                  ),
                ),
              ],
            ),
          ),
    );
    if (pickedDate != null && mounted) {
      onDateSelected(pickedDate!);
    }
  }

  Future<int> _showEstimatedTimePicker(BuildContext context) async {
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
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 32,
                          onSelectedItemChanged: (index) => pickedHours = index,
                          children: [
                            for (var i = 0; i <= 120; i++) Text('$i hours'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 32,
                          onSelectedItemChanged:
                              (index) => pickedMinutes = index * 15,
                          children: [
                            for (var i = 0; i < 4; i++)
                              Text('${i * 15} minutes'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
    return (pickedHours ?? 0) * 3600000 + (pickedMinutes ?? 0) * 60000;
  }

  void _handleCategoryChange(String value) {
    if (value == 'Add') {
      _showAddCategoryDialog(context);
    } else {
      setState(() => _selectedCategory = value);
    }
  }

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

  void _showValidationError(String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Validation Error'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  Future<void> _saveHabit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      _showValidationError('Please fill in all required fields.');
      return;
    }

    // Validate recurrence fields
    if (_frequency == 'weekly' && _daysOfWeek.isEmpty) {
      _showValidationError('Please select at least one day of the week.');
      return;
    }
    if (_frequency == 'monthly' && _daysOfMonth.isEmpty) {
      _showValidationError('Please select at least one day of the month.');
      return;
    }
    if (_frequency == 'yearly' && _months.isEmpty) {
      _showValidationError('Please select at least one month.');
      return;
    }

    // Create RepeatRule with the model structure
    final repeatRule = RepeatRule(
      type: _frequency.toUpperCase(),
      interval: _interval,
      startRepeat: _startDate,
      endRepeat: _endDate,
      byDay:
          _frequency == 'weekly'
              ? _daysOfWeek
                  .map(
                    (day) => RepeatRuleInstance(
                      selectedDay: day.toString(),
                      name: 'Day $day',
                      start: const TimeOfDay(hour: 0, minute: 0),
                      end: const TimeOfDay(hour: 23, minute: 59),
                    ),
                  )
                  .toList()
              : null,
      byMonthDay:
          _frequency == 'monthly'
              ? _daysOfMonth
                  .map(
                    (day) => RepeatRuleInstance(
                      selectedDay: day.toString(),
                      name: 'Day $day',
                      start: const TimeOfDay(hour: 0, minute: 0),
                      end: const TimeOfDay(hour: 23, minute: 59),
                    ),
                  )
                  .toList()
              : null,
      byMonth:
          _frequency == 'yearly'
              ? _months
                  .map(
                    (month) => RepeatRuleInstance(
                      selectedDay: month.toString(),
                      name: _getMonthName(month),
                      start: const TimeOfDay(hour: 0, minute: 0),
                      end: const TimeOfDay(hour: 23, minute: 59),
                    ),
                  )
                  .toList()
              : null,
      bySetPos: _weekOfMonth,
    );

    final tasksCubit = context.read<TaskManagerCubit>();

    // Update the habit
    tasksCubit.editTask(
      task: widget.habit,
      title: _titleController.text,
      priority: _priority,
      estimatedTime: _estimatedTime,
      deadline: _startDate.millisecondsSinceEpoch,
      category: Category(name: _selectedCategory),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      color: _selectedColor,
      frequency: repeatRule,
    );

    // Navigate back to home screen
    Navigator.pop(context);
    logInfo('Habit updated: ${_titleController.text}');
  }
}
