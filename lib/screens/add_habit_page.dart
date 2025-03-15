import 'package:flowo_client/blocs/tasks_controller/tasks_controller_cubit.dart';
import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/models/repeat_rule.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/screens/home_screen.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/tasks_controller/task_manager_cubit.dart';
import '../design/cupertino_form_theme.dart';
import '../design/cupertino_form_widgets.dart';

/// Extension to capitalize the first letter of a string.
extension StringExtension on String {
  String capitalize() =>
      isEmpty ? this : "${this[0].toUpperCase()}${substring(1)}";
}

class AddHabitPage extends StatefulWidget {
  final DateTime? selectedDate;

  const AddHabitPage({super.key, this.selectedDate});

  @override
  AddHabitPageState createState() => AddHabitPageState();
}

class AddHabitPageState extends State<AddHabitPage>
    with SingleTickerProviderStateMixin {
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
  final List<Map<String, dynamic>> _frequency = []; // Weekly frequency tracking
  final List<int> _monthlyDays = []; // Monthly frequency tracking
  String _monthlyType = 'specific'; // 'specific' or 'pattern'
  String? _monthlyWeek; // 'first', 'second', 'third', 'fourth', 'last'
  String? _monthlyDayOfWeek;

  // Animation for save button feedback
  late AnimationController _animationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _startTime = _selectedDate;

    // Initialize animation
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
    _intervalController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  int _dayNameToInt(String dayName) {
    const dayMap = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };
    return dayMap[dayName] ?? 1;
  }

  int _getSetPosFromWeek(String week) {
    const weekMap = {
      'first': 1,
      'second': 2,
      'third': 3,
      'fourth': 4,
      'last': -1,
    };
    return weekMap[week] ?? 1;
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
                _buildHabitDetailsSection(),
                SizedBox(height: CupertinoFormTheme.sectionSpacing),
                _buildDeadlineSection(),
                SizedBox(height: CupertinoFormTheme.sectionSpacing),
                _buildFrequencySection(),
                SizedBox(height: CupertinoFormTheme.sectionSpacing),
                _buildCategorySection(),
                SizedBox(height: CupertinoFormTheme.sectionSpacing),
                _buildPrioritySection(),
                SizedBox(height: CupertinoFormTheme.largeSpacing),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitDetailsSection() {
    return CupertinoFormWidgets.formGroup(
      title: 'Habit Details',
      children: [
        CupertinoFormWidgets.textField(
          controller: _titleController,
          placeholder: 'Habit Name *',
          validator: (value) => value!.isEmpty ? 'Required' : null,
        ),
        SizedBox(height: CupertinoFormTheme.elementSpacing),
        CupertinoFormWidgets.textField(
          controller: _notesController,
          placeholder: 'Notes',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildDeadlineSection() {
    return CupertinoFormWidgets.formGroup(
      title: 'Deadline',
      children: [
        CupertinoFormWidgets.selectionButton(
          label: 'Date',
          value: CupertinoFormTheme.formatDate(_selectedDate),
          onTap: () => _showDatePicker(context),
          color: CupertinoFormTheme.primaryColor,
          icon: CupertinoIcons.calendar,
        ),
        SizedBox(height: CupertinoFormTheme.elementSpacing),
        CupertinoFormWidgets.selectionButton(
          label: 'Start Time',
          value: CupertinoFormTheme.formatTime(_startTime),
          onTap: () => _showTimePicker(context, isStart: true),
          color: CupertinoFormTheme.secondaryColor,
          icon: CupertinoIcons.time,
        ),
        SizedBox(height: CupertinoFormTheme.elementSpacing),
        CupertinoFormWidgets.selectionButton(
          label: 'End Time',
          value: CupertinoFormTheme.formatTime(_endTime),
          onTap: () => _showTimePicker(context, isStart: false),
          color: CupertinoFormTheme.accentColor,
          icon: CupertinoIcons.time_solid,
        ),
      ],
    );
  }

  Widget _buildFrequencySection() {
    final frequencyTypes = ['daily', 'weekly', 'monthly', 'yearly'];
    final frequencyTypeWidgets = {
      for (var item in frequencyTypes)
        item: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CupertinoFormTheme.smallSpacing,
            vertical: CupertinoFormTheme.smallSpacing / 2,
          ),
          child: Text(item.capitalize()),
        ),
    };

    return CupertinoFormWidgets.formGroup(
      title: 'Frequency',
      children: [
        Text('Repeat Type', style: CupertinoFormTheme.labelTextStyle),
        SizedBox(height: CupertinoFormTheme.smallSpacing),
        CupertinoFormWidgets.segmentedControl(
          children: frequencyTypeWidgets,
          groupValue: _selectedFrequencyType,
          onValueChanged:
              (value) => setState(() => _selectedFrequencyType = value),
        ),
        SizedBox(height: CupertinoFormTheme.elementSpacing),
        Text('Repeat Every', style: CupertinoFormTheme.labelTextStyle),
        SizedBox(height: CupertinoFormTheme.smallSpacing),
        Row(
          children: [
            SizedBox(
              width: 60,
              child: CupertinoFormWidgets.textField(
                controller: _intervalController,
                placeholder: '1',
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    setState(() => _intervalValue = int.tryParse(value) ?? 1);
                  }
                },
              ),
            ),
            SizedBox(width: CupertinoFormTheme.smallSpacing),
            Text(
              _selectedFrequencyType == 'daily'
                  ? 'days'
                  : _selectedFrequencyType == 'weekly'
                  ? 'weeks'
                  : _selectedFrequencyType == 'monthly'
                  ? 'months'
                  : 'years',
              style: CupertinoFormTheme.valueTextStyle,
            ),
          ],
        ),
        if (_selectedFrequencyType == 'weekly') ...[
          SizedBox(height: CupertinoFormTheme.elementSpacing),
          Text('On Days', style: CupertinoFormTheme.labelTextStyle),
          SizedBox(height: CupertinoFormTheme.smallSpacing),
          if (_frequency.isNotEmpty)
            ..._frequency.map((freq) => _buildFrequencyItem(freq['day'])),
          SizedBox(height: CupertinoFormTheme.smallSpacing),
          CupertinoFormWidgets.primaryButton(
            text: 'Add Day',
            onPressed: () => _showWeeklyFrequencyDialog(context),
          ),
        ],
        if (_selectedFrequencyType == 'monthly') ...[
          SizedBox(height: CupertinoFormTheme.elementSpacing),
          _buildMonthlyOptions(),
        ],
      ],
    );
  }

  Widget _buildMonthlyOptions() {
    final monthlyTypeWidgets = {
      'specific': Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CupertinoFormTheme.smallSpacing,
          vertical: CupertinoFormTheme.smallSpacing / 2,
        ),
        child: Text('Specific Days'),
      ),
      'pattern': Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CupertinoFormTheme.smallSpacing,
          vertical: CupertinoFormTheme.smallSpacing / 2,
        ),
        child: Text('Pattern'),
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Type', style: CupertinoFormTheme.labelTextStyle),
        SizedBox(height: CupertinoFormTheme.smallSpacing),
        CupertinoFormWidgets.segmentedControl(
          children: monthlyTypeWidgets,
          groupValue: _monthlyType,
          onValueChanged: (value) => setState(() => _monthlyType = value),
        ),
        SizedBox(height: CupertinoFormTheme.elementSpacing),
        if (_monthlyType == 'specific') ...[
          Text('On Days', style: CupertinoFormTheme.labelTextStyle),
          SizedBox(height: CupertinoFormTheme.smallSpacing),
          if (_monthlyDays.isNotEmpty)
            Wrap(
              spacing: CupertinoFormTheme.smallSpacing,
              runSpacing: CupertinoFormTheme.smallSpacing,
              children: _monthlyDays.map((day) => _buildDayChip(day)).toList(),
            ),
          SizedBox(height: CupertinoFormTheme.smallSpacing),
          CupertinoFormWidgets.primaryButton(
            text: 'Add Day',
            onPressed: () => _showMonthlyDayPicker(context),
          ),
        ],
        if (_monthlyType == 'pattern') ...[
          Text('Pattern', style: CupertinoFormTheme.labelTextStyle),
          SizedBox(height: CupertinoFormTheme.smallSpacing),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showMonthlyWeekPicker(context),
                  child: Container(
                    padding: CupertinoFormTheme.inputPadding,
                    decoration: CupertinoFormTheme.inputDecoration,
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
              SizedBox(width: CupertinoFormTheme.smallSpacing),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showMonthlyDayOfWeekPicker(context),
                  child: Container(
                    padding: CupertinoFormTheme.inputPadding,
                    decoration: CupertinoFormTheme.inputDecoration,
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

  Widget _buildCategorySection() {
    final categoryWidgets = {
      for (var item in _categoryOptions)
        item: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CupertinoFormTheme.smallSpacing,
            vertical: CupertinoFormTheme.smallSpacing / 2,
          ),
          child: Text(item),
        ),
    };

    return CupertinoFormWidgets.formGroup(
      title: 'Category',
      children: [
        CupertinoFormWidgets.segmentedControl(
          children: categoryWidgets,
          groupValue: _selectedCategory,
          onValueChanged: _handleCategoryChange,
        ),
      ],
    );
  }

  Widget _buildPrioritySection() {
    final priorityWidgets = {
      for (var item in ['Low', 'Normal', 'High'])
        item: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CupertinoFormTheme.smallSpacing,
            vertical: CupertinoFormTheme.smallSpacing / 2,
          ),
          child: Text(item),
        ),
    };

    return CupertinoFormWidgets.formGroup(
      title: 'Priority',
      children: [
        CupertinoFormWidgets.segmentedControl(
          children: priorityWidgets,
          groupValue: _priority,
          onValueChanged: (value) => setState(() => _priority = value),
          selectedColor: CupertinoFormTheme.accentColor,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ScaleTransition(
      scale: _buttonScaleAnimation,
      child: CupertinoFormWidgets.primaryButton(
        text: 'Save Habit',
        onPressed: () {
          _animationController.forward().then(
            (_) => _animationController.reverse(),
          );
          _saveTask(context);
        },
      ),
    );
  }

  Widget _buildDayChip(int day) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CupertinoFormTheme.smallSpacing * 1.5,
        vertical: CupertinoFormTheme.smallSpacing * 0.75,
      ),
      decoration: BoxDecoration(
        color: CupertinoFormTheme.primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(CupertinoFormTheme.borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            day.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: CupertinoFormTheme.primaryColor,
            ),
          ),
          SizedBox(width: CupertinoFormTheme.smallSpacing / 2),
          GestureDetector(
            onTap: () => setState(() => _monthlyDays.remove(day)),
            child: Icon(
              CupertinoIcons.xmark_circle_fill,
              size: CupertinoFormTheme.smallIconSize,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyItem(String day) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: CupertinoFormTheme.smallSpacing / 2,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: CupertinoFormTheme.smallSpacing * 1.5,
          vertical: CupertinoFormTheme.smallSpacing * 0.75,
        ),
        decoration: BoxDecoration(
          color: CupertinoFormTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(CupertinoFormTheme.borderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(day, style: CupertinoFormTheme.valueTextStyle),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(
                CupertinoIcons.trash,
                size: CupertinoFormTheme.standardIconSize,
                color: CupertinoFormTheme.warningColor,
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

  Future<void> _showDatePicker(BuildContext context) async {
    final pickedDate = await CupertinoFormWidgets.showDatePicker(
      context: context,
      initialDate: _selectedDate,
    );
    if (pickedDate != null && mounted) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _showTimePicker(
    BuildContext context, {
    required bool isStart,
  }) async {
    final pickedTime = await CupertinoFormWidgets.showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime ?? _startTime,
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

  Future<void> _showWeeklyFrequencyDialog(BuildContext context) async {
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
                    if (day != null &&
                        mounted &&
                        !_frequency.any((item) => item['day'] == day)) {
                      setState(() => _frequency.add({'day': day}));
                      logInfo('Added frequency: $day');
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
    Function(String?) onSelected,
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
    String? selectedDay;

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
                    onSelectedItemChanged: (index) => selectedDay = days[index],
                    children: days.map((day) => Text(day)).toList(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        onSelected(null);
                        Navigator.pop(context);
                      },
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
    int? selectedDay;

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
                    onSelectedItemChanged: (index) => selectedDay = index + 1,
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
                        if (selectedDay != null &&
                            !_monthlyDays.contains(selectedDay)) {
                          setState(() {
                            _monthlyDays.add(selectedDay!);
                            _monthlyDays.sort();
                          });
                        }
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
    String? selectedWeek;

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
                    onSelectedItemChanged:
                        (index) => selectedWeek = weeks[index],
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
                        setState(() => _monthlyWeek = selectedWeek);
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
    String? selectedDay;

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
                    onSelectedItemChanged: (index) => selectedDay = days[index],
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
                        setState(() => _monthlyDayOfWeek = selectedDay);
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
                decoration: CupertinoFormTheme.inputDecoration,
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
                  if (newCategory.isNotEmpty &&
                      mounted &&
                      !_categoryOptions.contains(newCategory)) {
                    setState(() {
                      _categoryOptions.insert(
                        _categoryOptions.length - 1,
                        newCategory,
                      );
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

  void _saveTask(BuildContext context) {
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
    } else if (_selectedFrequencyType == 'monthly' &&
        _monthlyType == 'specific' &&
        _monthlyDays.isNotEmpty) {
      repeatRule = RepeatRule(
        frequency: _selectedFrequencyType,
        interval: _intervalValue,
        byMonthDay: _monthlyDays,
      );
    } else if (_selectedFrequencyType == 'monthly' &&
        _monthlyType == 'pattern' &&
        _monthlyWeek != null &&
        _monthlyDayOfWeek != null) {
      repeatRule = RepeatRule(
        frequency: _selectedFrequencyType,
        interval: _intervalValue,
        bySetPos: _getSetPosFromWeek(_monthlyWeek!),
        byDay: [_dayNameToInt(_monthlyDayOfWeek!)],
      );
    } else {
      repeatRule = RepeatRule(
        frequency: _selectedFrequencyType,
        interval: _intervalValue,
      );
    }

    context.read<TaskManagerCubit>().createTask(
      title: _titleController.text,
      priority: 10,
      deadline: startTime.millisecondsSinceEpoch,
      estimatedTime: endTime.difference(startTime).inMilliseconds,
      category: Category(name: _selectedCategory),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      frequency: repeatRule,
    );

    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (_) => const HomeScreen()),
    ).then((_) => context.read<CalendarCubit>().selectDate(startTime));
    logInfo('Saved habit: ${_titleController.text}');
  }
}
