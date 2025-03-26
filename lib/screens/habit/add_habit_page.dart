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
import '../../services/category_service.dart';

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
  List<String> _categoryOptions = [];
  final CategoryService _categoryService = CategoryService();

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
        widget.selectedDate ?? DateTime.now().add(const Duration(days: 7));

    _nameController = TextEditingController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Load categories from storage
    _loadCategories();
  }

  // Load categories from Hive storage
  Future<void> _loadCategories() async {
    final categories = await _categoryService.getCategories();
    setState(() {
      _categoryOptions = categories;
      if (!_categoryOptions.contains('Add')) {
        _categoryOptions.add('Add');
      }
      if (_categoryOptions.isNotEmpty && _categoryOptions.length > 1) {
        _selectedCategory = _categoryOptions[0];
      }
    });
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
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0, // Match CupertinoTaskForm.horizontalSpacing
            vertical: 16.0, // Match CupertinoTaskForm.verticalSpacing
          ),
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
                    SizedBox(
                      height: 12.0,
                    ), // Match CupertinoTaskForm.elementSpacing
                    CupertinoFormWidgets.textField(
                      context: context,
                      controller: _notesController,
                      placeholder: 'Notes',
                      maxLines: 3,
                    ),
                  ],
                ),
                SizedBox(
                  height: 24.0,
                ), // Match CupertinoTaskForm.sectionSpacing
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
                      iconSize: 20.0, // Match typical Cupertino icon size
                    ),
                  ],
                ),
                SizedBox(
                  height: 24.0,
                ), // Match CupertinoTaskForm.sectionSpacing
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
                      iconSize: 20.0, // Match typical Cupertino icon size
                    ),
                  ],
                ),
                SizedBox(
                  height: 24.0,
                ), // Match CupertinoTaskForm.sectionSpacing
                _buildFrequencySection(context, theme),
                SizedBox(
                  height: 24.0,
                ), // Match CupertinoTaskForm.sectionSpacing
                _buildCategorySection(context, theme),
                SizedBox(
                  height: 48.0,
                ), // Match CupertinoTaskForm.sectionSpacing * 2
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

    List<Widget> frequencyWidgets = [
      Text('Repeat Type', style: theme.labelTextStyle),
      SizedBox(height: 8.0), // Match CupertinoFormTheme.smallSpacing
      Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 8.0, // Match CupertinoFormTheme.smallSpacing
          vertical: 4.0, // Match CupertinoFormTheme.smallSpacing / 2
        ),
        decoration: BoxDecoration(
          color:
              CupertinoTheme.of(context).brightness == Brightness.dark
                  ? CupertinoColors.systemGrey6.darkColor
                  : CupertinoColors.systemGrey6.color,
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: const EdgeInsets.all(4.0),
        child: CupertinoSlidingSegmentedControl<String>(
          thumbColor:
              CupertinoTheme.of(context).brightness == Brightness.dark
                  ? CupertinoColors.systemGrey4.darkColor
                  : CupertinoColors.white,
          backgroundColor: CupertinoColors.transparent,
          children: {
            for (var type in frequencyTypes)
              type: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6.0, // Match AddTaskPage
                  horizontal: 8.0, // Match AddTaskPage
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type == 'daily'
                          ? CupertinoIcons.calendar_today
                          : type == 'weekly'
                          ? CupertinoIcons.calendar_badge_plus
                          : type == 'monthly'
                          ? CupertinoIcons.calendar
                          : CupertinoIcons.calendar_circle,
                      size: 24.0, // Match AddTaskPage
                      color:
                          _selectedFrequencyType == type
                              ? CupertinoTheme.of(context).primaryColor
                              : CupertinoTheme.of(
                                context,
                              ).textTheme.textStyle.color,
                    ),
                    SizedBox(height: 4.0), // Match AddTaskPage
                    Text(
                      type.capitalize(),
                      style: TextStyle(
                        fontSize: 12.0, // Match AddTaskPage
                        fontWeight:
                            _selectedFrequencyType == type
                                ? FontWeight
                                    .w600 // Match AddTaskPage
                                : FontWeight.normal,
                        color:
                            _selectedFrequencyType == type
                                ? CupertinoTheme.of(context).primaryColor
                                : CupertinoTheme.of(
                                  context,
                                ).textTheme.textStyle.color,
                      ),
                    ),
                  ],
                ),
              ),
          },
          groupValue: _selectedFrequencyType,
          onValueChanged: (value) {
            if (value != null) {
              setState(() => _selectedFrequencyType = value);
            }
          },
        ),
      ),
      SizedBox(height: 12.0), // Match CupertinoTaskForm.elementSpacing
      Text('Repeat Every', style: theme.labelTextStyle),
      SizedBox(height: 8.0), // Match CupertinoFormTheme.smallSpacing
      Container(
        decoration: BoxDecoration(
          color:
              CupertinoTheme.of(context).brightness == Brightness.dark
                  ? CupertinoColors.systemGrey6.darkColor
                  : CupertinoColors.systemGrey6.color,
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
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
            SizedBox(width: 8.0), // Match CupertinoFormTheme.smallSpacing
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
      SizedBox(height: 12.0), // Match CupertinoTaskForm.elementSpacing
      Text('Habit Details', style: theme.labelTextStyle),
      SizedBox(height: 8.0), // Match CupertinoFormTheme.smallSpacing
      CupertinoFormWidgets.textField(
        context: context,
        controller: _nameController,
        placeholder: 'Habit Name *',
        validator: (value) => value!.isEmpty ? 'Required' : null,
      ),
      SizedBox(height: 12.0), // Match CupertinoTaskForm.elementSpacing
      CupertinoFormWidgets.selectionButton(
        context: context,
        label: 'Start Time',
        value: _startTime != null ? _startTime!.format(context) : 'Select',
        onTap: () async {
          final time = await _pickTime(context, _startTime);
          if (time != null) setState(() => _startTime = time);
        },
        color: theme.secondaryColor,
        icon: CupertinoIcons.time,
        iconSize: 20.0, // Match typical Cupertino icon size
      ),
      SizedBox(height: 12.0), // Match CupertinoTaskForm.elementSpacing
      CupertinoFormWidgets.selectionButton(
        context: context,
        label: 'End Time',
        value: _endTime != null ? _endTime!.format(context) : 'Select',
        onTap: () async {
          final time = await _pickTime(context, _endTime);
          if (time != null) setState(() => _endTime = time);
        },
        color: theme.accentColor,
        icon: CupertinoIcons.time_solid,
        iconSize: 20.0, // Match typical Cupertino icon size
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
            SizedBox(height: 12.0), // Match CupertinoTaskForm.elementSpacing
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
              SizedBox(height: 12.0), // Match CupertinoTaskForm.elementSpacing
              Text('Day: $capitalizedDay', style: theme.labelTextStyle),
              SizedBox(height: 8.0), // Match CupertinoFormTheme.smallSpacing
              CupertinoFormWidgets.textField(
                context: context,
                controller: inst['nameController'],
                placeholder: 'Habit Name *',
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 12.0), // Match CupertinoTaskForm.elementSpacing
              CupertinoFormWidgets.selectionButton(
                context: context,
                label: 'Start Time',
                value:
                    inst['start'] != null
                        ? (inst['start'] as TimeOfDay).format(context)
                        : 'Select',
                onTap: () async {
                  final time = await _pickTime(context, inst['start']);
                  if (time != null) setState(() => inst['start'] = time);
                },
                color: theme.secondaryColor,
                icon: CupertinoIcons.time,
                iconSize: 20.0, // Match typical Cupertino icon size
              ),
              SizedBox(height: 12.0), // Match CupertinoTaskForm.elementSpacing
              CupertinoFormWidgets.selectionButton(
                context: context,
                label: 'End Time',
                value:
                    inst['end'] != null
                        ? (inst['end'] as TimeOfDay).format(context)
                        : 'Select',
                onTap: () async {
                  final time = await _pickTime(context, inst['end']);
                  if (time != null) setState(() => inst['end'] = time);
                },
                color: theme.accentColor,
                icon: CupertinoIcons.time_solid,
                iconSize: 20.0, // Match typical Cupertino icon size
              ),
              SizedBox(height: 12.0), // Match CupertinoTaskForm.elementSpacing
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: const Text('Remove', style: TextStyle(fontSize: 14.0)),
                onPressed: () => setState(() => _weeklyInstances.remove(inst)),
              ),
            ],
          );
        }),
      );

      widgets.add(
        SizedBox(height: 12.0),
      ); // Match CupertinoTaskForm.elementSpacing
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
    List<Widget> monthlyWidgets = [
      SizedBox(height: 12.0), // Match CupertinoTaskForm.elementSpacing
      Text('Select Type', style: theme.labelTextStyle),
      SizedBox(height: 8.0), // Match CupertinoFormTheme.smallSpacing
      Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 8.0, // Match CupertinoFormTheme.smallSpacing
          vertical: 4.0, // Match CupertinoFormTheme.smallSpacing / 2
        ),
        decoration: BoxDecoration(
          color:
              CupertinoTheme.of(context).brightness == Brightness.dark
                  ? CupertinoColors.systemGrey6.darkColor
                  : CupertinoColors.systemGrey6.color,
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: const EdgeInsets.all(4.0),
        child: CupertinoSlidingSegmentedControl<String>(
          thumbColor:
              CupertinoTheme.of(context).brightness == Brightness.dark
                  ? CupertinoColors.systemGrey4.darkColor
                  : CupertinoColors.white,
          backgroundColor: CupertinoColors.transparent,
          children: {
            'specific': Container(
              padding: const EdgeInsets.symmetric(
                vertical: 6.0, // Match AddTaskPage
                horizontal: 8.0, // Match AddTaskPage
              ),
              child: Text(
                'Specific Days',
                style: TextStyle(
                  fontSize: 12.0, // Match AddTaskPage
                  fontWeight:
                      _monthlyType == 'specific'
                          ? FontWeight
                              .w600 // Match AddTaskPage
                          : FontWeight.normal,
                ),
              ),
            ),
            'pattern': Container(
              padding: const EdgeInsets.symmetric(
                vertical: 6.0, // Match AddTaskPage
                horizontal: 8.0, // Match AddTaskPage
              ),
              child: Text(
                'Pattern',
                style: TextStyle(
                  fontSize: 12.0, // Match AddTaskPage
                  fontWeight:
                      _monthlyType == 'pattern'
                          ? FontWeight
                              .w600 // Match AddTaskPage
                          : FontWeight.normal,
                ),
              ),
            ),
          },
          groupValue: _monthlyType,
          onValueChanged: (value) => setState(() => _monthlyType = value!),
        ),
      ),
      SizedBox(height: 12.0), // Match CupertinoTaskForm.elementSpacing
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
            SizedBox(height: 12.0), // Match CupertinoTaskForm.elementSpacing
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
              SizedBox(height: 12.0), // Match CupertinoTaskForm.elementSpacing
              Text('Day: ${inst['day']}', style: theme.labelTextStyle),
              SizedBox(height: 8.0), // Match CupertinoFormTheme.smallSpacing
              CupertinoFormWidgets.textField(
                context: context,
                controller: inst['nameController'],
                placeholder: 'Habit Name *',
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 12.0), // Match CupertinoTaskForm.elementSpacing
              CupertinoFormWidgets.selectionButton(
                context: context,
                label: 'Start Time',
                value:
                    inst['start'] != null
                        ? inst['start'].format(context)
                        : 'Select',
                onTap: () async {
                  final time = await _pickTime(context, inst['start']);
                  if (time != null) setState(() => inst['start'] = time);
                },
                color: theme.secondaryColor,
                icon: CupertinoIcons.time,
                iconSize: 20.0, // Match typical Cupertino icon size
              ),
              SizedBox(height: 12.0), // Match CupertinoTaskForm.elementSpacing
              CupertinoFormWidgets.selectionButton(
                context: context,
                label: 'End Time',
                value:
                    inst['end'] != null
                        ? inst['end'].format(context)
                        : 'Select',
                onTap: () async {
                  final time = await _pickTime(context, inst['end']);
                  if (time != null) setState(() => inst['end'] = time);
                },
                color: theme.accentColor,
                icon: CupertinoIcons.time_solid,
                iconSize: 20.0, // Match typical Cupertino icon size
              ),
              SizedBox(height: 12.0), // Match CupertinoTaskForm.elementSpacing
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: const Text('Remove', style: TextStyle(fontSize: 14.0)),
                onPressed:
                    () =>
                        setState(() => _monthlySpecificInstances.remove(inst)),
              ),
            ],
          );
        }),
      );

      widgets.add(
        SizedBox(height: 12.0),
      ); // Match CupertinoTaskForm.elementSpacing
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
      SizedBox(height: 8.0), // Match CupertinoFormTheme.smallSpacing
      CupertinoFormWidgets.selectionButton(
        context: context,
        label: 'Week',
        value: _monthlyWeek?.capitalize() ?? 'Select',
        onTap: () => _showMonthlyWeekPicker(context),
        color: theme.primaryColor,
        icon: CupertinoIcons.calendar,
        iconSize: 20.0, // Match typical Cupertino icon size
      ),
      SizedBox(height: 12.0), // Match CupertinoTaskForm.elementSpacing
      Text('Select Day of Week', style: theme.labelTextStyle),
      SizedBox(height: 8.0), // Match CupertinoFormTheme.smallSpacing
      CupertinoFormWidgets.selectionButton(
        context: context,
        label: 'Day',
        value: _monthlyDayOfWeek?.capitalize() ?? 'Select',
        onTap: () => _showMonthlyDayOfWeekPicker(context),
        color: theme.secondaryColor,
        icon: CupertinoIcons.calendar_today,
        iconSize: 20.0, // Match typical Cupertino icon size
      ),
      SizedBox(height: 12.0), // Match CupertinoTaskForm.elementSpacing
      ..._buildSingleInstanceWidgets(context, theme),
    ];
  }

  Widget _buildCategorySection(BuildContext context, CupertinoFormTheme theme) {
    // Ensure we have at least 2 categories for the segmented control
    if (_categoryOptions.length < 2) {
      return CupertinoFormWidgets.formGroup(
        context: context,
        title: 'Category',
        children: [
          if (_categoryOptions.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 12.0, // Match CupertinoTaskForm.elementSpacing
              ),
              child: Text(
                'Current category: $_selectedCategory',
                style: theme.valueTextStyle,
              ),
            ),
          Center(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: CupertinoTheme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
              onPressed: () => _showAddCategoryDialog(context),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.add, size: 16.0), // Match AddTaskPage
                  SizedBox(width: 4),
                  Text(
                    'Add Category',
                    style: TextStyle(fontSize: 14.0),
                  ), // Match AddTaskPage
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Regular UI with segmented control for 2+ categories
    return CupertinoFormWidgets.formGroup(
      context: context,
      title: 'Category',
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 8.0, // Match CupertinoFormTheme.smallSpacing
              vertical: 4.0, // Match CupertinoFormTheme.smallSpacing / 2
            ),
            decoration: BoxDecoration(
              color:
                  CupertinoTheme.of(context).brightness == Brightness.dark
                      ? CupertinoColors.systemGrey6.darkColor
                      : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(10),
            ),
            child: CupertinoSegmentedControl(
              children: {
                for (var category in _categoryOptions)
                  category: _buildCategoryOption(
                    text: category,
                    icon: _getCategoryIcon(category),
                    isDarkMode:
                        CupertinoTheme.of(context).brightness ==
                        Brightness.dark,
                  ),
              },
              groupValue: _selectedCategory,
              onValueChanged: _handleCategoryChange,
              borderColor: CupertinoColors.transparent,
              selectedColor:
                  CupertinoTheme.of(context).brightness == Brightness.dark
                      ? CupertinoColors.systemBackground.darkColor
                      : CupertinoColors.white,
              unselectedColor: CupertinoColors.transparent,
              pressedColor: CupertinoTheme.of(
                context,
              ).primaryColor.withOpacity(0.1),
            ),
          ),
        ),
        SizedBox(height: 12.0), // Match CupertinoTaskForm.elementSpacing
        Center(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: CupertinoTheme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            onPressed: () => _showCategoryManagerDialog(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.settings, size: 16.0), // Match AddTaskPage
                SizedBox(width: 4),
                Text(
                  'Manage Categories',
                  style: TextStyle(fontSize: 14.0),
                ), // Match AddTaskPage
              ],
            ),
          ),
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
        : null;
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
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 14.0),
                      ),
                      onPressed: () {
                        onSelected(null);
                        Navigator.pop(context);
                      },
                    ),
                    CupertinoButton(
                      child: const Text(
                        'Select',
                        style: TextStyle(fontSize: 14.0),
                      ),
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
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 14.0),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text(
                        'Add',
                        style: TextStyle(fontSize: 14.0),
                      ),
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
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 14.0),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text(
                        'Select',
                        style: TextStyle(fontSize: 14.0),
                      ),
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
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 14.0),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text(
                        'Select',
                        style: TextStyle(fontSize: 14.0),
                      ),
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
              padding: const EdgeInsets.only(top: 12),
              child: CupertinoTextField(
                controller: controller,
                placeholder: 'Category Name',
                padding: const EdgeInsets.all(10),
                decoration: theme.inputDecoration,
                style: const TextStyle(
                  fontSize: 16.0,
                ), // Match Cupertino default
                autofocus: true,
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel', style: TextStyle(fontSize: 14.0)),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Add', style: TextStyle(fontSize: 14.0)),
                onPressed: () async {
                  final newCategory = controller.text.trim();
                  if (newCategory.isNotEmpty &&
                      mounted &&
                      !_categoryOptions.contains(newCategory) &&
                      newCategory != 'Add') {
                    await _categoryService.addCategory(newCategory);
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

  Widget _buildCategoryOption({
    required String text,
    required IconData icon,
    required bool isDarkMode,
  }) {
    final textColor =
        isDarkMode
            ? _selectedCategory == text
                ? CupertinoColors.activeBlue
                : CupertinoColors.white
            : _selectedCategory == text
            ? CupertinoTheme.of(context).primaryColor
            : CupertinoColors.black;

    final iconColor = textColor;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0, // Match AddTaskPage
        vertical: 6.0, // Match AddTaskPage
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24.0, color: iconColor), // Match AddTaskPage
          SizedBox(height: 4.0), // Match AddTaskPage
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.0, // Match AddTaskPage
                color: textColor,
                fontWeight:
                    _selectedCategory == text
                        ? FontWeight
                            .w600 // Match AddTaskPage
                        : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final Map<String, IconData> icons = {
      'Brainstorm': CupertinoIcons.lightbulb,
      'Design': CupertinoIcons.pencil_outline,
      'Workout': CupertinoIcons.heart,
      'Add': CupertinoIcons.add,
    };
    return icons[category] ?? CupertinoIcons.tag;
  }

  void _showCategoryManagerDialog(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Text('Manage Categories'),
            message: const Text('Add, edit or delete task categories'),
            actions: [
              ...List.generate(
                _categoryOptions.length - 1, // Exclude "Add" option
                (index) => CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.pop(context);
                    _showCategoryActionSheet(
                      context,
                      _categoryOptions[index],
                      index,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getCategoryIcon(_categoryOptions[index]),
                            size: 16.0, // Match AddTaskPage
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _categoryOptions[index],
                            style: const TextStyle(
                              fontSize: 14.0,
                            ), // Match AddTaskPage
                          ),
                        ],
                      ),
                      const Icon(CupertinoIcons.ellipsis, size: 16.0),
                    ],
                  ),
                ),
              ),
              CupertinoActionSheetAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _showAddCategoryDialog(context);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.add_circled,
                      size: 16.0,
                    ), // Match AddTaskPage
                    SizedBox(width: 10),
                    Text(
                      'Add New Category',
                      style: TextStyle(fontSize: 14.0),
                    ), // Match AddTaskPage
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: const Text('Cancel', style: TextStyle(fontSize: 14.0)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String category,
    int index,
  ) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text('Delete "$category"?'),
            content: const Text(
              'This will remove the category from your list. Tasks with this category will not be affected.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel', style: TextStyle(fontSize: 14.0)),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Delete', style: TextStyle(fontSize: 14.0)),
                onPressed: () {
                  _deleteCategory(index);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  void _deleteCategory(int index) async {
    final deletedCategory = _categoryOptions[index];
    await _categoryService.deleteCategory(deletedCategory);
    setState(() {
      _categoryOptions.removeAt(index);
      if (_selectedCategory == deletedCategory) {
        _selectedCategory = _categoryOptions[0];
      }
      logInfo('Category deleted: $deletedCategory');
    });
  }

  void _showCategoryActionSheet(
    BuildContext context,
    String category,
    int index,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: Text(category),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _showEditCategoryDialog(context, category, index);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.pencil,
                      size: 16.0,
                    ), // Match AddTaskPage
                    SizedBox(width: 10),
                    Text(
                      'Edit Category',
                      style: TextStyle(fontSize: 14.0),
                    ), // Match AddTaskPage
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, category, index);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.delete,
                      size: 16.0,
                    ), // Match AddTaskPage
                    SizedBox(width: 10),
                    Text(
                      'Delete Category',
                      style: TextStyle(fontSize: 14.0),
                    ), // Match AddTaskPage
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: const Text('Cancel', style: TextStyle(fontSize: 14.0)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
    );
  }

  void _showEditCategoryDialog(
    BuildContext context,
    String category,
    int index,
  ) {
    final controller = TextEditingController(text: category);
    final theme = CupertinoFormTheme(context);
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text('Edit "$category"'),
            content: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: CupertinoTextField(
                controller: controller,
                padding: const EdgeInsets.all(10),
                decoration: theme.inputDecoration,
                style: const TextStyle(
                  fontSize: 16.0,
                ), // Match Cupertino default
                autofocus: true,
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel', style: TextStyle(fontSize: 14.0)),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Save', style: TextStyle(fontSize: 14.0)),
                onPressed: () async {
                  final newCategoryName = controller.text.trim();
                  if (newCategoryName.isNotEmpty &&
                      mounted &&
                      !_categoryOptions.contains(newCategoryName) &&
                      newCategoryName != 'Add') {
                    await _categoryService.updateCategory(
                      category,
                      newCategoryName,
                    );
                    setState(() {
                      _categoryOptions[index] = newCategoryName;
                      if (_selectedCategory == category) {
                        _selectedCategory = newCategoryName;
                      }
                      logInfo(
                        'Category renamed: $category -> $newCategoryName',
                      );
                    });
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  /// Saves the habit by creating a RepeatRule and invoking the TaskManagerCubit.
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
                  child: const Text('OK', style: TextStyle(fontSize: 14.0)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
      return;
    }

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
                    child: const Text('OK', style: TextStyle(fontSize: 14.0)),
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
                    child: const Text('OK', style: TextStyle(fontSize: 14.0)),
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
                      child: const Text('OK', style: TextStyle(fontSize: 14.0)),
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
                      child: const Text('OK', style: TextStyle(fontSize: 14.0)),
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
      category: Category(name: _selectedCategory),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      frequency: repeatRule,
    );

    Navigator.pop(
      context,
      CupertinoPageRoute(builder: (_) => HomeScreen(initialIndex: 0)),
    );
    logInfo('Saved Habit: ${_titleController.text}');
  }
}
