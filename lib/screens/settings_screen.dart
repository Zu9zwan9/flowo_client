import 'dart:ui';

import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/design/glassmorphic_container.dart';
import 'package:flowo_client/models/time_frame.dart';
import 'package:flowo_client/models/user_settings.dart';
import 'package:flowo_client/screens/widgets/glassmorphic_settings_button.dart';
import 'package:flowo_client/screens/widgets/glassmorphic_settings_slider_item.dart';
import 'package:flowo_client/screens/widgets/glassmorphic_settings_time_picker_item.dart';
import 'package:flowo_client/screens/widgets/glassmorphic_settings_widgets.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme_notifier.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _minSessionDuration = (_minSessionDuration).clamp(5, 120);
    _breakDuration = (_breakDuration).clamp(5, 30);
  }

  void _loadSettings() {
    final currentSettings =
        context.read<TaskManagerCubit>().taskManager.userSettings;
    setState(() {
      _sleepTime =
          currentSettings.sleepTime.isNotEmpty
              ? currentSettings.sleepTime.first.startTime
              : const TimeOfDay(hour: 22, minute: 0);
      _wakeupTime =
          currentSettings.sleepTime.isNotEmpty
              ? currentSettings.sleepTime.first.endTime
              : const TimeOfDay(hour: 7, minute: 0);
      _breakDuration =
          (currentSettings.breakTime ?? 15 * 60 * 1000) ~/ (60 * 1000);
      _minSessionDuration = currentSettings.minSession ~/ (60 * 1000);
      _mealTimes = List.from(
        currentSettings.mealBreaks.isNotEmpty
            ? currentSettings.mealBreaks
            : [
              TimeFrame(
                startTime: const TimeOfDay(hour: 8, minute: 0),
                endTime: const TimeOfDay(hour: 8, minute: 30),
              ),
              TimeFrame(
                startTime: const TimeOfDay(hour: 13, minute: 0),
                endTime: const TimeOfDay(hour: 13, minute: 30),
              ),
              TimeFrame(
                startTime: const TimeOfDay(hour: 19, minute: 0),
                endTime: const TimeOfDay(hour: 19, minute: 30),
              ),
            ],
      );
      _freeTimes = List.from(
        currentSettings.freeTime.isNotEmpty
            ? currentSettings.freeTime
            : [
              TimeFrame(
                startTime: const TimeOfDay(hour: 17, minute: 0),
                endTime: const TimeOfDay(hour: 18, minute: 30),
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
    });
  }

  void _saveSettings() {
    final userSettings = UserSettings(
      name: 'Default',
      minSession: _minSessionDuration * 60 * 1000,
      breakTime: _breakDuration * 60 * 1000,
      sleepTime: [TimeFrame(startTime: _sleepTime, endTime: _wakeupTime)],
      mealBreaks: List.from(_mealTimes),
      freeTime: List.from(_freeTimes),
      activeDays: Map.from(_activeDays),
    );

    context.read<TaskManagerCubit>().updateUserSettings(userSettings);
    logInfo('Settings saved');

    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;

    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (_) => BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: glassmorphicTheme.defaultBlur,
              sigmaY: glassmorphicTheme.defaultBlur,
            ),
            child: CupertinoAlertDialog(
              title: const Text('Settings Saved'),
              content: const Text(
                'Your schedule preferences have been updated.',
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _saveLogs() async {
    // Log this action itself
    appLogger.info('Save logs button pressed', 'Settings');

    // Save logs to file
    final filePath = await appLogger.saveToFile(context);

    if (filePath != null) {
      // Show success dialog with options
      final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
      final glassmorphicTheme = themeNotifier.glassmorphicTheme;

      showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder:
            (_) => BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: glassmorphicTheme.defaultBlur,
                sigmaY: glassmorphicTheme.defaultBlur,
              ),
              child: CupertinoAlertDialog(
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
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
      );

      // Log success
      appLogger.info('Logs saved successfully', 'Settings', {'path': filePath});
    }
  }

  Future<void> _shareLogFile(String filePath) async {
    try {
      // Show a simple dialog with the file path since we can't directly share files
      // without additional setup
      final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
      final glassmorphicTheme = themeNotifier.glassmorphicTheme;

      showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder:
            (_) => BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: glassmorphicTheme.defaultBlur,
                sigmaY: glassmorphicTheme.defaultBlur,
              ),
              child: CupertinoAlertDialog(
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
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
      );

      appLogger.info('Log file location shown', 'Settings');
    } catch (e) {
      appLogger.error('Error showing log file location', 'Settings', {
        'error': e.toString(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to show log file location: $e')),
      );
    }
  }

  void _showTimePicker({
    required TimeOfDay initialTime,
    required Function(TimeOfDay) onTimeSelected,
  }) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;

    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: glassmorphicTheme.defaultBlur,
                sigmaY: glassmorphicTheme.defaultBlur,
              ),
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: themeNotifier.backgroundColor.withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border.all(
                    color: glassmorphicTheme.borderColor,
                    width: glassmorphicTheme.defaultBorderWidth,
                  ),
                ),
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

    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;

    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setDialogState) => BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: glassmorphicTheme.defaultBlur / 2,
                    sigmaY: glassmorphicTheme.defaultBlur / 2,
                  ),
                  child: CupertinoActionSheet(
                    title: Text('Add $title'),
                    message: Text('Set your $title start and end times'),
                    actions: [
                      CupertinoActionSheetAction(
                        child: Text(
                          'Start Time: ${_formatTimeOfDay(startTime)}',
                        ),
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
                                  (time) =>
                                      setDialogState(() => endTime = time),
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
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
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

  String _formatTimeOfDay(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        border: null, // Remove the bottom border for a cleaner look
        backgroundColor: themeNotifier.backgroundColor.withOpacity(0.8),
        middle: const Text('Settings'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          children: [
            // Theme Section
            GlassmorphicSettingsSection(
              title: 'Theme',
              footerText:
                  'Choose a theme that suits your preferences and needs.',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 8.0,
                  ),
                  child: Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16.0,
                      runSpacing: 16.0,
                      children: [
                        _buildThemeTab(
                          context: context,
                          themeMode: AppTheme.light,
                          currentTheme: themeNotifier.themeMode,
                          icon: CupertinoIcons.sun_max_fill,
                          label: 'Light',
                          accentColor: CupertinoColors.systemYellow,
                          onTap:
                              () => themeNotifier.setThemeMode(AppTheme.light),
                        ),
                        _buildThemeTab(
                          context: context,
                          themeMode: AppTheme.dark,
                          currentTheme: themeNotifier.themeMode,
                          icon: CupertinoIcons.moon_stars_fill,
                          label: 'Night',
                          accentColor: CupertinoColors.systemIndigo,
                          onTap:
                              () => themeNotifier.setThemeMode(AppTheme.dark),
                        ),
                        _buildThemeTab(
                          context: context,
                          themeMode: AppTheme.adhd,
                          currentTheme: themeNotifier.themeMode,
                          icon: CupertinoIcons.star_fill,
                          label: 'ADHD',
                          accentColor: CupertinoColors.systemPink,
                          onTap:
                              () => themeNotifier.setThemeMode(AppTheme.adhd),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Current theme: ${themeNotifier.themeMode == AppTheme.light
                        ? 'Light'
                        : themeNotifier.themeMode == AppTheme.dark
                        ? 'Night'
                        : 'ADHD'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            // Sleep Schedule Section
            GlassmorphicSettingsSection(
              title: 'Sleep Schedule',
              footerText:
                  'Set your sleep and wake up times to help optimize your schedule.',
              children: [
                GlassmorphicSettingsTimePickerItem(
                  label: 'Sleep Time',
                  time: _sleepTime,
                  onTimeSelected: (time) => setState(() => _sleepTime = time),
                  leading: const Icon(
                    CupertinoIcons.moon_fill,
                    color: CupertinoColors.systemIndigo,
                  ),
                  use24HourFormat: false,
                ),
                GlassmorphicSettingsTimePickerItem(
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
            GlassmorphicSettingsSection(
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
                              (day) => GlassmorphicSettingsButton(
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
            GlassmorphicSettingsSection(
              title: 'Meal Times',
              footerText:
                  'Set your regular meal times to help schedule your day.',
              children: [
                ..._mealTimes
                    .map(
                      (meal) => GlassmorphicSettingsItem(
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
                          onPressed:
                              () => setState(() => _mealTimes.remove(meal)),
                        ),
                      ),
                    )
                    .toList(),
                GlassmorphicSettingsItem(
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
            GlassmorphicSettingsSection(
              title: 'Free Times',
              footerText:
                  'Set your free time periods to avoid scheduling tasks during these times.',
              children: [
                ..._freeTimes
                    .map(
                      (freeTime) => GlassmorphicSettingsItem(
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
                    )
                    .toList(),
                GlassmorphicSettingsItem(
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
            GlassmorphicSettingsSection(
              title: 'Session Duration',
              footerText:
                  'Set the minimum duration for a task session in minutes.',
              children: [
                GlassmorphicSettingsSliderItem(
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
            GlassmorphicSettingsSection(
              title: 'Break Duration',
              footerText:
                  'Set the duration for breaks between tasks in minutes.',
              children: [
                GlassmorphicSettingsSliderItem(
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

            // Logs Section
            GlassmorphicSettingsSection(
              title: 'Logs',
              footerText:
                  'Save and share application logs for troubleshooting.',
              children: [
                GlassmorphicSettingsItem(
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
              child: GlassmorphicSettingsButton(
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

/// Builds a custom glassmorphic theme selection tab
Widget _buildThemeTab({
  required BuildContext context,
  required AppTheme themeMode,
  required AppTheme currentTheme,
  required IconData icon,
  required String label,
  required Color accentColor,
  required VoidCallback onTap,
}) {
  final themeNotifier = Provider.of<ThemeNotifier>(context);
  final glassmorphicTheme = themeNotifier.glassmorphicTheme;
  final isSelected = themeMode == currentTheme;

  return GestureDetector(
    onTap: onTap,
    child: GlassmorphicContainer(
      width: 100,
      height: 90,
      blur: glassmorphicTheme.defaultBlur * (isSelected ? 1.0 : 0.6),
      opacity: isSelected ? 0.2 : 0.1,
      borderRadius: BorderRadius.circular(12),
      borderWidth: isSelected ? 1.5 : 0.5,
      borderColor:
          isSelected
              ? accentColor
              : glassmorphicTheme.borderColor.withOpacity(0.3),
      backgroundColor:
          isSelected ? accentColor.withOpacity(0.1) : Colors.transparent,
      useGradient: isSelected,
      gradientColors: [
        accentColor.withOpacity(0.15),
        accentColor.withOpacity(0.05),
      ],
      showShimmer: isSelected,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: isSelected ? accentColor : CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? accentColor : CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    ),
  );
}
