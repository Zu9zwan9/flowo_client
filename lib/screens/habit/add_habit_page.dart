import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/models/repeat_rule.dart';
import 'package:flowo_client/models/repeat_rule_instance.dart';
import 'package:flowo_client/screens/home_screen.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../design/cupertino_form_theme.dart';
import '../../design/cupertino_form_widgets.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _intervalController = TextEditingController(text: '1');

  late DateTime _selectedStartDate;
  late DateTime _selectedEndDate;

  String _selectedCategory = 'Brainstorm';
  final String _priority = 'Normal';
  final List<String> _categoryOptions = [
    'Brainstorm',
    'Design',
    'Workout',
    'Add',
  ];

  String _selectedFrequencyType = 'weekly';
  int _intervalValue = 1;
  String _monthlyType = 'specific';
  String? _monthlyWeek;
  String? _monthlyDayOfWeek;

  late AnimationController _animationController;
  late Animation<double> _buttonScaleAnimation;

  // State for RepeatRuleInstance inputs
  late TextEditingController _nameController;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final List<Map<String, dynamic>> _weeklyInstances = [];
  final List<Map<String, dynamic>> _monthlySpecificInstances = [];

  @override
  void initState() {
    super.initState();
    _selectedStartDate = widget.selectedDate ?? DateTime.now();
    _selectedEndDate =
        widget.selectedDate ?? DateTime.now().add(Duration(days: 7));

    _nameController = TextEditingController();

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
    _nameController.dispose();
    for (var inst in _weeklyInstances) {
      inst['nameController'].dispose();
    }
    for (var inst in _monthlySpecificInstances) {
      inst['nameController'].dispose();
    }
    _animationController.dispose();
    super.dispose();
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
    final theme = CupertinoFormTheme(context);
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Add Habit')),
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
                  title: 'Habit Details',
                  children: [
                    CupertinoFormWidgets.textField(
                      context: context,
                      controller: _titleController,
                      placeholder: 'Habit Title *',
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: CupertinoFormTheme.elementSpacing),
                    CupertinoFormWidgets.textField(
                      context: context,
                      controller: _notesController,
                      placeholder: 'Notes',
                      maxLines: 3,
                    ),
                  ],
                ),
                SizedBox(height: CupertinoFormTheme.sectionSpacing),
                CupertinoFormWidgets.formGroup(
                  context: context,
                  title: 'Starts',
                  children: [
                    CupertinoFormWidgets.selectionButton(
                      context: context,
                      label: 'Date',
                      value: theme.formatDate(_selectedStartDate),
                      onTap: () => _showDatePicker(context, true),
                      color: theme.primaryColor,
                      icon: CupertinoIcons.calendar,
                    ),
                  ],
                ),
                SizedBox(height: CupertinoFormTheme.sectionSpacing),
                CupertinoFormWidgets.formGroup(
                  context: context,
                  title: 'Ends',
                  children: [
                    CupertinoFormWidgets.selectionButton(
                      context: context,
                      label: 'Date',
                      value: theme.formatDate(_selectedEndDate),
                      onTap: () => _showDatePicker(context, false),
                      color: theme.primaryColor,
                      icon: CupertinoIcons.calendar,
                    ),
                  ],
                ),
                SizedBox(height: CupertinoFormTheme.sectionSpacing),
                _buildFrequencySection(context, theme),
                SizedBox(height: CupertinoFormTheme.sectionSpacing),
                _buildCategorySection(context, theme),
                SizedBox(height: CupertinoFormTheme.largeSpacing),
                ScaleTransition(
                  scale: _buttonScaleAnimation,
                  child: CupertinoFormWidgets.primaryButton(
                    context: context,
                    text: 'Save Habit',
                    onPressed: () {
                      _animationController.forward().then(
                        (_) => _animationController.reverse(),
                      );
                      _saveTask(context);
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

  /// Builds the frequency section with dynamic fields based on the selected frequency type.
  Widget _buildFrequencySection(
    BuildContext context,
    CupertinoFormTheme theme,
  ) {
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

    List<Widget> frequencyWidgets = [
      Text('Repeat Type', style: theme.labelTextStyle),
      SizedBox(height: CupertinoFormTheme.smallSpacing),
      CupertinoFormWidgets.segmentedControl(
        context: context,
        children: frequencyTypeWidgets,
        groupValue: _selectedFrequencyType,
        onValueChanged:
            (value) => setState(() => _selectedFrequencyType = value),
      ),
      SizedBox(height: CupertinoFormTheme.elementSpacing),
      Text('Repeat Every', style: theme.labelTextStyle),
      SizedBox(height: CupertinoFormTheme.smallSpacing),
      Row(
        children: [
          SizedBox(
            width: 60,
            child: CupertinoFormWidgets.textField(
              context: context,
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
            style: theme.valueTextStyle,
          ),
        ],
      ),
    ];

    // Add frequency-specific input fields
    if (_selectedFrequencyType == 'daily' ||
        _selectedFrequencyType == 'yearly') {
      frequencyWidgets.addAll(_buildSingleInstanceWidgets(context, theme));
    } else if (_selectedFrequencyType == 'weekly') {
      frequencyWidgets.addAll(_buildWeeklyWidgets(context, theme));
    } else if (_selectedFrequencyType == 'monthly') {
      frequencyWidgets.add(_buildMonthlyOptions(context, theme));
    }

    return CupertinoFormWidgets.formGroup(
      context: context,
      title: 'Frequency',
      children: frequencyWidgets,
    );
  }

  /// Builds input fields for a single habit instance (used for daily, yearly, and monthly pattern).
  List<Widget> _buildSingleInstanceWidgets(
    BuildContext context,
    CupertinoFormTheme theme,
  ) {
    return [
      SizedBox(height: CupertinoFormTheme.elementSpacing),
      Text('Habit Details', style: theme.labelTextStyle),
      SizedBox(height: CupertinoFormTheme.smallSpacing),
      CupertinoFormWidgets.textField(
        context: context,
        controller: _nameController,
        placeholder: 'Habit Name *',
        validator: (value) => value!.isEmpty ? 'Required' : null,
      ),
      SizedBox(height: CupertinoFormTheme.elementSpacing),
      CupertinoFormWidgets.selectionButton(
        context: context,
        label: 'Start Time',
        value: _startTime != null ? _startTime!.format(context) : 'Select',
        // Use TimeOfDay.format
        onTap: () async {
          final time = await _pickTime(context, _startTime);
          if (time != null) setState(() => _startTime = time);
        },
        color: theme.secondaryColor,
        icon: CupertinoIcons.time,
      ),
      SizedBox(height: CupertinoFormTheme.elementSpacing),
      CupertinoFormWidgets.selectionButton(
        context: context,
        label: 'End Time',
        value: _endTime != null ? _endTime!.format(context) : 'Select',
        // Use TimeOfDay.format
        onTap: () async {
          final time = await _pickTime(context, _endTime);
          if (time != null) setState(() => _endTime = time);
        },
        color: theme.accentColor,
        icon: CupertinoIcons.time_solid,
      ),
    ];
  }

  /// Builds widgets for weekly frequency with multiple instances.
  List<Widget> _buildWeeklyWidgets(
    BuildContext context,
    CupertinoFormTheme theme,
  ) {
    List<Widget> widgets = [];

    if (_weeklyInstances.isEmpty) {
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No days added yet', style: theme.labelTextStyle),
            SizedBox(height: CupertinoFormTheme.elementSpacing),
            CupertinoFormWidgets.primaryButton(
              context: context,
              text: 'Add Day',
              onPressed: () => _showWeeklyDayPicker(context),
            ),
          ],
        ),
      );
    } else {
      widgets.addAll(
        _weeklyInstances.map((inst) {
          final day = inst['day'] as String;
          final capitalizedDay =
              day.isEmpty ? day : "${day[0].toUpperCase()}${day.substring(1)}";
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: CupertinoFormTheme.elementSpacing),
              Text('Day: $capitalizedDay', style: theme.labelTextStyle),
              SizedBox(height: CupertinoFormTheme.smallSpacing),
              CupertinoFormWidgets.textField(
                context: context,
                controller: inst['nameController'],
                placeholder: 'Habit Name *',
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: CupertinoFormTheme.elementSpacing),
              CupertinoFormWidgets.selectionButton(
                context: context,
                label: 'Start Time',
                value:
                    inst['start'] != null
                        ? (inst['start'] as TimeOfDay).format(
                          context,
                        ) // Используем TimeOfDay.format
                        : 'Select',
                onTap: () async {
                  final time = await _pickTime(context, inst['start']);
                  if (time != null) setState(() => inst['start'] = time);
                },
                color: theme.secondaryColor,
                icon: CupertinoIcons.time,
              ),
              SizedBox(height: CupertinoFormTheme.elementSpacing),
              CupertinoFormWidgets.selectionButton(
                context: context,
                label: 'End Time',
                value:
                    inst['end'] != null
                        ? (inst['end'] as TimeOfDay).format(
                          context,
                        ) // Используем TimeOfDay.format
                        : 'Select',
                onTap: () async {
                  final time = await _pickTime(context, inst['end']);
                  if (time != null) setState(() => inst['end'] = time);
                },
                color: theme.accentColor,
                icon: CupertinoIcons.time_solid,
              ),
              SizedBox(height: CupertinoFormTheme.elementSpacing),
              CupertinoButton(
                child: const Text('Remove'),
                onPressed: () => setState(() => _weeklyInstances.remove(inst)),
              ),
            ],
          );
        }),
      );

      widgets.add(SizedBox(height: CupertinoFormTheme.elementSpacing));
      widgets.add(
        CupertinoFormWidgets.primaryButton(
          context: context,
          text: 'Add Day',
          onPressed: () => _showWeeklyDayPicker(context),
        ),
      );
    }

    return widgets;
  }

  /// Builds options for monthly frequency (specific days or pattern).
  Widget _buildMonthlyOptions(BuildContext context, CupertinoFormTheme theme) {
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

    List<Widget> monthlyWidgets = [
      SizedBox(height: CupertinoFormTheme.elementSpacing),
      Text('Select Type', style: theme.labelTextStyle),
      SizedBox(height: CupertinoFormTheme.smallSpacing),
      CupertinoFormWidgets.segmentedControl(
        context: context,
        children: monthlyTypeWidgets,
        groupValue: _monthlyType,
        onValueChanged: (value) => setState(() => _monthlyType = value),
      ),
      SizedBox(height: CupertinoFormTheme.elementSpacing),
    ];

    if (_monthlyType == 'specific') {
      monthlyWidgets.addAll(_buildMonthlySpecificWidgets(context, theme));
    } else {
      monthlyWidgets.addAll(_buildMonthlyPatternWidgets(context, theme));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: monthlyWidgets,
    );
  }

  /// Builds widgets for monthly specific days with multiple instances.
  List<Widget> _buildMonthlySpecificWidgets(
    BuildContext context,
    CupertinoFormTheme theme,
  ) {
    List<Widget> widgets = [];

    if (_monthlySpecificInstances.isEmpty) {
      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No specific days added yet', style: theme.labelTextStyle),
            SizedBox(height: CupertinoFormTheme.elementSpacing),
            CupertinoFormWidgets.primaryButton(
              context: context,
              text: 'Add Day',
              onPressed: () => _showMonthlySpecificDayPicker(context),
            ),
          ],
        ),
      );
    } else {
      widgets.addAll(
        _monthlySpecificInstances.map((inst) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: CupertinoFormTheme.elementSpacing),
              Text('Day: ${inst['day']}', style: theme.labelTextStyle),
              SizedBox(height: CupertinoFormTheme.smallSpacing),
              CupertinoFormWidgets.textField(
                context: context,
                controller: inst['nameController'],
                placeholder: 'Habit Name *',
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: CupertinoFormTheme.elementSpacing),
              CupertinoFormWidgets.selectionButton(
                context: context,
                label: 'Start Time',
                value:
                    inst['start'] != null
                        ? inst['start'].format(context)
                        : 'Select',
                // Updated to TimeOfDay.format
                onTap: () async {
                  final time = await _pickTime(context, inst['start']);
                  if (time != null) setState(() => inst['start'] = time);
                },
                color: theme.secondaryColor,
                icon: CupertinoIcons.time,
              ),
              SizedBox(height: CupertinoFormTheme.elementSpacing),
              CupertinoFormWidgets.selectionButton(
                context: context,
                label: 'End Time',
                value:
                    inst['end'] != null
                        ? inst['end'].format(context)
                        : 'Select',
                // Updated to TimeOfDay.format
                onTap: () async {
                  final time = await _pickTime(context, inst['end']);
                  if (time != null) setState(() => inst['end'] = time);
                },
                color: theme.accentColor,
                icon: CupertinoIcons.time_solid,
              ),
              SizedBox(height: CupertinoFormTheme.elementSpacing),
              CupertinoButton(
                child: const Text('Remove'),
                onPressed:
                    () =>
                        setState(() => _monthlySpecificInstances.remove(inst)),
              ),
            ],
          );
        }),
      );

      widgets.add(SizedBox(height: CupertinoFormTheme.elementSpacing));
      widgets.add(
        CupertinoFormWidgets.primaryButton(
          context: context,
          text: 'Add Day',
          onPressed: () => _showMonthlySpecificDayPicker(context),
        ),
      );
    }

    return widgets;
  }

  /// Builds widgets for monthly pattern with a single instance.
  List<Widget> _buildMonthlyPatternWidgets(
    BuildContext context,
    CupertinoFormTheme theme,
  ) {
    return [
      Text('Select Week', style: theme.labelTextStyle),
      SizedBox(height: CupertinoFormTheme.smallSpacing),
      CupertinoFormWidgets.selectionButton(
        context: context,
        label: 'Week',
        value: _monthlyWeek?.capitalize() ?? 'Select',
        onTap: () => _showMonthlyWeekPicker(context),
        color: theme.primaryColor,
        icon: CupertinoIcons.calendar,
      ),
      SizedBox(height: CupertinoFormTheme.elementSpacing),
      Text('Select Day of Week', style: theme.labelTextStyle),
      SizedBox(height: CupertinoFormTheme.smallSpacing),
      CupertinoFormWidgets.selectionButton(
        context: context,
        label: 'Day',
        value: _monthlyDayOfWeek?.capitalize() ?? 'Select',
        onTap: () => _showMonthlyDayOfWeekPicker(context),
        color: theme.secondaryColor,
        icon: CupertinoIcons.calendar_today,
      ),
      SizedBox(height: CupertinoFormTheme.elementSpacing),
      ..._buildSingleInstanceWidgets(context, theme),
    ];
  }

  Widget _buildCategorySection(BuildContext context, CupertinoFormTheme theme) {
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
      context: context,
      title: 'Category',
      children: [
        CupertinoFormWidgets.segmentedControl(
          context: context,
          children: categoryWidgets,
          groupValue: _selectedCategory,
          onValueChanged: _handleCategoryChange,
        ),
      ],
    );
  }

  Future<void> _showDatePicker(BuildContext context, bool isStart) async {
    final pickedDate = await CupertinoFormWidgets.showDatePicker(
      context: context,
      initialDate: isStart ? _selectedStartDate : _selectedEndDate,
    );
    if (pickedDate != null && mounted) {
      setState(
        () => isStart ? _selectedStartDate : _selectedEndDate = pickedDate,
      );
    }
  }

  Future<TimeOfDay?> _pickTime(
    BuildContext context,
    TimeOfDay? initialTime,
  ) async {
    final now = DateTime.now();
    final initialDateTime =
        initialTime != null
            ? DateTime(
              _selectedStartDate.year,
              _selectedStartDate.month,
              _selectedStartDate.day,
              initialTime.hour,
              initialTime.minute,
            )
            : DateTime(
              _selectedStartDate.year,
              _selectedStartDate.month,
              _selectedStartDate.day,
              now.hour,
              now.minute,
            );

    final pickedTime = await CupertinoFormWidgets.showTimePicker(
      context: context,
      initialTime: initialDateTime,
    );
    return pickedTime != null
        ? TimeOfDay(hour: pickedTime.hour, minute: pickedTime.minute)
        : null; // Convert DateTime to TimeOfDay
  }

  Future<void> _showWeeklyDayPicker(BuildContext context) async {
    await _showDayOfWeekPicker(context, (day) {
      if (day != null && !_weeklyInstances.any((inst) => inst['day'] == day)) {
        setState(() {
          _weeklyInstances.add({
            'day': day,
            'nameController': TextEditingController(),
            'start': null,
            'end': null,
          });
        });
      }
    });
  }

  Future<void> _showDayOfWeekPicker(
    BuildContext context,
    Function(String?) onSelected,
  ) async {
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

  Future<void> _showMonthlySpecificDayPicker(BuildContext context) async {
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
                            !_monthlySpecificInstances.any(
                              (inst) => inst['day'] == selectedDay,
                            )) {
                          setState(() {
                            _monthlySpecificInstances.add({
                              'day': selectedDay,
                              'nameController': TextEditingController(),
                              'start': null,
                              'end': null,
                            });
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
    final theme = CupertinoFormTheme(context);
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
                decoration: theme.inputDecoration,
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

  /// Saves the habit by creating a RepeatRule and invoking the TaskManagerCubit.
  void _saveTask(BuildContext context) {
    // Arrange: Validate the form
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

    // Act: Create the RepeatRule based on frequency type
    RepeatRule? repeatRule;
    if (_selectedFrequencyType == 'daily' ||
        _selectedFrequencyType == 'yearly') {
      if (_nameController.text.isEmpty ||
          _startTime == null ||
          _endTime == null) {
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Validation Error'),
                content: const Text(
                  'Please provide habit name, start time, and end time.',
                ),
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
      repeatRule = RepeatRule(
        type: _selectedFrequencyType,
        interval: _intervalValue,
        startRepeat: _selectedStartDate,
        endRepeat: _selectedEndDate,
        byDay: [
          RepeatRuleInstance(
            selectedDay: _selectedFrequencyType,
            // 'daily' or 'yearly' as identifier
            name: _nameController.text,
            start: _startTime!,
            end: _endTime!,
          ),
        ],
      );
    } else if (_selectedFrequencyType == 'weekly') {
      if (_weeklyInstances.isEmpty ||
          _weeklyInstances.any(
            (inst) =>
                inst['nameController'].text.isEmpty ||
                inst['start'] == null ||
                inst['end'] == null,
          )) {
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Validation Error'),
                content: const Text(
                  'Please provide details for all weekly habits.',
                ),
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
      repeatRule = RepeatRule(
        type: 'weekly',
        interval: _intervalValue,
        startRepeat: _selectedStartDate,
        endRepeat: _selectedEndDate,
        byDay:
            _weeklyInstances
                .map(
                  (inst) => RepeatRuleInstance(
                    selectedDay: inst['day'],
                    name: inst['nameController'].text,
                    start: inst['start'],
                    end: inst['end'],
                  ),
                )
                .toList(),
      );
    } else if (_selectedFrequencyType == 'monthly') {
      if (_monthlyType == 'specific') {
        if (_monthlySpecificInstances.isEmpty ||
            _monthlySpecificInstances.any(
              (inst) =>
                  inst['nameController'].text.isEmpty ||
                  inst['start'] == null ||
                  inst['end'] == null,
            )) {
          showCupertinoDialog(
            context: context,
            builder:
                (context) => CupertinoAlertDialog(
                  title: const Text('Validation Error'),
                  content: const Text(
                    'Please provide details for all monthly specific days.',
                  ),
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
        repeatRule = RepeatRule(
          type: 'monthly',
          interval: _intervalValue,
          startRepeat: _selectedStartDate,
          endRepeat: _selectedEndDate,
          byMonthDay:
              _monthlySpecificInstances
                  .map(
                    (inst) => RepeatRuleInstance(
                      selectedDay: inst['day'].toString(),
                      name: inst['nameController'].text,
                      start: inst['start'],
                      end: inst['end'],
                    ),
                  )
                  .toList(),
        );
      } else {
        // pattern
        if (_monthlyWeek == null ||
            _monthlyDayOfWeek == null ||
            _nameController.text.isEmpty ||
            _startTime == null ||
            _endTime == null) {
          showCupertinoDialog(
            context: context,
            builder:
                (context) => CupertinoAlertDialog(
                  title: const Text('Validation Error'),
                  content: const Text(
                    'Please provide all details for the monthly pattern.',
                  ),
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
        repeatRule = RepeatRule(
          type: 'monthly',
          interval: _intervalValue,
          startRepeat: _selectedStartDate,
          endRepeat: _selectedEndDate,
          bySetPos: _getSetPosFromWeek(_monthlyWeek!),
          byDay: [
            RepeatRuleInstance(
              selectedDay: _monthlyDayOfWeek!,
              name: _nameController.text,
              start: _startTime!,
              end: _endTime!,
            ),
          ],
        );
      }
    }

    context.read<TaskManagerCubit>().createTask(
      title: _titleController.text,
      priority: {'Low': 0, 'Normal': 1, 'High': 2}[_priority] ?? 1,
      deadline: 0,
      estimatedTime: 0,
      // Duration is handled per instance in RepeatRule
      category: Category(name: _selectedCategory),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      frequency: repeatRule,
    );

    // Assert: Navigate back to HomeScreen
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (_) => HomeScreen(initialIndex: 0)),
    );
    logInfo('Saved Habit: ${_titleController.text}');
  }
}
