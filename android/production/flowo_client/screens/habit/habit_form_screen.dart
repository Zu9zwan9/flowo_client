import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/models/repeat_rule.dart';
import 'package:flowo_client/models/repeat_rule_instance.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/scheduled_task_type.dart';
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
import '../../services/category/category_service.dart';
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

  // Notification settings
  int? _firstNotification = 5;
  int? _secondNotification;

  @override
  void initState() {
    super.initState();
    _userSettings = context.read<TaskManagerCubit>().taskManager.userSettings;

    // Initialize notification service

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

  String _formatNotificationTime(int? minutes) {
    if (minutes == null) {
      return 'None';
    }

    switch (minutes) {
      case 0:
        return 'At event time';
      case 1:
        return '1 minute before';
      case 5:
        return '5 minutes before';
      case 15:
        return '15 minutes before';
      case 30:
        return '30 minutes before';
      case 60:
        return '1 hour before';
      case 120:
        return '2 hours before';
      case 1440:
        return '1 day before';
      case 2880:
        return '2 days before';
      case 10080:
        return '1 week before';
      default:
        if (minutes < 60) {
          return '$minutes minutes before';
        } else if (minutes < 1440) {
          final hours = minutes ~/ 60;
          final mins = minutes % 60;

          if (mins == 0) {
            return '$hours hours before';
          } else {
            return '$hours hours $mins minutes before';
          }
        } else {
          final days = minutes ~/ 1440;
          return '$days days before';
        }
    }
  }

  Future<void> _showNotificationTimePicker(
    BuildContext context,
    bool isFirstNotification,
  ) async {
    // Define different notification time options for first and second alerts
    final List<int?> timeOptions = [
      null,
      0,
      5,
      15,
      30,
      60,
      120,
      1440,
      2880,
      10080,
    ];

    // Get current value and find its index
    final int? currentValue =
        isFirstNotification ? _firstNotification : _secondNotification;
    final int initialIndex =
        timeOptions.contains(currentValue)
            ? timeOptions.indexOf(currentValue)
            : 0;

    await showCupertinoModalPopup<void>(
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
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(
                      initialItem: initialIndex,
                    ),
                    onSelectedItemChanged: (index) {
                      if (mounted) {
                        setState(() {
                          if (isFirstNotification) {
                            _firstNotification = timeOptions[index];
                          } else {
                            _secondNotification = timeOptions[index];
                          }
                        });
                      }
                    },
                    children:
                        timeOptions
                            .map((time) => Text(_formatNotificationTime(time)))
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // Validates the entire form and returns an error message if invalid
  String? _validateForm() {
    // Check if title is empty
    if (_titleController.text.trim().isEmpty) {
      return 'Habit title is required';
    }

    // Validate start and end dates
    final now = DateTime.now();
    if (_selectedStartDate.isBefore(DateTime(now.year, now.month, now.day))) {
      return 'Start date cannot be in the past';
    }
    if (_selectedEndDate.isBefore(_selectedStartDate)) {
      return 'End date must be after start date';
    }

    // Check if category is selected
    if (_categoryOptions.isEmpty || _selectedCategory.isEmpty) {
      return 'Please select or add a category';
    }

    // Validate interval
    if (_intervalValue <= 0) {
      return 'Repeat interval must be greater than zero';
    }

    // Validate frequency-specific details
    if (_selectedFrequencyType == 'daily' ||
        _selectedFrequencyType == 'yearly') {
      if (_nameController.text.trim().isEmpty) {
        return 'Habit name is required for $_selectedFrequencyType frequency';
      }
      if (_startTime == null || _endTime == null) {
        return 'Start and end times are required for $_selectedFrequencyType frequency';
      }
      if (_endTime!.hour < _startTime!.hour ||
          (_endTime!.hour == _startTime!.hour &&
              _endTime!.minute <= _startTime!.minute)) {
        return 'End time must be after start time for $_selectedFrequencyType frequency';
      }
    } else if (_selectedFrequencyType == 'weekly') {
      if (_weeklyInstances.isEmpty) {
        return 'At least one day must be selected for weekly frequency';
      }
      for (var inst in _weeklyInstances) {
        if (inst['nameController'].text.trim().isEmpty) {
          return 'Habit name is required for all weekly instances';
        }
        if (inst['start'] == null || inst['end'] == null) {
          return 'Start and end times are required for all weekly instances';
        }
        final start = inst['start'] as TimeOfDay;
        final end = inst['end'] as TimeOfDay;
        if (end.hour < start.hour ||
            (end.hour == start.hour && end.minute <= start.minute)) {
          return 'End time must be after start time for ${inst['day']}';
        }
      }
    } else if (_selectedFrequencyType == 'monthly') {
      if (_monthlyType == 'specific') {
        if (_monthlySpecificInstances.isEmpty) {
          return 'At least one day must be selected for monthly specific frequency';
        }
        for (var inst in _monthlySpecificInstances) {
          if (inst['nameController'].text.trim().isEmpty) {
            return 'Habit name is required for all monthly specific instances';
          }
          if (inst['start'] == null || inst['end'] == null) {
            return 'Start and end times are required for all monthly specific instances';
          }
          final start = inst['start'] as TimeOfDay;
          final end = inst['end'] as TimeOfDay;
          if (end.hour < start.hour ||
              (end.hour == start.hour && end.minute <= start.minute)) {
            return 'End time must be after start time for day ${inst['day']}';
          }
        }
      } else {
        if (_monthlyWeek == null || _monthlyDayOfWeek == null) {
          return 'Week and day of week must be selected for monthly pattern';
        }
        if (_nameController.text.trim().isEmpty) {
          return 'Habit name is required for monthly pattern';
        }
        if (_startTime == null || _endTime == null) {
          return 'Start and end times are required for monthly pattern';
        }
        if (_endTime!.hour < _startTime!.hour ||
            (_endTime!.hour == _startTime!.hour &&
                _endTime!.minute <= _startTime!.minute)) {
          return 'End time must be after start time for monthly pattern';
        }
      }
    }

    return null;
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
                      validator:
                          (value) => value!.trim().isEmpty ? 'Required' : null,
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
                const SizedBox(height: 24.0),
                _buildNotificationSection(context, theme),
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
              child: CupertinoTextField(
                controller: _intervalController,
                placeholder: '1',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                // Ограничение ввода только цифрами
                style: theme.valueTextStyle,
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(5),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      _intervalValue = int.tryParse(value) ?? 1;
                      // Immediate validation for interval
                      if (_intervalValue <= 0) {
                        showCupertinoDialog(
                          context: context,
                          builder:
                              (context) => CupertinoAlertDialog(
                                title: const Text('Invalid Interval'),
                                content: const Text(
                                  'Interval must be greater than zero',
                                ),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text('OK'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                        );
                        _intervalController.text = '1';
                        _intervalValue = 1;
                      }
                    });
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
          setState(() => _selectedFrequencyType = type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: double.infinity,
          decoration: BoxDecoration(
            color:
                isSelected
                    ? CupertinoColors.systemBackground.resolveFrom(context)
                    : CupertinoColors.transparent,
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
                Flexible(
                  child: Text(
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
                    overflow: TextOverflow.ellipsis,
                    semanticsLabel: '${type.capitalize()} frequency',
                  ),
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
        validator: (value) => value!.trim().isEmpty ? 'Required' : null,
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
          if (time != null && mounted) {
            setState(() {
              _startTime = time;
              // Immediate validation for time
              if (_endTime != null &&
                  (_endTime!.hour < _startTime!.hour ||
                      (_endTime!.hour == _startTime!.hour &&
                          _endTime!.minute <= _startTime!.minute))) {
                showCupertinoDialog(
                  context: context,
                  builder:
                      (context) => CupertinoAlertDialog(
                        title: const Text('Time Error'),
                        content: const Text(
                          'End time must be after start time',
                        ),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('OK'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                );
                _endTime = null;
              }
            });
          }
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
          if (time != null && mounted) {
            setState(() {
              _endTime = time;
              // Immediate validation for time
              if (_startTime != null &&
                  (_endTime!.hour < _startTime!.hour ||
                      (_endTime!.hour == _startTime!.hour &&
                          _endTime!.minute <= _startTime!.minute))) {
                showCupertinoDialog(
                  context: context,
                  builder:
                      (context) => CupertinoAlertDialog(
                        title: const Text('Time Error'),
                        content: const Text(
                          'End time must be after start time',
                        ),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('OK'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                );
                _endTime = null;
              }
            });
          }
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
                validator: (value) => value!.trim().isEmpty ? 'Required' : null,
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
                  if (time != null && mounted) {
                    setState(() {
                      inst['start'] = time;
                      // Immediate validation for weekly instance time
                      if (inst['end'] != null) {
                        final end = inst['end'] as TimeOfDay;
                        if (end.hour < time.hour ||
                            (end.hour == time.hour &&
                                end.minute <= time.minute)) {
                          showCupertinoDialog(
                            context: context,
                            builder:
                                (context) => CupertinoAlertDialog(
                                  title: const Text('Time Error'),
                                  content: const Text(
                                    'End time must be after start time',
                                  ),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text('OK'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                          );
                          inst['end'] = null;
                        }
                      }
                    });
                  }
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
                  if (time != null && mounted) {
                    setState(() {
                      inst['end'] = time;
                      // Immediate validation for weekly instance time
                      if (inst['start'] != null) {
                        final start = inst['start'] as TimeOfDay;
                        if (time.hour < start.hour ||
                            (time.hour == start.hour &&
                                time.minute <= start.minute)) {
                          showCupertinoDialog(
                            context: context,
                            builder:
                                (context) => CupertinoAlertDialog(
                                  title: const Text('Time Error'),
                                  content: const Text(
                                    'End time must be after start time',
                                  ),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text('OK'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                          );
                          inst['end'] = null;
                        }
                      }
                    });
                  }
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
                validator: (value) => value!.trim().isEmpty ? 'Required' : null,
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
                  if (time != null && mounted) {
                    setState(() {
                      inst['start'] = time;
                      // Immediate validation for monthly specific instance time
                      if (inst['end'] != null) {
                        final end = inst['end'] as TimeOfDay;
                        if (end.hour < time.hour ||
                            (end.hour == time.hour &&
                                end.minute <= time.minute)) {
                          showCupertinoDialog(
                            context: context,
                            builder:
                                (context) => CupertinoAlertDialog(
                                  title: const Text('Time Error'),
                                  content: const Text(
                                    'End time must be after start time',
                                  ),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text('OK'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                          );
                          inst['end'] = null;
                        }
                      }
                    });
                  }
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
                  if (time != null && mounted) {
                    setState(() {
                      inst['end'] = time;
                      // Immediate validation for monthly specific instance time
                      if (inst['start'] != null) {
                        final start = inst['start'] as TimeOfDay;
                        if (time.hour < start.hour ||
                            (time.hour == start.hour &&
                                time.minute <= start.minute)) {
                          showCupertinoDialog(
                            context: context,
                            builder:
                                (context) => CupertinoAlertDialog(
                                  title: const Text('Time Error'),
                                  content: const Text(
                                    'End time must be after start time',
                                  ),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text('OK'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                          );
                          inst['end'] = null;
                        }
                      }
                    });
                  }
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

  Widget _buildNotificationSection(
    BuildContext context,
    CupertinoFormTheme theme,
  ) {
    return CupertinoFormWidgets.formGroup(
      context: context,
      title: 'Notification Settings',
      children: [
        Text(
          'Set when you want to be notified before the habit',
          style: theme.helperTextStyle,
        ),
        const SizedBox(height: 12.0),
        CupertinoFormWidgets.selectionButton(
          context: context,
          label: 'Alert',
          value: _formatNotificationTime(_firstNotification),
          onTap: () => _showNotificationTimePicker(context, true),
          color: theme.secondaryColor,
          icon: CupertinoIcons.bell,
          iconSize: 20.0,
        ),
        const SizedBox(height: 12.0),
        CupertinoFormWidgets.selectionButton(
          context: context,
          label: 'Second Alert',
          value: _formatNotificationTime(_secondNotification),
          onTap: () => _showNotificationTimePicker(context, false),
          color: theme.accentColor,
          icon: CupertinoIcons.bell_fill,
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
        // Immediate validation for dates
        final error = _validateForm();
        if (error != null && error.contains('date')) {
          showCupertinoDialog(
            context: context,
            builder:
                (context) => CupertinoAlertDialog(
                  title: const Text('Date Error'),
                  content: Text(error),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('OK'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
          );
          if (isStart) {
            _selectedStartDate = minimumDate;
          } else {
            _selectedEndDate = _selectedStartDate.add(const Duration(days: 7));
          }
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
                    onDateTimeChanged: (dateTime) => selectedTime = dateTime,
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
                          setDialogState(() => tempSelectedCategory = category);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          color:
                              isSelected
                                  ? CupertinoTheme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1)
                                  : CupertinoColors.transparent,
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

  Future<bool?> _showOverlapResolutionDialog(
    BuildContext context,
    List<ScheduledTask> overlappingTasks,
    bool isEdit,
  ) async {
    // Get parent tasks for all overlapping tasks
    final overlappingParentTasks = <Task>[];
    for (var scheduledTask in overlappingTasks) {
      final parentTask = scheduledTask.parentTask;
      if (parentTask != null && !overlappingParentTasks.contains(parentTask)) {
        overlappingParentTasks.add(parentTask);
      }
    }

    // Format the list of overlapping tasks for display
    final overlappingTasksText = overlappingParentTasks
        .map((task) {
          final scheduledTask = task.scheduledTasks.firstWhere(
            (st) => overlappingTasks.any(
              (ot) => ot.scheduledTaskId == st.scheduledTaskId,
            ),
            orElse:
                () => overlappingTasks.firstWhere(
                  (ot) => ot.parentTaskId == task.id,
                ),
          );

          final startTime = scheduledTask.startTime;
          final endTime = scheduledTask.endTime;
          final formattedStart =
              '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
          final formattedEnd =
              '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

          String taskType = 'Task';
          if (scheduledTask.type == ScheduledTaskType.timeSensitive) {
            taskType = 'Event';
          } else if (scheduledTask.type == ScheduledTaskType.rest) {
            taskType = 'Break';
          } else if (scheduledTask.type == ScheduledTaskType.mealBreak) {
            taskType = 'Meal Break';
          } else if (scheduledTask.type == ScheduledTaskType.sleep) {
            taskType = 'Sleep Time';
          } else if (scheduledTask.type == ScheduledTaskType.freeTime) {
            taskType = 'Free Time';
          }

          return '• ${task.title} ($taskType, $formattedStart-$formattedEnd)';
        })
        .join('\n');

    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        // Use dynamic colors based on system color
        final primaryColor = CupertinoTheme.of(context).primaryColor;
        final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;

        return CupertinoAlertDialog(
          title: Text(
            'Schedule Conflict',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This ${isEdit ? 'edit' : 'new habit'} overlaps with:',
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 8),
              Text(overlappingTasksText, style: TextStyle(color: textColor)),
              const SizedBox(height: 12),
              Text(
                'What would you like to do?',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              isDestructiveAction: true,
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, true),
              isDefaultAction: true,
              child: const Text('Override Conflicts'),
            ),
          ],
        );
      },
    );
  }

  // Saves the habit after performing validation
  void _saveTask(BuildContext context) {
    final validationError = _validateForm();

    if (validationError != null) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Validation Error'),
              content: Text(validationError),
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
      repeatRule = RepeatRule(
        type: _selectedFrequencyType,
        interval: _intervalValue,
        startRepeat: _selectedStartDate,
        endRepeat: _selectedEndDate,
        byDay: [
          RepeatRuleInstance(
            selectedDay: _selectedFrequencyType,
            name: _nameController.text.trim(),
            start: _startTime!,
            end: _endTime!,
          ),
        ],
      );
    } else if (_selectedFrequencyType == 'weekly') {
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
                    name: inst['nameController'].text.trim(),
                    start: inst['start'],
                    end: inst['end'],
                  ),
                )
                .toList(),
      );
    } else if (_selectedFrequencyType == 'monthly') {
      if (_monthlyType == 'specific') {
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
                      name: inst['nameController'].text.trim(),
                      start: inst['start'],
                      end: inst['end'],
                    ),
                  )
                  .toList(),
        );
      } else {
        repeatRule = RepeatRule(
          type: 'monthly',
          interval: _intervalValue,
          startRepeat: _selectedStartDate,
          endRepeat: _selectedEndDate,
          bySetPos: _getSetPosFromWeek(_monthlyWeek!),
          byDay: [
            RepeatRuleInstance(
              selectedDay: _monthlyDayOfWeek!,
              name: _nameController.text.trim(),
              start: _startTime!,
              end: _endTime!,
            ),
          ],
        );
      }
    }

    final tasksCubit = context.read<TaskManagerCubit>();

    if (widget.habit != null) {
      tasksCubit.editTask(
        task: widget.habit!,
        title: _titleController.text.trim(),
        priority: {'Low': 0, 'Normal': 1, 'High': 2}[_priority] ?? 1,
        deadline: _selectedStartDate.millisecondsSinceEpoch,
        estimatedTime: 0,
        category: Category(name: _selectedCategory),
        notes:
            _notesController.text.isNotEmpty
                ? _notesController.text.trim()
                : null,
        frequency: repeatRule,
        firstNotification: _firstNotification,
        secondNotification: _secondNotification,
      );
    } else {
      tasksCubit.createTask(
        title: _titleController.text.trim(),
        priority: {'Low': 0, 'Normal': 1, 'High': 2}[_priority] ?? 1,
        deadline: _selectedStartDate.millisecondsSinceEpoch,
        estimatedTime: 0,
        category: Category(name: _selectedCategory),
        notes:
            _notesController.text.isNotEmpty
                ? _notesController.text.trim()
                : null,
        frequency: repeatRule,
        firstNotification: _firstNotification,
        secondNotification: _secondNotification,
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
