import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/models/time_frame.dart';
import 'package:flowo_client/models/user_settings.dart';
import 'package:flowo_client/screens/widgets/settings_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/cupertino_form_theme.dart';
import '../../models/app_theme.dart'; // Import the shared AppTheme enum
import '../../theme_notifier.dart';
import '../../utils/logger.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TimeOfDay _sleepTime;
  late TimeOfDay _wakeupTime;
  late int _breakDuration;
  late int _minSessionDuration;
  late List<TimeFrame> _mealTimes;
  late List<TimeFrame> _freeTimes;
  late Map<String, bool> _activeDays;
  late String _dateFormat;
  late String _monthFormat;
  late bool _is24HourFormat;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _minSessionDuration = _minSessionDuration.clamp(5, 120);
    _breakDuration = _breakDuration.clamp(5, 30);
  }

  /// Loads user settings from TaskManagerCubit and initializes state variables.
  void _loadSettings() {
    final currentSettings = context.read<TaskManagerCubit>().taskManager.userSettings;
    setState(() {
      _sleepTime = currentSettings.sleepTime.isNotEmpty
          ? currentSettings.sleepTime.first.startTime
          : const TimeOfDay(hour: 22, minute: 0);
      _wakeupTime = currentSettings.sleepTime.isNotEmpty
          ? currentSettings.sleepTime.first.endTime
          : const TimeOfDay(hour: 7, minute: 0);
      _breakDuration = (currentSettings.breakTime ?? 15 * 60 * 1000) ~/ (60 * 1000);
      _minSessionDuration = currentSettings.minSession ~/ (60 * 1000);
      _mealTimes = List.from(
        currentSettings.mealBreaks.isNotEmpty
            ? currentSettings.mealBreaks
            : [
          TimeFrame(
            startTime: TimeOfDay(hour: 8, minute: 0),
            endTime: TimeOfDay(hour: 8, minute: 30),
          ),
          TimeFrame(
            startTime: TimeOfDay(hour: 13, minute: 0),
            endTime: TimeOfDay(hour: 13, minute: 30),
          ),
          TimeFrame(
            startTime: TimeOfDay(hour: 19, minute: 0),
            endTime: TimeOfDay(hour: 19, minute: 30),
          ),
        ],
      );
      _freeTimes = List.from(
        currentSettings.freeTime.isNotEmpty
            ? currentSettings.freeTime
            : [
          TimeFrame(
            startTime: TimeOfDay(hour: 17, minute: 0),
            endTime: TimeOfDay(hour: 18, minute: 30),
          ),
        ],
      );
      _activeDays = Map.from(
        currentSettings.activeDays ??
            {
              'Monday': true,
              'Tuesday': true,
              'Wednesday': true,
              'Thursday': true,
              'Friday': true,
              'Saturday': true,
              'Sunday': true,
            },
      );
      _dateFormat = currentSettings.dateFormat;
      _monthFormat = currentSettings.monthFormat;
      _is24HourFormat = currentSettings.is24HourFormat;
    });
  }

  /// Saves the current settings to TaskManagerCubit and shows a confirmation dialog.
  void _saveSettings() {
    final userSettings = UserSettings(
      name: 'Default',
      minSession: _minSessionDuration * 60 * 1000,
      breakTime: _breakDuration * 60 * 1000,
      sleepTime: [TimeFrame(startTime: _sleepTime, endTime: _wakeupTime)],
      mealBreaks: List.from(_mealTimes),
      freeTime: List.from(_freeTimes),
      activeDays: Map.from(_activeDays),
      dateFormat: _dateFormat,
      monthFormat: _monthFormat,
      is24HourFormat: _is24HourFormat,
    );

    context.read<TaskManagerCubit>().updateUserSettings(userSettings);
    logInfo('Settings saved');

    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Settings Saved'),
        content: const Text('Your schedule preferences have been updated.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  /// Saves application logs to a file and shows a dialog with options to share or dismiss.
  Future<void> _saveLogs() async {
    appLogger.info('Save logs button pressed', 'Settings');
    final filePath = await appLogger.saveToFile(context);

    if (!mounted || filePath == null) return;

    showCupertinoDialog(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: const Text('Logs Saved'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Logs have been saved successfully.'),
                const SizedBox(height: 8),
                Text(
                  'Location: $filePath',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Share'),
                onPressed: () {
                  Navigator.pop(context);
                  _shareLogFile(filePath);
                },
              ),
              const CupertinoDialogAction(
                isDefaultAction: true,
                child: Text('OK'),
              ),
            ],
          ),
    );

    appLogger.info('Logs saved successfully', 'Settings', {'path': filePath});
  }

  /// Shows a dialog with the log file location (since direct sharing isn't implemented).
  Future<void> _shareLogFile(String filePath) async {
    try {
      showCupertinoDialog(
        context: context,
        builder:
            (_) => CupertinoAlertDialog(
              title: const Text('Log File Location'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your log file is saved at:'),
                  const SizedBox(height: 8),
                  Text(
                    filePath,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'You can access this file through your device\'s file manager.',
                  ),
                ],
              ),
              actions: [
                const CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text('OK'),
                ),
              ],
            ),
      );

      appLogger.info('Log file location shown', 'Settings');
    } catch (e) {
      appLogger.error('Error showing log file location', 'Settings', {
        'error': e.toString(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to show log file location: $e')),
        );
      }
    }
  }

  /// Shows a time picker dialog for selecting a time.
  Future<void> _showTimePicker({
    required TimeOfDay initialTime,
    required Function(TimeOfDay) onTimeSelected,
  }) async {
    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => Container(
            height: 280,
            color: CupertinoFormTheme(context).backgroundColor,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
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
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: DateTime(
                      2022,
                      1,
                      1,
                      initialTime.hour,
                      initialTime.minute,
                    ),
                    onDateTimeChanged:
                        (dateTime) => onTimeSelected(
                          TimeOfDay(
                            hour: dateTime.hour,
                            minute: dateTime.minute,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  /// Shows a dialog to add a time slot (meal or free time).
  void _showAddTimeSlotDialog({
    required String title,
    required Function(TimeOfDay, TimeOfDay) onAdd,
    Color iconColor = CupertinoColors.systemBlue,
  }) {
    var startTime = const TimeOfDay(hour: 12, minute: 0);
    var endTime = const TimeOfDay(hour: 13, minute: 0);

    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setDialogState) => CupertinoActionSheet(
                  title: Text('Add $title'),
                  message: Text('Set your $title start and end times'),
                  actions: [
                    CupertinoActionSheetAction(
                      child: Text('Start Time: ${_formatTimeOfDay(startTime)}'),
                      onPressed:
                          () => _showTimePicker(
                            initialTime: startTime,
                            onTimeSelected:
                                (time) =>
                                    setDialogState(() => startTime = time),
                          ),
                    ),
                    CupertinoActionSheetAction(
                      child: Text('End Time: ${_formatTimeOfDay(endTime)}'),
                      onPressed:
                          () => _showTimePicker(
                            initialTime: endTime,
                            onTimeSelected:
                                (time) => setDialogState(() => endTime = time),
                          ),
                    ),
                    CupertinoActionSheetAction(
                      isDefaultAction: true,
                      child: Text('Add $title'),
                      onPressed: () {
                        onAdd(startTime, endTime);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                  cancelButton: CupertinoActionSheetAction(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
          ),
    );
  }

  /// Shows a dialog to add a meal time slot.
  void _showAddMealDialog() {
    _showAddTimeSlotDialog(
      title: 'Meal Time',
      iconColor: CupertinoColors.systemOrange,
      onAdd:
          (startTime, endTime) => setState(
            () => _mealTimes.add(
              TimeFrame(startTime: startTime, endTime: endTime),
            ),
          ),
    );
  }

  /// Shows a dialog to add a free time slot.
  void _showAddFreeTimeDialog() {
    _showAddTimeSlotDialog(
      title: 'Free Time',
      iconColor: CupertinoColors.systemGreen,
      onAdd:
          (startTime, endTime) => setState(
            () => _freeTimes.add(
              TimeFrame(startTime: startTime, endTime: endTime),
            ),
          ),
    );
  }

  /// Formats a TimeOfDay object into a string (e.g., "08:30").
  String _formatTimeOfDay(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  /// Shows a color picker dialog for selecting a custom theme color.
  void _showColorPicker(ThemeNotifier themeNotifier) {
    final iosColors = [
      const Color(0xFF007AFF), // iOS Blue
      const Color(0xFF34C759), // iOS Green
      const Color(0xFFFF9500), // iOS Orange
      const Color(0xFFFF2D55), // iOS Red
      const Color(0xFF5856D6), // iOS Purple
      const Color(0xFFAF52DE), // iOS Pink
      const Color(0xFF5AC8FA), // iOS Light Blue
      const Color(0xFFFFCC00), // iOS Yellow
      const Color(0xFF8E8E93), // iOS Gray
    ];

    Color selectedColor = themeNotifier.customColor;

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Container(
                  height: 400,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoDynamicColor.resolve(
                      CupertinoColors.systemBackground,
                      context,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Text(
                            'Choose Color',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: const Text('Done'),
                            onPressed: () {
                              themeNotifier.setCustomColor(selectedColor);
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'iOS Colors',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children:
                            iosColors.map((color) {
                              final isSelected =
                                  selectedColor.value == color.value;
                              return GestureDetector(
                                onTap:
                                    () => setState(() => selectedColor = color),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? CupertinoColors.white
                                              : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: CupertinoColors.systemGrey
                                            .withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child:
                                      isSelected
                                          ? const Icon(
                                            CupertinoIcons.checkmark,
                                            color: CupertinoColors.white,
                                            size: 20,
                                          )
                                          : null,
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 24),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: CupertinoDynamicColor.resolve(
                          CupertinoColors.systemGrey5,
                          context,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        child: const Text('Choose Custom Color'),
                        onPressed: () {
                          final additionalColors = [
                            const Color(0xFF964B00), // Brown
                            const Color(0xFF50C878), // Emerald
                            const Color(0xFFFFC0CB), // Pink
                            const Color(0xFF40E0D0), // Turquoise
                            const Color(0xFFDE3163), // Cerise
                          ];
                          final randomColor =
                              additionalColors[DateTime.now()
                                      .millisecondsSinceEpoch %
                                  additionalColors.length];
                          setState(() => selectedColor = randomColor);
                        },
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _showDateFormatPicker(BuildContext context) {
    final options = [
      'DD-MM-YYYY (e.g., 29-03-2025)',
      'MM-DD-YYYY (e.g., 03-29-2025)',
    ];
    final values = ['DD-MM-YYYY', 'MM-DD-YYYY'];
    int selectedIndex = values.indexOf(_dateFormat);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 280,
        color: CupertinoFormTheme(context).backgroundColor,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () {
                      setState(() => _dateFormat = values[selectedIndex]);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32.0,
                scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                onSelectedItemChanged: (index) => selectedIndex = index,
                children: options.map((option) => Center(child: Text(option))).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthFormatPicker(BuildContext context) {
    final options = [
      'Numeric (e.g., 03)',
      'Short (e.g., Mar)',
      'Full (e.g., March)',
    ];
    final values = ['numeric', 'short', 'full'];
    int selectedIndex = values.indexOf(_monthFormat);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 280,
        color: CupertinoFormTheme(context).backgroundColor,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () {
                      setState(() => _monthFormat = values[selectedIndex]);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32.0,
                scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                onSelectedItemChanged: (index) => selectedIndex = index,
                children: options.map((option) => Center(child: Text(option))).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return CupertinoPageScaffold(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: [
            // Theme Section
            SettingsSection(
              title: 'Theme',
              footerText:
                  'Choose a theme that suits your preferences and needs.',
              children: [
                SettingsSegmentedItem(
                  label: 'Appearance',
                  subtitle: 'Select your preferred visual style',
                  groupValue:
                      themeNotifier.themeMode.toString().split('.').last,
                  children: {
                    'system': const Text('System'),
                    'light': const Text('Light'),
                    'dark': const Text('Night'),
                    'adhd': const Text('ADHD'),
                    'custom': Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: themeNotifier.customColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: const Text(
                            'Custom',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  },
                  onValueChanged: (value) {
                    AppTheme themeValue;
                    switch (value) {
                      case 'system':
                        themeValue = AppTheme.system;
                        break;
                      case 'light':
                        themeValue = AppTheme.light;
                        break;
                      case 'dark':
                        themeValue = AppTheme.dark;
                        break;
                      case 'adhd':
                        themeValue = AppTheme.adhd;
                        break;
                      case 'custom':
                        themeValue = AppTheme.custom;
                        break;
                      default:
                        themeValue = AppTheme.system;
                    }
                    themeNotifier.setThemeMode(themeValue);
                  },
                ),
                const SizedBox(height: 16),
                SettingsToggleItem(
                  label: 'Dark Mode',
                  value: themeNotifier.brightness == Brightness.dark,
                  onChanged: (value) {
                    themeNotifier.setBrightness(
                      value ? Brightness.dark : Brightness.light,
                    );
                  },
                  subtitle: 'Toggle between light and dark mode',
                ),
                if (themeNotifier.themeMode == AppTheme.custom) ...[
                  const SizedBox(height: 16),
                  SettingsItem(
                    label: 'Theme Color',
                    subtitle: 'Choose your custom theme color',
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: themeNotifier.customColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: CupertinoColors.systemGrey3,
                          width: 1,
                        ),
                      ),
                    ),
                    onTap: () => _showColorPicker(themeNotifier),
                  ),
                  SettingsSliderItem(
                    label: 'Color Intensity',
                    value: themeNotifier.colorIntensity,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    valueLabel:
                        '${(themeNotifier.colorIntensity * 100).round()}%',
                    onChanged:
                        (value) => themeNotifier.setColorIntensity(value),
                    subtitle: 'Adjust the intensity of your custom color',
                  ),
                  SettingsSliderItem(
                    label: 'Noise Effect',
                    value: themeNotifier.noiseLevel,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    valueLabel: '${(themeNotifier.noiseLevel * 100).round()}%',
                    onChanged: (value) => themeNotifier.setNoiseLevel(value),
                    subtitle: 'Add subtle noise effect to the background',
                  ),
                ],
              ],
            ),

            // Sleep Schedule Section
            SettingsSection(
              title: 'Sleep Schedule',
              footerText:
                  'Set your sleep and wake up times to help optimize your schedule.',
              children: [
                SettingsTimePickerItem(
                  label: 'Sleep Time',
                  time: _sleepTime,
                  onTimeSelected: (time) => setState(() => _sleepTime = time),
                  leading: const Icon(
                    CupertinoIcons.moon_fill,
                    color: CupertinoColors.systemIndigo,
                  ),
                  use24HourFormat: false,
                ),
                SettingsTimePickerItem(
                  label: 'Wake Up Time',
                  time: _wakeupTime,
                  onTimeSelected: (time) => setState(() => _wakeupTime = time),
                  leading: const Icon(
                    CupertinoIcons.sunrise_fill,
                    color: CupertinoColors.systemOrange,
                  ),
                  use24HourFormat: false,
                ),
              ],
            ),

            // Active Days Section
            SettingsSection(
              title: 'Active Days',
              footerText: 'Select the days when you want to be active.',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 16.0,
                  ),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children:
                        _activeDays.keys
                            .map(
                              (day) => SettingsButton(
                                label: day.substring(0, 3),
                                isPrimary: _activeDays[day]!,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 6.0,
                                ),
                                borderRadius: BorderRadius.circular(16.0),
                                minSize: 0,
                                onPressed:
                                    () => setState(
                                      () =>
                                          _activeDays[day] = !_activeDays[day]!,
                                    ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),

            // Meal Times Section
            SettingsSection(
              title: 'Meal Times',
              footerText:
                  'Set your regular meal times to help schedule your day.',
              children: [
                ..._mealTimes.map(
                  (meal) => SettingsItem(
                    label:
                        'Meal ${_formatTimeOfDay(meal.startTime)} - ${_formatTimeOfDay(meal.endTime)}',
                    leading: const Icon(
                      CupertinoIcons.clock,
                      color: CupertinoColors.systemOrange,
                    ),
                    trailing: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(
                        CupertinoIcons.delete,
                        color: CupertinoColors.systemRed,
                      ),
                      onPressed: () => setState(() => _mealTimes.remove(meal)),
                    ),
                  ),
                ),
                SettingsItem(
                  label: 'Add Meal Time',
                  leading: const Icon(
                    CupertinoIcons.add_circled,
                    color: CupertinoColors.systemOrange,
                  ),
                  onTap: _showAddMealDialog,
                ),
              ],
            ),

            // Free Times Section
            SettingsSection(
              title: 'Free Times',
              footerText:
                  'Set your free time periods to avoid scheduling tasks during these times.',
              children: [
                ..._freeTimes.map(
                  (freeTime) => SettingsItem(
                    label:
                        'Free ${_formatTimeOfDay(freeTime.startTime)} - ${_formatTimeOfDay(freeTime.endTime)}',
                    leading: const Icon(
                      CupertinoIcons.clock,
                      color: CupertinoColors.systemGreen,
                    ),
                    trailing: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(
                        CupertinoIcons.delete,
                        color: CupertinoColors.systemRed,
                      ),
                      onPressed:
                          () => setState(() => _freeTimes.remove(freeTime)),
                    ),
                  ),
                ),
                SettingsItem(
                  label: 'Add Free Time',
                  leading: const Icon(
                    CupertinoIcons.add_circled,
                    color: CupertinoColors.systemGreen,
                  ),
                  onTap: _showAddFreeTimeDialog,
                ),
              ],
            ),

            // Session Duration Section
            SettingsSection(
              title: 'Session Duration',
              footerText:
                  'Set the minimum duration for a task session in minutes.',
              children: [
                SettingsSliderItem(
                  label: 'Minimum Session',
                  value: _minSessionDuration.toDouble(),
                  min: 5,
                  max: 120,
                  divisions: 23,
                  valueLabel: '${_minSessionDuration.round()} min',
                  onChanged:
                      (value) =>
                          setState(() => _minSessionDuration = value.round()),
                  subtitle: 'The minimum time you want to spend on a task',
                ),
              ],
            ),

            // Break Duration Section
            SettingsSection(
              title: 'Break Duration',
              footerText:
                  'Set the duration for breaks between tasks in minutes.',
              children: [
                SettingsSliderItem(
                  label: 'Break Time',
                  value: _breakDuration.toDouble(),
                  min: 5,
                  max: 30,
                  divisions: 5,
                  valueLabel: '${_breakDuration.round()} min',
                  onChanged:
                      (value) => setState(() => _breakDuration = value.round()),
                  subtitle:
                      'The time you want to take for breaks between tasks',
                ),
              ],
            ),

            // Date & Time Format Section
            SettingsSection(
              title: 'Date & Time Format',
              footerText: 'Customize how dates and times are displayed in the app.',
              children: [
                SettingsItem(
                  label: 'Date Format',
                  subtitle: 'Choose your preferred date format',
                  trailing: Text(
                    _dateFormat == 'DD-MM-YYYY' ? 'DD-MM-YYYY (e.g., 29-03-2025)' : 'MM-DD-YYYY (e.g., 03-29-2025)',
                    style: const TextStyle(color: CupertinoColors.systemGrey),
                  ),
                  onTap: () => _showDateFormatPicker(context),
                ),
                const SizedBox(height: 16),
                SettingsItem(
                  label: 'Month Format',
                  subtitle: 'Choose how months are displayed',
                  trailing: Text(
                    _monthFormat == 'numeric'
                        ? 'Numeric (e.g., 03)'
                        : _monthFormat == 'short'
                        ? 'Short (e.g., Mar)'
                        : 'Full (e.g., March)',
                    style: const TextStyle(color: CupertinoColors.systemGrey),
                  ),
                  onTap: () => _showMonthFormatPicker(context),
                ),
                const SizedBox(height: 16),
                SettingsToggleItem(
                  label: '24-Hour Format',
                  value: _is24HourFormat,
                  onChanged: (value) => setState(() => _is24HourFormat = value),
                  subtitle: 'Use 24-hour (e.g., 14:30) or 12-hour (e.g., 2:30 PM) format',
                ),
              ],
            ),

            // Logs Section
            SettingsSection(
              title: 'Logs',
              footerText:
                  'Save and share application logs for troubleshooting.',
              children: [
                SettingsItem(
                  label: 'Save Logs',
                  subtitle: 'Save application logs to a file',
                  leading: const Icon(
                    CupertinoIcons.doc_text,
                    color: CupertinoColors.systemBlue,
                  ),
                  onTap: _saveLogs,
                ),
              ],
            ),

            // Save Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SettingsButton(
                label: 'Save Settings',
                isPrimary: true,
                icon: CupertinoIcons.check_mark,
                onPressed: _saveSettings,
              ),
            ),
          ],
        ),
      ),
    );
  }
}