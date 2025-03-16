import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/models/time_frame.dart';
import 'package:flowo_client/models/user_settings.dart';
import 'package:flowo_client/screens/widgets/settings_widgets.dart';
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

    showCupertinoDialog(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: const Text('Settings Saved'),
            content: const Text('Your schedule preferences have been updated.'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
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
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
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
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
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
    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => Container(
            height: 280,
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
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
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

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
        border: null, // Remove the bottom border for a cleaner look
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
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
                  groupValue: themeNotifier.currentThemeName,
                  children: const {
                    'Light': Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Light'),
                    ),
                    'Night': Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Night'),
                    ),
                    'ADHD': Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('ADHD'),
                    ),
                  },
                  onValueChanged: (value) => themeNotifier.setTheme(value),
                ),
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
                ..._mealTimes
                    .map(
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
                          onPressed:
                              () => setState(() => _mealTimes.remove(meal)),
                        ),
                      ),
                    )
                    .toList(),
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
                ..._freeTimes
                    .map(
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
                    )
                    .toList(),
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
