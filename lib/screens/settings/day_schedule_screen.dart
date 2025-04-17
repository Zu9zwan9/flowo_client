import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../blocs/tasks_controller/task_manager_cubit.dart';
import '../../models/day_schedule.dart';
import '../../models/time_frame.dart';
import '../../models/user_settings.dart';
import '../../utils/formatter/date_time_formatter.dart';
import '../widgets/settings_widgets.dart';

class DayScheduleScreen extends StatefulWidget {
  const DayScheduleScreen({super.key});

  @override
  State<DayScheduleScreen> createState() => _DayScheduleScreenState();
}

class _DayScheduleScreenState extends State<DayScheduleScreen> {
  late String _selectedDay;
  late Map<String, DaySchedule> _daySchedules;
  late bool _is24HourFormat;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadSettings();
  }

  void _loadSettings() {
    final userSettings =
        context.read<TaskManagerCubit>().taskManager.userSettings;
    setState(() {
      _daySchedules = Map.from(userSettings.daySchedules);
      _selectedDay = 'Monday'; // Default to Monday
      _is24HourFormat = userSettings.is24HourFormat;
    });
  }

  void _saveSettings() {
    final taskManagerCubit = context.read<TaskManagerCubit>();
    final userSettings = taskManagerCubit.taskManager.userSettings;

    // Create a new UserSettings object with the updated day schedules
    final updatedSettings = UserSettings(
      name: userSettings.name,
      minSession: userSettings.minSession,
      breakTime: userSettings.breakTime,
      mealBreaks: userSettings.mealBreaks,
      sleepTime: userSettings.sleepTime,
      freeTime: userSettings.freeTime,
      activeDays: userSettings.activeDays,
      daySchedules: _daySchedules,
      defaultNotificationType: userSettings.defaultNotificationType,
      dateFormat: userSettings.dateFormat,
      monthFormat: userSettings.monthFormat,
      is24HourFormat: userSettings.is24HourFormat,
      themeMode: userSettings.themeMode,
      customColorValue: userSettings.customColorValue,
      colorIntensity: userSettings.colorIntensity,
      noiseLevel: userSettings.noiseLevel,
      useGradient: userSettings.useGradient,
      secondaryColorValue: userSettings.secondaryColorValue,
      useDynamicColors: userSettings.useDynamicColors,
    );

    taskManagerCubit.updateUserSettings(updatedSettings);

    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: const Text('Settings Saved'),
            content: const Text('Your day schedules have been updated.'),
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
            color: CupertinoTheme.of(context).scaffoldBackgroundColor,
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
          (startTime, endTime) => setState(() {
            final daySchedule = _daySchedules[_selectedDay]!;
            // Create a mutable copy of the list if it's a const list
            if (daySchedule.mealBreaks.isEmpty &&
                identical(daySchedule.mealBreaks, const [])) {
              daySchedule.mealBreaks = [];
            }
            daySchedule.mealBreaks.add(
              TimeFrame(startTime: startTime, endTime: endTime),
            );
          }),
    );
  }

  void _showAddFreeTimeDialog() {
    _showAddTimeSlotDialog(
      title: 'Free Time',
      iconColor: CupertinoColors.systemGreen,
      onAdd:
          (startTime, endTime) => setState(() {
            final daySchedule = _daySchedules[_selectedDay]!;
            // Create a mutable copy of the list if it's a const list
            if (daySchedule.freeTimes.isEmpty &&
                identical(daySchedule.freeTimes, const [])) {
              daySchedule.freeTimes = [];
            }
            daySchedule.freeTimes.add(
              TimeFrame(startTime: startTime, endTime: endTime),
            );
          }),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final dateTime = DateTime(2022, 1, 1, time.hour, time.minute);
    return DateTimeFormatter.formatTime(
      dateTime,
      is24HourFormat: _is24HourFormat,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDaySchedule = _daySchedules[_selectedDay]!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Day Schedules'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saveSettings,
          child: const Text('Save'),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: [
            SettingsSection(
              title: 'Select Day',
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
                        _daySchedules.keys
                            .map(
                              (day) => SettingsButton(
                                label: day.substring(0, 3),
                                isPrimary: _selectedDay == day,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 6.0,
                                ),
                                borderRadius: BorderRadius.circular(16.0),
                                minSize: 0,
                                onPressed:
                                    () => setState(() => _selectedDay = day),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: 'Active Day',
              children: [
                SettingsToggleItem(
                  label: 'Enable $_selectedDay',
                  value: currentDaySchedule.isActive,
                  onChanged:
                      (value) => setState(() {
                        currentDaySchedule.isActive = value;
                      }),
                ),
              ],
            ),
            SettingsSection(
              title: 'Sleep Schedule',
              footerText: 'Set your sleep and wake up times for $_selectedDay.',
              children: [
                SettingsTimePickerItem(
                  label: 'Sleep Time',
                  time: currentDaySchedule.sleepTime.startTime,
                  onTimeSelected:
                      (time) => setState(() {
                        currentDaySchedule.sleepTime = TimeFrame(
                          startTime: time,
                          endTime: currentDaySchedule.sleepTime.endTime,
                        );
                      }),
                  leading: const Icon(
                    CupertinoIcons.moon_fill,
                    color: CupertinoColors.systemIndigo,
                  ),
                  use24HourFormat: _is24HourFormat,
                ),
                SettingsTimePickerItem(
                  label: 'Wake Up Time',
                  time: currentDaySchedule.sleepTime.endTime,
                  onTimeSelected:
                      (time) => setState(() {
                        currentDaySchedule.sleepTime = TimeFrame(
                          startTime: currentDaySchedule.sleepTime.startTime,
                          endTime: time,
                        );
                      }),
                  leading: const Icon(
                    CupertinoIcons.sunrise_fill,
                    color: CupertinoColors.systemOrange,
                  ),
                  use24HourFormat: _is24HourFormat,
                ),
              ],
            ),
            SettingsSection(
              title: 'Meal Times',
              footerText: 'Set your regular meal times for $_selectedDay.',
              children: [
                ...currentDaySchedule.mealBreaks.map(
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
                          () => setState(
                            () => currentDaySchedule.mealBreaks.remove(meal),
                          ),
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
                  'Set your free time periods for $_selectedDay to avoid scheduling tasks during these times.',
              children: [
                ...currentDaySchedule.freeTimes.map(
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
                          () => setState(
                            () => currentDaySchedule.freeTimes.remove(freeTime),
                          ),
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
          ],
        ),
      ),
    );
  }
}
