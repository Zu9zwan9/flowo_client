import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/models/repeat_rule.dart';
import 'package:flowo_client/models/repeat_rule_instance.dart';
import 'package:flowo_client/screens/home_screen.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../design/cupertino_form_theme.dart';
import '../../design/cupertino_form_widgets.dart';
import '../../models/task.dart';
import '../../models/user_settings.dart';
import '../../services/category_service.dart';
import '../../utils/formatter/date_time_formatter.dart';

extension StringExtension on String {
  String capitalize() =>
      isEmpty ? this : "${this[0].toUpperCase()}${substring(1)}";
}

class HabitFormScreen extends StatefulWidget {
  final DateTime? selectedDate;
  final Task? habit;

  const HabitFormScreen({super.key, this.selectedDate, this.habit});

  @override
  HabitFormScreenState createState() => HabitFormScreenState();
}

class HabitFormScreenState extends State<HabitFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _intervalController = TextEditingController(text: '1');

  late DateTime _selectedStartDate;
  late DateTime _selectedEndDate;

  String _selectedCategory = '';
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

  late TextEditingController _nameController;
  late UserSettings _userSettings;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final List<Map<String, dynamic>> _weeklyInstances = [];
  final List<Map<String, dynamic>> _monthlySpecificInstances = [];

  @override
  void initState() {
    super.initState();
    _userSettings = context.read<TaskManagerCubit>().taskManager.userSettings;

    if (widget.habit != null) {
      final habit = widget.habit!;
      _titleController.text = habit.title;
      _notesController.text = habit.notes ?? '';
      _selectedCategory = habit.category.name;
      _selectedStartDate = DateTime.fromMillisecondsSinceEpoch(habit.deadline);
      _selectedEndDate =
          habit.frequency?.endRepeat ??
          _selectedStartDate.add(const Duration(days: 7));

      _nameController = TextEditingController();

      if (habit.frequency != null) {
        final repeatRule = habit.frequency!;
        _selectedFrequencyType = repeatRule.type.toLowerCase();
        _intervalController.text = repeatRule.interval.toString();
        _intervalValue = repeatRule.interval;

        if (_selectedFrequencyType == 'daily' ||
            _selectedFrequencyType == 'yearly') {
          if (repeatRule.byDay != null && repeatRule.byDay!.isNotEmpty) {
            final instance = repeatRule.byDay![0];
            _nameController.text = instance.name;
            _startTime = instance.start;
            _endTime = instance.end;
          }
        } else if (_selectedFrequencyType == 'weekly') {
          _weeklyInstances.clear();
          for (var instance in repeatRule.byDay ?? []) {
            _weeklyInstances.add({
              'day': instance.selectedDay,
              'nameController': TextEditingController(text: instance.name),
              'start': instance.start,
              'end': instance.end,
            });
          }
        } else if (_selectedFrequencyType == 'monthly') {
          if (repeatRule.byMonthDay != null) {
            _monthlyType = 'specific';
            _monthlySpecificInstances.clear();
            for (var instance in repeatRule.byMonthDay!) {
              _monthlySpecificInstances.add({
                'day': int.tryParse(instance.selectedDay) ?? 1,
                'nameController': TextEditingController(text: instance.name),
                'start': instance.start,
                'end': instance.end,
              });
            }
          } else if (repeatRule.bySetPos != null && repeatRule.byDay != null) {
            _monthlyType = 'pattern';
            _monthlyWeek = _getWeekFromSetPos(repeatRule.bySetPos!);
            if (repeatRule.byDay!.isNotEmpty) {
              final instance = repeatRule.byDay![0];
              _monthlyDayOfWeek = instance.selectedDay;
              _nameController.text = instance.name;
              _startTime = instance.start;
              _endTime = instance.end;
            }
          }
        }
      }
    } else {
      // Создание новой привычки
      _selectedStartDate = widget.selectedDate ?? DateTime.now();
      _selectedEndDate = _selectedStartDate.add(const Duration(days: 7));
      _nameController = TextEditingController();
      _intervalController.text = '1';
      _intervalValue = 1;
      _selectedFrequencyType = 'weekly';
      _monthlyType = 'specific';
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _categoryService.getCategories();
    setState(() {
      _categoryOptions = categories;
      if (_categoryOptions.isNotEmpty && _selectedCategory.isEmpty) {
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

  String _getWeekFromSetPos(int setPos) {
    const setPosMap = {
      1: 'first',
      2: 'second',
      3: 'third',
      4: 'fourth',
      -1: 'last',
    };
    return setPosMap[setPos] ?? 'first';
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoFormTheme(context);
    return CupertinoPageScaffold(
      navigationBar:
          widget.habit != null
              ? CupertinoNavigationBar(middle: Text('Edit Habit'))
              : Navigator.canPop(context)
              ? CupertinoNavigationBar(middle: Text('Create Habit'))
              : null,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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
                    const SizedBox(height: 12.0),
                    CupertinoFormWidgets.textField(
                      context: context,
                      controller: _notesController,
                      placeholder: 'Notes',
                      maxLines: 3,
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),
                CupertinoFormWidgets.formGroup(
                  context: context,
                  title: 'Starts',
                  children: [
                    CupertinoFormWidgets.selectionButton(
                      context: context,
                      label: 'Date',
                      value: DateTimeFormatter.formatDate(
                        _selectedStartDate,
                        dateFormat: _userSettings.dateFormat,
                        monthFormat: _userSettings.monthFormat,
                      ),
                      onTap: () => _showDatePicker(context, true),
                      color: theme.primaryColor,
                      icon: CupertinoIcons.calendar,
                      iconSize: 20.0,
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),
                CupertinoFormWidgets.formGroup(
                  context: context,
                  title: 'Ends',
                  children: [
                    CupertinoFormWidgets.selectionButton(
                      context: context,
                      label: 'Date',
                      value: DateTimeFormatter.formatDate(
                        _selectedEndDate,
                        dateFormat: _userSettings.dateFormat,
                        monthFormat: _userSettings.monthFormat,
                      ),
                      onTap: () => _showDatePicker(context, false),
                      color: theme.primaryColor,
                      icon: CupertinoIcons.calendar,
                      iconSize: 20.0,
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),
                _buildFrequencySection(context, theme),
                const SizedBox(height: 24.0),
                _buildCategorySection(context, theme),
                const SizedBox(height: 48.0),
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

  Widget _buildFrequencySection(
    BuildContext context,
    CupertinoFormTheme theme,
  ) {
    final frequencyTypes = ['daily', 'weekly', 'monthly', 'yearly'];
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    final backgroundColor = CupertinoColors.systemGrey6.resolveFrom(context);

    List<Widget> frequencyWidgets = [
      Text('Repeat Type', style: theme.labelTextStyle),
      const SizedBox(height: 8.0),
      Container(
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children:
              frequencyTypes.map((type) {
                return _buildFrequencyTab(
                  type: type,
                  icon: _getFrequencyIcon(type),
                  primaryColor: primaryColor,
                );
              }).toList(),
        ),
      ),
      const SizedBox(height: 12.0),
      Text('Repeat Every', style: theme.labelTextStyle),
      const SizedBox(height: 8.0),
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
            const SizedBox(width: 8.0),
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

  Widget _buildFrequencyTab({
    required String type,
    required IconData icon,
    required Color primaryColor,
  }) {
    final isSelected = _selectedFrequencyType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedFrequencyType = type;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: double.infinity,
          decoration: BoxDecoration(
            color:
                isSelected
                    ? CupertinoColors.systemBackground.resolveFrom(context)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          margin: const EdgeInsets.all(2),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color:
                      isSelected
                          ? primaryColor
                          : CupertinoColors.systemGrey.resolveFrom(context),
                  semanticLabel: type.capitalize(),
                ),
                const SizedBox(width: 4),
                Text(
                  type.capitalize(),
                  style: TextStyle(
                    color:
                        isSelected
                            ? primaryColor
                            : CupertinoColors.systemGrey.resolveFrom(context),
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  semanticsLabel: '${type.capitalize()} frequency',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getFrequencyIcon(String type) {
    switch (type) {
      case 'daily':
        return CupertinoIcons.calendar_today;
      case 'weekly':
        return CupertinoIcons.calendar_badge_plus;
      case 'monthly':
        return CupertinoIcons.calendar;
      case 'yearly':
        return CupertinoIcons.calendar_circle;
      default:
        return CupertinoIcons.calendar;
    }
  }

  List<Widget> _buildSingleInstanceWidgets(
    BuildContext context,
    CupertinoFormTheme theme,
  ) {
    return [
      const SizedBox(height: 12.0),
      Text('Habit Details', style: theme.labelTextStyle),
      const SizedBox(height: 8.0),
      CupertinoFormWidgets.textField(
        context: context,
        controller: _nameController,
        placeholder: 'Habit Name *',
        validator: (value) => value!.isEmpty ? 'Required' : null,
      ),
      const SizedBox(height: 12.0),
      CupertinoFormWidgets.selectionButton(
        context: context,
        label: 'Start Time',
        value:
            _startTime != null
                ? DateTimeFormatter.formatTime(
                  DateTime(2023, 1, 1, _startTime!.hour, _startTime!.minute),
                  is24HourFormat: _userSettings.is24HourFormat,
                )
                : 'Select',
        onTap: () async {
          final time = await _pickTime(context, _startTime);
          if (time != null) setState(() => _startTime = time);
        },
        color: theme.secondaryColor,
        icon: CupertinoIcons.time,
        iconSize: 20.0,
      ),
      const SizedBox(height: 12.0),
      CupertinoFormWidgets.selectionButton(
        context: context,
        label: 'End Time',
        value:
            _endTime != null
                ? DateTimeFormatter.formatTime(
                  DateTime(2023, 1, 1, _endTime!.hour, _endTime!.minute),
                  is24HourFormat: _userSettings.is24HourFormat,
                )
                : 'Select',
        onTap: () async {
          final time = await _pickTime(context, _endTime);
          if (time != null) setState(() => _endTime = time);
        },
        color: theme.accentColor,
        icon: CupertinoIcons.time_solid,
        iconSize: 20.0,
      ),
    ];
  }

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
            const SizedBox(height: 12.0),
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
          final capitalizedDay = day.capitalize();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12.0),
              Text('Day: $capitalizedDay', style: theme.labelTextStyle),
              const SizedBox(height: 8.0),
              CupertinoFormWidgets.textField(
                context: context,
                controller: inst['nameController'],
                placeholder: 'Habit Name *',
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12.0),
              CupertinoFormWidgets.selectionButton(
                context: context,
                label: 'Start Time',
                value:
                    inst['start'] != null
                        ? DateTimeFormatter.formatTime(
                          DateTime(
                            2023,
                            1,
                            1,
                            (inst['start'] as TimeOfDay).hour,
                            (inst['start'] as TimeOfDay).minute,
                          ),
                          is24HourFormat: _userSettings.is24HourFormat,
                        )
                        : 'Select',
                onTap: () async {
                  final time = await _pickTime(context, inst['start']);
                  if (time != null) setState(() => inst['start'] = time);
                },
                color: theme.secondaryColor,
                icon: CupertinoIcons.time,
                iconSize: 20.0,
              ),
              const SizedBox(height: 12.0),
              CupertinoFormWidgets.selectionButton(
                context: context,
                label: 'End Time',
                value:
                    inst['end'] != null
                        ? DateTimeFormatter.formatTime(
                          DateTime(
                            2023,
                            1,
                            1,
                            (inst['end'] as TimeOfDay).hour,
                            (inst['end'] as TimeOfDay).minute,
                          ),
                          is24HourFormat: _userSettings.is24HourFormat,
                        )
                        : 'Select',
                onTap: () async {
                  final time = await _pickTime(context, inst['end']);
                  if (time != null) setState(() => inst['end'] = time);
                },
                color: theme.accentColor,
                icon: CupertinoIcons.time_solid,
                iconSize: 20.0,
              ),
              const SizedBox(height: 12.0),
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
      widgets.add(const SizedBox(height: 12.0));
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

  Widget _buildMonthlyOptions(BuildContext context, CupertinoFormTheme theme) {
    List<Widget> monthlyWidgets = [
      const SizedBox(height: 12.0),
      Text('Select Type', style: theme.labelTextStyle),
      const SizedBox(height: 8.0),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
                vertical: 6.0,
                horizontal: 8.0,
              ),
              child: Text(
                'Specific Days',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight:
                      _monthlyType == 'specific'
                          ? FontWeight.w600
                          : FontWeight.normal,
                ),
              ),
            ),
            'pattern': Container(
              padding: const EdgeInsets.symmetric(
                vertical: 6.0,
                horizontal: 8.0,
              ),
              child: Text(
                'Pattern',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight:
                      _monthlyType == 'pattern'
                          ? FontWeight.w600
                          : FontWeight.normal,
                ),
              ),
            ),
          },
          groupValue: _monthlyType,
          onValueChanged: (value) => setState(() => _monthlyType = value!),
        ),
      ),
      const SizedBox(height: 12.0),
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
            const SizedBox(height: 12.0),
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
              const SizedBox(height: 12.0),
              Text('Day: ${inst['day']}', style: theme.labelTextStyle),
              const SizedBox(height: 8.0),
              CupertinoFormWidgets.textField(
                context: context,
                controller: inst['nameController'],
                placeholder: 'Habit Name *',
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12.0),
              CupertinoFormWidgets.selectionButton(
                context: context,
                label: 'Start Time',
                value:
                    inst['start'] != null
                        ? DateTimeFormatter.formatTime(
                          DateTime(
                            2023,
                            1,
                            1,
                            (inst['start'] as TimeOfDay).hour,
                            (inst['start'] as TimeOfDay).minute,
                          ),
                          is24HourFormat: _userSettings.is24HourFormat,
                        )
                        : 'Select',
                onTap: () async {
                  final time = await _pickTime(context, inst['start']);
                  if (time != null) setState(() => inst['start'] = time);
                },
                color: theme.secondaryColor,
                icon: CupertinoIcons.time,
                iconSize: 20.0,
              ),
              const SizedBox(height: 12.0),
              CupertinoFormWidgets.selectionButton(
                context: context,
                label: 'End Time',
                value:
                    inst['end'] != null
                        ? DateTimeFormatter.formatTime(
                          DateTime(
                            2023,
                            1,
                            1,
                            (inst['end'] as TimeOfDay).hour,
                            (inst['end'] as TimeOfDay).minute,
                          ),
                          is24HourFormat: _userSettings.is24HourFormat,
                        )
                        : 'Select',
                onTap: () async {
                  final time = await _pickTime(context, inst['end']);
                  if (time != null) setState(() => inst['end'] = time);
                },
                color: theme.accentColor,
                icon: CupertinoIcons.time_solid,
                iconSize: 20.0,
              ),
              const SizedBox(height: 12.0),
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
      widgets.add(const SizedBox(height: 12.0));
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

  List<Widget> _buildMonthlyPatternWidgets(
    BuildContext context,
    CupertinoFormTheme theme,
  ) {
    return [
      Text('Select Week', style: theme.labelTextStyle),
      const SizedBox(height: 8.0),
      CupertinoFormWidgets.selectionButton(
        context: context,
        label: 'Week',
        value: _monthlyWeek?.capitalize() ?? 'Select',
        onTap: () => _showMonthlyWeekPicker(context),
        color: theme.primaryColor,
        icon: CupertinoIcons.calendar,
        iconSize: 20.0,
      ),
      const SizedBox(height: 12.0),
      Text('Select Day of Week', style: theme.labelTextStyle),
      const SizedBox(height: 8.0),
      CupertinoFormWidgets.selectionButton(
        context: context,
        label: 'Day',
        value: _monthlyDayOfWeek?.capitalize() ?? 'Select',
        onTap: () => _showMonthlyDayOfWeekPicker(context),
        color: theme.secondaryColor,
        icon: CupertinoIcons.calendar_today,
        iconSize: 20.0,
      ),
      const SizedBox(height: 12.0),
      ..._buildSingleInstanceWidgets(context, theme),
    ];
  }

  Widget _buildCategorySection(BuildContext context, CupertinoFormTheme theme) {
    return CupertinoFormWidgets.formGroup(
      context: context,
      title: 'Category',
      children: [
        CupertinoFormWidgets.selectionButton(
          context: context,
          label: 'Category',
          value:
              _categoryOptions.isEmpty ? 'Add a category' : _selectedCategory,
          onTap: () => _showCategoryManagerDialog(context),
          color: theme.primaryColor,
          icon: CupertinoIcons.tag,
          iconSize: 20.0,
        ),
      ],
    );
  }

  Future<void> _showDatePicker(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    DateTime initialDate = isStart ? _selectedStartDate : _selectedEndDate;
    initialDate = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
    );
    final minimumDate = DateTime(now.year, now.month, now.day);

    if (initialDate.isBefore(minimumDate)) {
      initialDate = minimumDate;
    }

    DateTime? selectedDate = initialDate;

    final pickedDate = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder:
          (context) => Container(
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
                      onPressed: () => Navigator.pop(context, selectedDate),
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate,
                    minimumDate: minimumDate,
                    maximumDate: DateTime.now().add(const Duration(days: 730)),
                    onDateTimeChanged: (dateTime) {
                      selectedDate = dateTime;
                    },
                  ),
                ),
              ],
            ),
          ),
    );

    if (pickedDate != null && mounted) {
      setState(() {
        if (isStart) {
          _selectedStartDate = pickedDate;
        } else {
          _selectedEndDate = pickedDate;
        }
      });
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
              now.year,
              now.month,
              now.day,
              initialTime.hour,
              initialTime.minute,
            )
            : DateTime(now.year, now.month, now.day, now.hour, now.minute);

    DateTime? selectedTime;

    final pickedTime = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder:
          (context) => Container(
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
                      onPressed: () => Navigator.pop(context, selectedTime),
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: initialDateTime,
                    use24hFormat: _userSettings.is24HourFormat,
                    onDateTimeChanged: (dateTime) {
                      selectedTime = dateTime;
                    },
                  ),
                ),
              ],
            ),
          ),
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
            color: CupertinoFormTheme(context).backgroundColor,
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
            color: CupertinoFormTheme(context).backgroundColor,
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
            color: CupertinoFormTheme(context).backgroundColor,
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
            color: CupertinoFormTheme(context).backgroundColor,
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
                style: const TextStyle(fontSize: 16.0),
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
                      !_categoryOptions.contains(newCategory)) {
                    await _categoryService.addCategory(newCategory);
                    setState(() {
                      _categoryOptions.add(newCategory);
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

  void _showCategoryManagerDialog(BuildContext context) {
    String tempSelectedCategory = _selectedCategory;

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => CupertinoActionSheet(
                  title: const Text('Manage Categories'),
                  message: const Text(
                    'Select, add, edit, or delete categories',
                  ),
                  actions: [
                    ...List.generate(_categoryOptions.length, (index) {
                      final category = _categoryOptions[index];
                      final isSelected = tempSelectedCategory == category;
                      return CupertinoActionSheetAction(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setDialogState(() {
                            tempSelectedCategory = category;
                          });
                        },
                        // TODO: remove space between button and edges in category selector
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          color:
                              isSelected
                                  ? CupertinoTheme.of(
                                    context,
                                  ).primaryColor.withOpacity(
                                    0.1,
                                  ) // Subtle background highlight
                                  : Colors.transparent,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getCategoryIcon(category),
                                    size: 16.0,
                                    color:
                                        isSelected
                                            ? CupertinoTheme.of(
                                              context,
                                            ).primaryColor
                                            : CupertinoColors.systemGrey,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      color:
                                          isSelected
                                              ? CupertinoTheme.of(
                                                context,
                                              ).primaryColor
                                              : CupertinoTheme.of(
                                                    context,
                                                  ).brightness ==
                                                  Brightness.dark
                                              ? CupertinoColors.white
                                              : CupertinoColors.black,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    child: const Icon(
                                      CupertinoIcons.pencil,
                                      size: 16.0,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showEditCategoryDialog(
                                        context,
                                        category,
                                        index,
                                      );
                                    },
                                  ),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    child: const Icon(
                                      CupertinoIcons.delete,
                                      size: 16.0,
                                      color: CupertinoColors.destructiveRed,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showDeleteConfirmation(
                                        context,
                                        category,
                                        index,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    CupertinoActionSheetAction(
                      isDefaultAction: true,
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddCategoryDialog(context);
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.add_circled, size: 16.0),
                          SizedBox(width: 10),
                          Text(
                            'Add New Category',
                            style: TextStyle(fontSize: 14.0),
                          ),
                        ],
                      ),
                    ),
                  ],
                  cancelButton: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CupertinoActionSheetAction(
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 14.0),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      CupertinoActionSheetAction(
                        isDefaultAction: true,
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: CupertinoColors.activeBlue,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            if (_categoryOptions.isNotEmpty) {
                              _selectedCategory = tempSelectedCategory;
                            }
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
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
        _selectedCategory =
            _categoryOptions.isNotEmpty ? _categoryOptions[0] : '';
      }
      logInfo('Category deleted: $deletedCategory');
    });
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
                style: const TextStyle(fontSize: 16.0),
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
                      !_categoryOptions.contains(newCategoryName)) {
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

  IconData _getCategoryIcon(String category) {
    final Map<String, IconData> icons = {
      'Brainstorm': CupertinoIcons.lightbulb,
      'Design': CupertinoIcons.pencil_outline,
      'Workout': CupertinoIcons.heart,
    };
    return icons[category] ?? CupertinoIcons.tag;
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
                  child: const Text('OK', style: TextStyle(fontSize: 14.0)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
      return;
    }

    if (_categoryOptions.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('No Categories'),
              content: const Text(
                'Please add a category before saving the habit.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Cancel', style: TextStyle(fontSize: 14.0)),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text(
                    'Add Category',
                    style: TextStyle(fontSize: 14.0),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddCategoryDialog(context);
                  },
                ),
              ],
            ),
      );
      return;
    }

    if (_selectedCategory.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Validation Error'),
              content: const Text('Please select a category.'),
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

    if (_selectedEndDate.isBefore(_selectedStartDate)) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Invalid Date'),
              content: const Text('End date must be after start date.'),
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

    final tasksCubit = context.read<TaskManagerCubit>();

    if (widget.habit != null) {
      // Редагування існуючої звички
      tasksCubit.editTask(
        task: widget.habit!,
        title: _titleController.text,
        priority: {'Low': 0, 'Normal': 1, 'High': 2}[_priority] ?? 1,
        deadline: _selectedStartDate.millisecondsSinceEpoch,
        estimatedTime: 0,
        category: Category(name: _selectedCategory),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        frequency: repeatRule,
      );
    } else {
      // Створення нової звички
      tasksCubit.createTask(
        title: _titleController.text,
        priority: {'Low': 0, 'Normal': 1, 'High': 2}[_priority] ?? 1,
        deadline: _selectedStartDate.millisecondsSinceEpoch,
        estimatedTime: 0,
        category: Category(name: _selectedCategory),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        frequency: repeatRule,
      );
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (_) => const HomeScreen()),
      );
    }

    logInfo(
      widget.habit == null
          ? 'Created Habit: ${_titleController.text}'
          : 'Updated Habit: ${_titleController.text}',
    );
  }
}
