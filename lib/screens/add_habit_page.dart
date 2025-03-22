import 'dart:ui';

import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/models/repeat_rule.dart';
import 'package:flowo_client/screens/home_screen.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../design/animated_particles_background.dart';
import '../design/cupertino_form_theme.dart';
import '../design/cupertino_form_widgets.dart';
import '../design/glassmorphic_container.dart';
import '../design/glassmorphic_form_theme.dart';
import '../design/glassmorphic_form_widgets.dart';
import '../theme_notifier.dart';

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

  late DateTime _selectedDate;
  late DateTime _startTime;
  DateTime? _endTime;

  bool _useParticlesBackground = true;

  String _selectedCategory = 'Brainstorm';
  String _priority = 'Normal';
  final List<String> _categoryOptions = [
    'Brainstorm',
    'Design',
    'Workout',
    'Add',
  ];

  String _selectedFrequencyType = 'weekly';
  int _intervalValue = 1;
  final List<Map<String, dynamic>> _frequency = [];
  final List<int> _monthlyDays = [];
  String _monthlyType = 'specific';
  String? _monthlyWeek;
  String? _monthlyDayOfWeek;

  late AnimationController _animationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _startTime = _selectedDate;

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

  void _toggleParticlesBackground() {
    setState(() {
      _useParticlesBackground = !_useParticlesBackground;
    });
    HapticFeedback.mediumImpact();
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
    // Access theme notifier for glassmorphic styling
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;
    final theme = GlassmorphicFormTheme(context);

    // Create vibrant color accents
    final primaryColor = themeNotifier.primaryColor;
    final accentColor = CupertinoColors.systemTeal;
    final secondaryAccent = CupertinoColors.systemIndigo;

    // Create gradient colors for various elements
    final headerGradient = [
      primaryColor.withOpacity(0.7),
      accentColor.withOpacity(0.5),
    ];

    Widget content = CupertinoPageScaffold(
      // Apply glassmorphic styling to navigation bar
      navigationBar: CupertinoNavigationBar(
        backgroundColor: themeNotifier.backgroundColor.withOpacity(0.8),
        border: null, // Remove default border
        middle: const Text(
          'Add Habit',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _toggleParticlesBackground,
          child: Icon(
            CupertinoIcons.sparkles,
            color:
                _useParticlesBackground
                    ? glassmorphicTheme.accentColor
                    : CupertinoColors.systemGrey,
          ),
        ),
      ),
      child: Container(
        // Add a subtle gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeNotifier.backgroundColor,
              themeNotifier.backgroundColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(
              GlassmorphicFormTheme.horizontalSpacing,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassmorphicContainer(
                    borderRadius: BorderRadius.circular(16),
                    padding: const EdgeInsets.all(16),
                    blur: glassmorphicTheme.defaultBlur,
                    opacity: glassmorphicTheme.defaultOpacity,
                    borderWidth: glassmorphicTheme.defaultBorderWidth,
                    borderColor: glassmorphicTheme.borderColor,
                    useGradient: true,
                    gradientColors: glassmorphicTheme.gradientColors,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text(
                            'Habit Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: glassmorphicTheme.accentColor,
                            ),
                          ),
                        ),
                        CupertinoFormWidgets.textField(
                          context: context,
                          controller: _titleController,
                          placeholder: 'Habit Name *',
                          validator:
                              (value) => value!.isEmpty ? 'Required' : null,
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
                  ),
                  SizedBox(height: CupertinoFormTheme.sectionSpacing),
                  GlassmorphicContainer(
                    borderRadius: BorderRadius.circular(16),
                    padding: const EdgeInsets.all(16),
                    blur: glassmorphicTheme.defaultBlur,
                    opacity: glassmorphicTheme.defaultOpacity,
                    borderWidth: glassmorphicTheme.defaultBorderWidth,
                    borderColor: glassmorphicTheme.borderColor,
                    useGradient: true,
                    gradientColors: [
                      primaryColor.withOpacity(0.3),
                      accentColor.withOpacity(0.2),
                    ],
                    showShimmer: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text(
                            'Deadline',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        CupertinoFormWidgets.selectionButton(
                          context: context,
                          label: 'Date',
                          value: theme.formatDate(_selectedDate),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _showDatePicker(context);
                          },
                          color: theme.primaryColor,
                          icon: CupertinoIcons.calendar,
                        ),
                        SizedBox(height: CupertinoFormTheme.elementSpacing),
                        CupertinoFormWidgets.selectionButton(
                          context: context,
                          label: 'Start Time',
                          value: theme.formatTime(_startTime),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _showTimePicker(context, isStart: true);
                          },
                          color: theme.secondaryColor,
                          icon: CupertinoIcons.time,
                        ),
                        SizedBox(height: CupertinoFormTheme.elementSpacing),
                        CupertinoFormWidgets.selectionButton(
                          context: context,
                          label: 'End Time',
                          value: theme.formatTime(_endTime),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _showTimePicker(context, isStart: false);
                          },
                          color: theme.accentColor,
                          icon: CupertinoIcons.time_solid,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: CupertinoFormTheme.sectionSpacing),
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    child: _buildFrequencySection(context, theme),
                  ),
                  SizedBox(height: CupertinoFormTheme.sectionSpacing),
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    child: _buildCategorySection(context, theme),
                  ),
                  SizedBox(height: CupertinoFormTheme.sectionSpacing),
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeInOut,
                    child: _buildPrioritySection(context, theme),
                  ),
                  SizedBox(height: CupertinoFormTheme.largeSpacing),
                  AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    child: ScaleTransition(
                      scale: _buttonScaleAnimation,
                      child: CupertinoFormWidgets.primaryButton(
                        context: context,
                        text: 'Save Habit',
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _animationController.forward().then(
                            (_) => _animationController.reverse(),
                          );
                          _saveTask(context);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Wrap with particles background if enabled
    return _useParticlesBackground
        ? AnimatedParticlesBackground(
          particleCount: 30,
          speedFactor: 0.5,
          particleOpacity: 0.3,
          child: content,
        )
        : content;
  }

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

    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;
    final secondaryAccent = CupertinoColors.systemPurple;

    return GlassmorphicContainer(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      blur: glassmorphicTheme.defaultBlur,
      opacity: glassmorphicTheme.defaultOpacity,
      borderWidth: glassmorphicTheme.defaultBorderWidth,
      borderColor: glassmorphicTheme.borderColor,
      useGradient: true,
      gradientColors: [
        secondaryAccent.withOpacity(0.3),
        glassmorphicTheme.accentColor.withOpacity(0.2),
      ],
      showShimmer: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'Frequency',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: secondaryAccent,
              ),
            ),
          ),
          Text('Repeat Type', style: theme.labelTextStyle),
          SizedBox(height: CupertinoFormTheme.smallSpacing),
          CupertinoFormWidgets.segmentedControl(
            context: context,
            children: frequencyTypeWidgets,
            groupValue: _selectedFrequencyType,
            onValueChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() => _selectedFrequencyType = value);
            },
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
                    if (value.isNotEmpty)
                      setState(() => _intervalValue = int.tryParse(value) ?? 1);
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
          if (_selectedFrequencyType == 'weekly') ...[
            SizedBox(height: CupertinoFormTheme.elementSpacing),
            Text('On Days', style: theme.labelTextStyle),
            SizedBox(height: CupertinoFormTheme.smallSpacing),
            if (_frequency.isNotEmpty)
              ..._frequency.map(
                (freq) => _buildFrequencyItem(context, theme, freq['day']),
              ),
            SizedBox(height: CupertinoFormTheme.smallSpacing),
            CupertinoFormWidgets.primaryButton(
              context: context,
              text: 'Add Day',
              onPressed: () => _showWeeklyFrequencyDialog(context),
            ),
          ],
          if (_selectedFrequencyType == 'monthly') ...[
            SizedBox(height: CupertinoFormTheme.elementSpacing),
            _buildMonthlyOptions(context, theme),
          ],
        ],
      ),
    );
  }

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Type', style: theme.labelTextStyle),
        SizedBox(height: CupertinoFormTheme.smallSpacing),
        CupertinoFormWidgets.segmentedControl(
          context: context,
          children: monthlyTypeWidgets,
          groupValue: _monthlyType,
          onValueChanged: (value) => setState(() => _monthlyType = value),
        ),
        SizedBox(height: CupertinoFormTheme.elementSpacing),
        if (_monthlyType == 'specific') ...[
          Text('On Days', style: theme.labelTextStyle),
          SizedBox(height: CupertinoFormTheme.smallSpacing),
          if (_monthlyDays.isNotEmpty)
            Wrap(
              spacing: CupertinoFormTheme.smallSpacing,
              runSpacing: CupertinoFormTheme.smallSpacing,
              children:
                  _monthlyDays
                      .map((day) => _buildDayChip(context, theme, day))
                      .toList(),
            ),
          SizedBox(height: CupertinoFormTheme.smallSpacing),
          CupertinoFormWidgets.primaryButton(
            context: context,
            text: 'Add Day',
            onPressed: () => _showMonthlyDayPicker(context),
          ),
        ],
        if (_monthlyType == 'pattern') ...[
          Text('Pattern', style: theme.labelTextStyle),
          SizedBox(height: CupertinoFormTheme.smallSpacing),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showMonthlyWeekPicker(context),
                  child: Container(
                    padding: CupertinoFormTheme.inputPadding,
                    decoration: theme.inputDecoration,
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
                    decoration: theme.inputDecoration,
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

    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;
    final categoryColor = CupertinoColors.systemGreen;

    return GlassmorphicContainer(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      blur: glassmorphicTheme.defaultBlur,
      opacity: glassmorphicTheme.defaultOpacity,
      borderWidth: glassmorphicTheme.defaultBorderWidth,
      borderColor: glassmorphicTheme.borderColor,
      useGradient: true,
      gradientColors: [
        categoryColor.withOpacity(0.3),
        glassmorphicTheme.accentColor.withOpacity(0.2),
      ],
      showShimmer: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: categoryColor,
              ),
            ),
          ),
          CupertinoFormWidgets.segmentedControl(
            context: context,
            children: categoryWidgets,
            groupValue: _selectedCategory,
            onValueChanged: (value) {
              HapticFeedback.selectionClick();
              _handleCategoryChange(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySection(BuildContext context, CupertinoFormTheme theme) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;
    final priorityColor = _getPriorityColor();

    return GlassmorphicContainer(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
      blur: glassmorphicTheme.defaultBlur,
      opacity: glassmorphicTheme.defaultOpacity,
      borderWidth: glassmorphicTheme.defaultBorderWidth,
      borderColor: glassmorphicTheme.borderColor,
      useGradient: true,
      gradientColors: [
        priorityColor.withOpacity(0.3),
        glassmorphicTheme.accentColor.withOpacity(0.2),
      ],
      showShimmer: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'Priority',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: priorityColor,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level: ${_getPriorityValue()}',
                style: theme.labelTextStyle,
              ),
              Text(
                _getPriorityLabel(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _getPriorityColor(),
                ),
              ),
            ],
          ),
          SizedBox(height: CupertinoFormTheme.elementSpacing),
          CupertinoSlider(
            value: _getPriorityValue().toDouble(),
            min: 0,
            max: 2,
            divisions: 2,
            activeColor: _getPriorityColor(),
            onChanged: (value) {
              HapticFeedback.selectionClick();
              setState(() {
                _priority = ['Low', 'Normal', 'High'][value.round()];
              });
            },
          ),
        ],
      ),
    );
  }

  int _getPriorityValue() {
    return {'Low': 0, 'Normal': 1, 'High': 2}[_priority] ?? 1;
  }

  String _getPriorityLabel() {
    return {
          'Low': 'Not urgent',
          'Normal': 'Standard',
          'High': 'Urgent',
        }[_priority] ??
        'Standard';
  }

  Color _getPriorityColor() {
    return {
          'Low': CupertinoColors.systemGreen,
          'Normal': CupertinoColors.systemOrange,
          'High': CupertinoColors.systemRed,
        }[_priority] ??
        CupertinoColors.systemOrange;
  }

  Widget _buildDayChip(
    BuildContext context,
    CupertinoFormTheme theme,
    int day,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CupertinoFormTheme.smallSpacing * 1.5,
        vertical: CupertinoFormTheme.smallSpacing * 0.75,
      ),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.2),
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
              color: theme.primaryColor,
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

  Widget _buildFrequencyItem(
    BuildContext context,
    CupertinoFormTheme theme,
    String day,
  ) {
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
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(CupertinoFormTheme.borderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(day, style: theme.valueTextStyle),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(
                CupertinoIcons.trash,
                size: CupertinoFormTheme.standardIconSize,
                color: theme.warningColor,
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
    // Provide haptic feedback when opening the date picker
    HapticFeedback.selectionClick();

    final pickedDate = await CupertinoFormWidgets.showDatePicker(
      context: context,
      initialDate: _selectedDate,
    );

    if (pickedDate != null && mounted) {
      // Provide haptic feedback when a date is selected
      HapticFeedback.mediumImpact();
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _showTimePicker(
    BuildContext context, {
    required bool isStart,
  }) async {
    // Provide haptic feedback when opening the time picker
    HapticFeedback.selectionClick();

    final pickedTime = await CupertinoFormWidgets.showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime ?? _startTime,
    );

    if (pickedTime != null && mounted) {
      // Provide haptic feedback when a time is selected
      HapticFeedback.mediumImpact();
      setState(() => isStart ? _startTime = pickedTime : _endTime = pickedTime);
    }
  }

  Future<void> _showWeeklyFrequencyDialog(BuildContext context) async {
    // Provide haptic feedback when opening the dialog
    HapticFeedback.mediumImpact();

    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Text('Add Day'),
            actions: [
              CupertinoActionSheetAction(
                child: const Text('Select Day'),
                onPressed: () async {
                  // Provide haptic feedback when selecting an option
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                  await _showDayOfWeekPicker(context, (day) {
                    if (day != null &&
                        mounted &&
                        !_frequency.any((item) => item['day'] == day)) {
                      // Provide haptic feedback when adding a day
                      HapticFeedback.mediumImpact();
                      setState(() => _frequency.add({'day': day}));
                      logInfo('Added frequency: $day');
                    }
                  });
                },
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: const Text('Cancel'),
              onPressed: () {
                // Provide haptic feedback when canceling
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
            ),
          ),
    );
  }

  Future<void> _showDayOfWeekPicker(
    BuildContext context,
    Function(String?) onSelected,
  ) async {
    // Provide haptic feedback when opening the picker
    HapticFeedback.selectionClick();

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
                    onSelectedItemChanged: (index) {
                      // Provide haptic feedback when scrolling through options
                      HapticFeedback.selectionClick();
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
                      onPressed: () {
                        // Provide haptic feedback when canceling
                        HapticFeedback.selectionClick();
                        onSelected(null);
                        Navigator.pop(context);
                      },
                    ),
                    CupertinoButton(
                      child: const Text('Select'),
                      onPressed: () {
                        // Provide haptic feedback when selecting
                        HapticFeedback.mediumImpact();
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
    // Provide haptic feedback when opening the picker
    HapticFeedback.selectionClick();

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
                    onSelectedItemChanged: (index) {
                      // Provide haptic feedback when scrolling through options
                      HapticFeedback.selectionClick();
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
                      onPressed: () {
                        // Provide haptic feedback when canceling
                        HapticFeedback.selectionClick();
                        Navigator.pop(context);
                      },
                    ),
                    CupertinoButton(
                      child: const Text('Add'),
                      onPressed: () {
                        if (selectedDay != null &&
                            !_monthlyDays.contains(selectedDay)) {
                          // Provide haptic feedback when adding a day
                          HapticFeedback.mediumImpact();
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
    // Provide haptic feedback when opening the picker
    HapticFeedback.selectionClick();

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
                    onSelectedItemChanged: (index) {
                      // Provide haptic feedback when scrolling through options
                      HapticFeedback.selectionClick();
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
                      onPressed: () {
                        // Provide haptic feedback when canceling
                        HapticFeedback.selectionClick();
                        Navigator.pop(context);
                      },
                    ),
                    CupertinoButton(
                      child: const Text('Select'),
                      onPressed: () {
                        // Provide haptic feedback when selecting
                        HapticFeedback.mediumImpact();
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
    // Provide haptic feedback when opening the picker
    HapticFeedback.selectionClick();

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
                    onSelectedItemChanged: (index) {
                      // Provide haptic feedback when scrolling through options
                      HapticFeedback.selectionClick();
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
                      onPressed: () {
                        // Provide haptic feedback when canceling
                        HapticFeedback.selectionClick();
                        Navigator.pop(context);
                      },
                    ),
                    CupertinoButton(
                      child: const Text('Select'),
                      onPressed: () {
                        // Provide haptic feedback when selecting
                        HapticFeedback.mediumImpact();
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
    // Provide haptic feedback when opening the dialog
    HapticFeedback.mediumImpact();

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
                onSubmitted: (_) {
                  // Provide haptic feedback when submitting with keyboard
                  HapticFeedback.mediumImpact();
                },
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () {
                  // Provide haptic feedback when canceling
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                },
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Add'),
                onPressed: () {
                  // Provide haptic feedback when adding
                  HapticFeedback.mediumImpact();

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
    // Provide haptic feedback when changing category
    HapticFeedback.selectionClick();

    if (value == 'Add')
      _showAddCategoryDialog(context);
    else
      setState(() => _selectedCategory = value);
  }

  void _saveTask(BuildContext context) {
    // Provide haptic feedback when attempting to save
    HapticFeedback.mediumImpact();

    if (!_formKey.currentState!.validate()) {
      // Provide error feedback
      HapticFeedback.vibrate();

      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Validation Error'),
              content: const Text('Please fill in all required fields.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                  },
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
      // Provide error feedback for time validation
      HapticFeedback.vibrate();

      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Invalid Time'),
              content: const Text('End time must be after start time.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
      );
      return;
    }

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

    // Create the task
    context.read<TaskManagerCubit>().createTask(
      title: _titleController.text,
      priority: {'Low': 0, 'Normal': 1, 'High': 2}[_priority] ?? 1,
      deadline: startTime.millisecondsSinceEpoch,
      estimatedTime: endTime.difference(startTime).inMilliseconds,
      category: Category(name: _selectedCategory),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      frequency: repeatRule,
    );

    // Provide success feedback
    HapticFeedback.heavyImpact();

    // Show a brief success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Habit "${_titleController.text}" created successfully'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Navigate back to home screen
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (_) => HomeScreen(initialIndex: 0)),
    );
    logInfo('Saved Habit: ${_titleController.text}');
  }
}
