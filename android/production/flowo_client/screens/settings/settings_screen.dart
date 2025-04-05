import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/models/time_frame.dart';
import 'package:flowo_client/models/user_settings.dart';
import 'package:flowo_client/screens/widgets/settings_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/cupertino_form_theme.dart';
import '../../models/app_theme.dart';
import '../../theme_notifier.dart';
import '../../utils/formatter/date_time_formatter.dart';
import '../../utils/logger.dart';

abstract class ThemeSelectionStrategy {
  Widget buildThemeSelector(
    BuildContext context,
    ThemeNotifier themeNotifier,
    ValueChanged<AppTheme> onThemeChanged,
  );
}

class ThemeTabsStrategy implements ThemeSelectionStrategy {
  const ThemeTabsStrategy();

  @override
  Widget buildThemeSelector(
    BuildContext context,
    ThemeNotifier themeNotifier,
    ValueChanged<AppTheme> onThemeChanged,
  ) {
    return _ThemeTabs(
      themeNotifier: themeNotifier,
      onThemeChanged: onThemeChanged,
    );
  }
}

class _ThemeTabs extends StatelessWidget {
  final ThemeNotifier themeNotifier;
  final ValueChanged<AppTheme> onThemeChanged;

  const _ThemeTabs({required this.themeNotifier, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    final currentTheme = themeNotifier.themeMode.toString().split('.').last;
    const themes = {'light': 'Light', 'dark': 'Dark', 'custom': 'Custom'};

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appearance',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
          ),
          const SizedBox(height: 4),
          Text(
            'Select your preferred visual style',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.systemGrey,
                context,
              ),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.systemGrey6,
                context,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children:
                  themes.entries
                      .map(
                        (entry) => _buildTab(
                          context,
                          entry.value,
                          entry.key,
                          currentTheme,
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    String label,
    String value,
    String currentTheme,
  ) {
    final isSelected = value == currentTheme;
    final isCustom = value == 'custom';

    return Expanded(
      child: GestureDetector(
        onTap: () {
          final themeValue = AppTheme.values.firstWhere(
            (e) => e.toString().split('.').last == value,
            orElse: () => AppTheme.system,
          );
          onThemeChanged(themeValue);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          height: double.infinity,
          decoration: BoxDecoration(
            color:
                isSelected
                    ? CupertinoDynamicColor.resolve(
                      CupertinoColors.systemBackground,
                      context,
                    )
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isCustom) ...[
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: themeNotifier.customColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
              Text(
                label,
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  color:
                      isSelected
                          ? CupertinoDynamicColor.resolve(
                            CupertinoColors.label,
                            context,
                          )
                          : CupertinoDynamicColor.resolve(
                            CupertinoColors.secondaryLabel,
                            context,
                          ),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final ThemeSelectionStrategy themeSelectionStrategy;

  const SettingsScreen({
    super.key,
    this.themeSelectionStrategy = const ThemeTabsStrategy(),
  });

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

  void _loadSettings() {
    final currentSettings = context.read<TaskManagerCubit>().taskManager.userSettings;
    setState(() {
      // Sleep Time (unchanged - works correctly)
      _sleepTime = currentSettings.sleepTime.isNotEmpty
          ? currentSettings.sleepTime.first.startTime
          : const TimeOfDay(hour: 22, minute: 0);
      _wakeupTime = currentSettings.sleepTime.isNotEmpty
          ? currentSettings.sleepTime.first.endTime
          : const TimeOfDay(hour: 7, minute: 0);

      // Break and Session Duration (unchanged)
      _breakDuration = (currentSettings.breakTime ?? 15 * 60 * 1000) ~/ (60 * 1000);
      _minSessionDuration = currentSettings.minSession ~/ (60 * 1000);
      _mealTimes = List.from(currentSettings.mealBreaks);
      _freeTimes = List.from(currentSettings.freeTime);
      _activeDays = Map.from(currentSettings.activeDays ?? {
        'Monday': true,
        'Tuesday': true,
        'Wednesday': true,
        'Thursday': true,
        'Friday': true,
        'Saturday': true,
        'Sunday': true,
      });
      _dateFormat = currentSettings.dateFormat;
      _monthFormat = currentSettings.monthFormat;
      _is24HourFormat = currentSettings.is24HourFormat;
    });
  }

  void _saveSettings() {
    // Get the current theme settings from ThemeNotifier
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

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
      // Include theme-related settings
      themeMode: themeNotifier.themeMode,
      customColorValue: themeNotifier.customColor.value,
      colorIntensity: themeNotifier.colorIntensity,
      noiseLevel: themeNotifier.noiseLevel,
    );

    context.read<TaskManagerCubit>().updateUserSettings(userSettings);
    logInfo('Settings saved with theme preferences');

    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
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

  Future<void> _showTimePicker({
    required TimeOfDay initialTime,
    required Function(TimeOfDay) onTimeSelected,
  }) async {
    TimeOfDay? selectedTime = initialTime;

    await showCupertinoModalPopup(
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
                        onPressed: () {
                          onTimeSelected(selectedTime!);
                          Navigator.pop(context);
                        },
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
                    use24hFormat: _is24HourFormat,
                    onDateTimeChanged: (dateTime) {
                      selectedTime = TimeOfDay(
                        hour: dateTime.hour,
                        minute: dateTime.minute,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

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

  String _formatTimeOfDay(TimeOfDay time) {
    final dateTime = DateTime(2022, 1, 1, time.hour, time.minute);
    return DateTimeFormatter.formatTime(
      dateTime,
      is24HourFormat: _is24HourFormat,
    );
  }

  void _showColorPicker(ThemeNotifier themeNotifier) {
    final iosColors = [
      const Color(0xFF007AFF),
      const Color(0xFF34C759),
      const Color(0xFFFF9500),
      const Color(0xFFFF2D55),
      const Color(0xFF5856D6),
      const Color(0xFFAF52DE),
      const Color(0xFF5AC8FA),
      const Color(0xFFFFCC00),
      const Color(0xFF8E8E93),
    ];

    Color selectedColor = themeNotifier.customColor;

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Container(
                  height: MediaQuery.of(context).size.height * 0.7,
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
                  child: SingleChildScrollView(
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
                                      () =>
                                          setState(() => selectedColor = color),
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
                        const SizedBox(height: 16),
                        const Text(
                          'Custom Color',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Hue slider
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            const Text('Hue', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CupertinoSlider(
                                value:
                                    HSVColor.fromColor(selectedColor).hue / 360,
                                onChanged: (value) {
                                  final hsvColor = HSVColor.fromColor(
                                    selectedColor,
                                  );
                                  setState(() {
                                    selectedColor =
                                        hsvColor.withHue(value * 360).toColor();
                                  });
                                },
                                activeColor: CupertinoColors.systemBlue,
                              ),
                            ),
                          ],
                        ),
                        // Saturation slider
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            const Text(
                              'Saturation',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CupertinoSlider(
                                value:
                                    HSVColor.fromColor(
                                      selectedColor,
                                    ).saturation,
                                onChanged: (value) {
                                  final hsvColor = HSVColor.fromColor(
                                    selectedColor,
                                  );
                                  setState(() {
                                    selectedColor =
                                        hsvColor
                                            .withSaturation(value)
                                            .toColor();
                                  });
                                },
                                activeColor: CupertinoColors.systemBlue,
                              ),
                            ),
                          ],
                        ),
                        // Value slider
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            const Text(
                              'Brightness',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CupertinoSlider(
                                value: HSVColor.fromColor(selectedColor).value,
                                onChanged: (value) {
                                  final hsvColor = HSVColor.fromColor(
                                    selectedColor,
                                  );
                                  setState(() {
                                    selectedColor =
                                        hsvColor.withValue(value).toColor();
                                  });
                                },
                                activeColor: CupertinoColors.systemBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  void _showSecondaryColorPicker(ThemeNotifier themeNotifier) {
    final iosColors = [
      const Color(0xFF34C759), // Green
      const Color(0xFFFF9500), // Orange
      const Color(0xFFFF2D55), // Red
      const Color(0xFF5856D6), // Purple
      const Color(0xFFAF52DE), // Magenta
      const Color(0xFF5AC8FA), // Teal
      const Color(0xFFFFCC00), // Yellow
      const Color(0xFF8E8E93), // Gray
      const Color(0xFF007AFF), // Blue
    ];

    Color selectedColor = themeNotifier.secondaryColor;

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Container(
                  height: MediaQuery.of(context).size.height * 0.7,
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
                  child: SingleChildScrollView(
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
                              'Choose Secondary Color',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Text('Done'),
                              onPressed: () {
                                themeNotifier.setSecondaryColor(selectedColor);
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
                        const SizedBox(height: 16),
                        // Show a preview of the gradient
                        Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                themeNotifier.customColor,
                                selectedColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              'Gradient Preview',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                                      () =>
                                          setState(() => selectedColor = color),
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
                        const Text(
                          'Custom Color',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Hue slider
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            const Text('Hue', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CupertinoSlider(
                                value:
                                    HSVColor.fromColor(selectedColor).hue / 360,
                                onChanged: (value) {
                                  final hsvColor = HSVColor.fromColor(
                                    selectedColor,
                                  );
                                  setState(() {
                                    selectedColor =
                                        hsvColor.withHue(value * 360).toColor();
                                  });
                                },
                                activeColor: CupertinoColors.systemBlue,
                              ),
                            ),
                          ],
                        ),
                        // Saturation slider
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            const Text(
                              'Saturation',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CupertinoSlider(
                                value:
                                    HSVColor.fromColor(
                                      selectedColor,
                                    ).saturation,
                                onChanged: (value) {
                                  final hsvColor = HSVColor.fromColor(
                                    selectedColor,
                                  );
                                  setState(() {
                                    selectedColor =
                                        hsvColor
                                            .withSaturation(value)
                                            .toColor();
                                  });
                                },
                                activeColor: CupertinoColors.systemBlue,
                              ),
                            ),
                          ],
                        ),
                        // Value slider
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            const Text(
                              'Brightness',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CupertinoSlider(
                                value: HSVColor.fromColor(selectedColor).value,
                                onChanged: (value) {
                                  final hsvColor = HSVColor.fromColor(
                                    selectedColor,
                                  );
                                  setState(() {
                                    selectedColor =
                                        hsvColor.withValue(value).toColor();
                                  });
                                },
                                activeColor: CupertinoColors.systemBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
                    scrollController: FixedExtentScrollController(
                      initialItem: selectedIndex,
                    ),
                    onSelectedItemChanged: (index) => selectedIndex = index,
                    children:
                        options
                            .map((option) => Center(child: Text(option)))
                            .toList(),
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
                    scrollController: FixedExtentScrollController(
                      initialItem: selectedIndex,
                    ),
                    onSelectedItemChanged: (index) => selectedIndex = index,
                    children:
                        options
                            .map((option) => Center(child: Text(option)))
                            .toList(),
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
            SettingsSection(
              title: 'Theme',
              footerText:
                  'Choose a theme that suits your preferences and needs.',
              children: [
                widget.themeSelectionStrategy.buildThemeSelector(
                  context,
                  themeNotifier,
                  (themeValue) => themeNotifier.setThemeMode(themeValue),
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
                  SettingsToggleItem(
                    label: 'Use Gradient',
                    value: themeNotifier.useGradient,
                    onChanged: (value) => themeNotifier.setUseGradient(value),
                    subtitle: 'Apply gradient effect to the background',
                  ),
                  if (themeNotifier.useGradient)
                    SettingsItem(
                      label: 'Secondary Color',
                      subtitle: 'Choose the secondary color for gradient',
                      leading: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: themeNotifier.secondaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: CupertinoColors.systemGrey3,
                            width: 1,
                          ),
                        ),
                      ),
                      onTap: () => _showSecondaryColorPicker(themeNotifier),
                    ),
                ],
              ],
            ),
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
                  use24HourFormat: _is24HourFormat,
                ),
                SettingsTimePickerItem(
                  label: 'Wake Up Time',
                  time: _wakeupTime,
                  onTimeSelected: (time) => setState(() => _wakeupTime = time),
                  leading: const Icon(
                    CupertinoIcons.sunrise_fill,
                    color: CupertinoColors.systemOrange,
                  ),
                  use24HourFormat: _is24HourFormat,
                ),
              ],
            ),
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
            SettingsSection(
              title: 'Date & Time Format',
              footerText:
                  'Customize how dates and times are displayed in the app.',
              showDivider: false,
              customFooter: null,
              children: [
                SettingsItem(
                  label: 'Date Format',
                  showDivider: false,
                  trailing: Text(
                    _dateFormat == 'DD-MM-YYYY' ? 'DD-MM-YYYY' : 'MM-DD-YYYY',
                    style: const TextStyle(color: CupertinoColors.systemGrey),
                  ),
                  onTap: () => _showDateFormatPicker(context),
                ),
                const SizedBox(height: 16),
                SettingsItem(
                  label: 'Month Format',
                  showDivider: false,
                  trailing: Text(
                    _monthFormat == 'numeric'
                        ? 'Numeric'
                        : _monthFormat == 'short'
                        ? 'Short'
                        : 'Full',
                    style: const TextStyle(color: CupertinoColors.systemGrey),
                  ),
                  onTap: () => _showMonthFormatPicker(context),
                ),
                const SizedBox(height: 16),
                SettingsToggleItem(
                  label: '24-Hour Format',
                  value: _is24HourFormat,
                  onChanged: (value) => setState(() => _is24HourFormat = value),
                ),
              ],
            ),
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
