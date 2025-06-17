import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../blocs/tasks_controller/task_manager_cubit.dart';
import '../../models/day_schedule.dart';
import '../../models/time_frame.dart';
import '../../models/user_settings.dart';
import '../../utils/formatter/date_time_formatter.dart';
import '../widgets/settings_widgets.dart';

// Days of the week for assignment
enum WeekDay { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

class DayScheduleScreen extends StatefulWidget {
  final DaySchedule? initialSchedule;
  final bool isNewSchedule;

  const DayScheduleScreen({
    super.key,
    this.initialSchedule,
    this.isNewSchedule = false,
  });

  @override
  State<DayScheduleScreen> createState() => _DayScheduleScreenState();
}

class _DayScheduleScreenState extends State<DayScheduleScreen> {
  late DaySchedule _schedule;
  late bool _is24HourFormat;
  bool _hasChanges = false;

  // Controller for schedule name input field
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    // Clean up the text controller
    _nameController.dispose();
    super.dispose();
  }

  // Initialize settings and schedule data
  void _loadSettings() {
    final userSettings =
        context.read<TaskManagerCubit>().taskManager.userSettings;
    _is24HourFormat = userSettings.is24HourFormat;

    if (widget.initialSchedule != null) {
      // Copy the initial schedule for editing
      _schedule = DaySchedule(
        name: widget.initialSchedule!.name,
        day: List.from(widget.initialSchedule!.day),
        isActive: widget.initialSchedule!.isActive,
        sleepTime: TimeFrame(
          startTime: widget.initialSchedule!.sleepTime.startTime,
          endTime: widget.initialSchedule!.sleepTime.endTime,
        ),
        mealBreaks:
            widget.initialSchedule!.mealBreaks
                .map(
                  (b) => TimeFrame(startTime: b.startTime, endTime: b.endTime),
                )
                .toList(),
        freeTimes:
            widget.initialSchedule!.freeTimes
                .map(
                  (m) => TimeFrame(startTime: m.startTime, endTime: m.endTime),
                )
                .toList(),
      );
      _nameController.text = widget.initialSchedule!.name;
    } else if (widget.isNewSchedule) {
      // Create a new default schedule
      _schedule = DaySchedule(
        name: "New Schedule",
        day: [],
        isActive: true,
        sleepTime: TimeFrame(
          startTime: const TimeOfDay(hour: 23, minute: 0),
          endTime: const TimeOfDay(hour: 7, minute: 0),
        ),
        mealBreaks: [],
        freeTimes: [],
      );
      _nameController.text = "New Schedule";
    } else {
      // Default fallback (shouldn't happen with proper navigation)
      _schedule = DaySchedule(
        name: "Default Schedule",
        day: [],
        isActive: true,
        sleepTime: TimeFrame(
          startTime: const TimeOfDay(hour: 23, minute: 0),
          endTime: const TimeOfDay(hour: 7, minute: 0),
        ),
        mealBreaks: [],
        freeTimes: [],
      );
      _nameController.text = "Default Schedule";
    }
  }

  // Update sleep time settings
  void _updateSleepTime(TimeOfDay? bedtime, TimeOfDay? wakeUpTime) {
    setState(() {
      if (bedtime != null) {
        _schedule = _schedule.copyWith(
          sleepTime: TimeFrame(
            startTime: bedtime,
            endTime: _schedule.sleepTime.endTime,
          ),
        );
      }

      if (wakeUpTime != null) {
        _schedule = _schedule.copyWith(
          sleepTime: TimeFrame(
            startTime: _schedule.sleepTime.startTime,
            endTime: wakeUpTime,
          ),
        );
      }

      _hasChanges = true;
    });
  }

  // Main save method - validates and prepares for saving
  void _saveSettings() {
    // Update schedule name from controller
    _schedule = _schedule.copyWith(name: _nameController.text);

    // Validate that at least one day is assigned
    if (_schedule.day.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder:
            (dialogContext) => CupertinoAlertDialog(
              title: const Text('No Days Assigned'),
              content: const Text(
                'Please assign at least one day to this schedule.',
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
      );
      return;
    }

    // Validate name is not empty
    if (_nameController.text.trim().isEmpty) {
      showCupertinoDialog(
        context: context,
        builder:
            (dialogContext) => CupertinoAlertDialog(
              title: const Text('Missing Name'),
              content: const Text('Please enter a name for this schedule.'),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
      );
      return;
    }

    final taskManagerCubit = context.read<TaskManagerCubit>();
    final userSettings = taskManagerCubit.taskManager.userSettings;

    // Check for day conflicts with other schedules
    final conflicts = _checkDayConflicts(userSettings);

    if (conflicts.isNotEmpty) {
      // Format conflict messages for display
      final dayNames = conflicts
          .map((conflict) {
            final dayName =
                conflict['day'][0].toUpperCase() + conflict['day'].substring(1);
            return '$dayName (in schedule "${conflict['scheduleName']}")';
          })
          .join('\n');

      // Show conflict confirmation dialog
      showCupertinoDialog(
        context: context,
        builder:
            (dialogContext) => CupertinoAlertDialog(
              title: const Text('Day Conflicts Detected'),
              content: Text(
                'The following days are already assigned to other schedules:\n\n$dayNames\n\n'
                'These days will be moved to this schedule if you proceed.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: const Text('Move Days'),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    // Continue with saving and resolving conflicts
                    _saveWithConflictResolution();
                  },
                ),
              ],
            ),
      );
    } else {
      // No conflicts, proceed with normal save
      _saveWithConflictResolution();
    }
  }

  // Helper method for the actual save operation
  void _saveWithConflictResolution() {
    final taskManagerCubit = context.read<TaskManagerCubit>();
    final userSettings = taskManagerCubit.taskManager.userSettings;

    // Get current schedules list
    final schedules = List<DaySchedule>.from(userSettings.schedules);

    // Remove selected days from other schedules
    _removeSelectedDaysFromOtherSchedules(schedules);

    // Add or update this schedule
    if (widget.initialSchedule != null) {
      // Replace the existing schedule
      final index = schedules.indexWhere(
        (s) =>
            s.name == widget.initialSchedule!.name &&
            _areListsEqual(s.day, widget.initialSchedule!.day),
      );
      if (index >= 0) {
        schedules[index] = _schedule;
      } else {
        schedules.add(_schedule);
      }
    } else {
      // Add a new schedule
      schedules.add(_schedule);
    }

    // Remove empty schedules
    schedules.removeWhere((schedule) => schedule.day.isEmpty);

    // Update user settings
    final updatedSettings = userSettings.copyWith(schedules: schedules);

    // Save the updated settings
    taskManagerCubit.updateUserSettings(updatedSettings);

    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: const Text('Schedule Saved'),
            content: const Text('Your schedule has been updated.'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(
                    context,
                    _schedule,
                  ); // Return the updated schedule
                },
              ),
            ],
          ),
    );
  }

  // Helper method to check if two lists have the same elements
  bool _areListsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;

    // Convert both lists to lowercase for case-insensitive comparison
    final aLower = a.map((s) => s.toLowerCase()).toList()..sort();
    final bLower = b.map((s) => s.toLowerCase()).toList()..sort();

    for (int i = 0; i < aLower.length; i++) {
      if (aLower[i] != bLower[i]) return false;
    }

    return true;
  }

  // Check for conflicts between selected days and other schedules
  List<Map<String, dynamic>> _checkDayConflicts(UserSettings userSettings) {
    final conflicts = <Map<String, dynamic>>[];
    final existingSchedules = userSettings.schedules;

    logDebug('Checking day conflicts for schedule: ${_nameController.text}');
    logDebug('Days to check: ${_schedule.day.join(', ')}');

    for (final existingSchedule in existingSchedules) {
      // Skip comparing with the schedule being edited
      if (widget.initialSchedule != null &&
          existingSchedule.name == widget.initialSchedule!.name &&
          _areListsEqual(existingSchedule.day, widget.initialSchedule!.day)) {
        continue;
      }

      logDebug('Current schedule days: ${_schedule.day.join(', ')}');
      logDebug('Existing schedule days: ${existingSchedule.day.join(', ')}');

      // Check for day overlaps - USING CASE INSENSITIVE COMPARISON
      for (final day in _schedule.day) {
        logDebug(
          'Checking day conflict: $day in schedule ${existingSchedule.name}',
        );

        // Case insensitive comparison - check if any day in existing schedule matches
        final dayLower = day.toLowerCase();
        final conflict = existingSchedule.day.any(
          (existingDay) => existingDay.toLowerCase() == dayLower,
        );

        if (conflict) {
          logDebug('Caught conflict for day: $day');
          conflicts.add({'day': day, 'scheduleName': existingSchedule.name});
        }
      }
    }

    logDebug('Found ${conflicts.length} conflicts');
    return conflicts;
  }

  // Remove selected days from other schedules
  void _removeSelectedDaysFromOtherSchedules(List<DaySchedule> schedules) {
    // Get the set of selected days (lowercase for case-insensitive comparison)
    final selectedDaysLower =
        _schedule.day.map((day) => day.toLowerCase()).toSet();

    // For each schedule
    for (int i = 0; i < schedules.length; i++) {
      // Skip if it's the schedule being edited
      if (widget.initialSchedule != null &&
          schedules[i].name == widget.initialSchedule!.name &&
          _areListsEqual(schedules[i].day, widget.initialSchedule!.day)) {
        continue;
      }

      // Check if this schedule has any of the selected days (case-insensitive)
      final hasConflict = schedules[i].day.any(
        (day) => selectedDaysLower.contains(day.toLowerCase()),
      );

      if (hasConflict) {
        // Remove the conflicting days (case-insensitive)
        final remainingDays =
            schedules[i].day
                .where((day) => !selectedDaysLower.contains(day.toLowerCase()))
                .toList();

        // Replace the schedule with an updated version
        schedules[i] = schedules[i].copyWith(day: remainingDays);
      }
    }
  }

  // Dialog for selecting days of the week for this schedule
  // No conflict checking during selection - it's handled at save time
  void _showEditDaysDialog() {
    // Use a case-insensitive comparison when creating the initial selection set
    // This solves the issue where default schedule days don't show as selected
    final selectedDays = Set<String>();

    // Create normalized set of days (capitalized first letter) from current schedule
    for (final day in _schedule.day) {
      if (day.isNotEmpty) {
        // Convert to proper case (Monday, Tuesday, etc.)
        final properCaseDay = day[0].toUpperCase() + day.substring(1).toLowerCase();
        selectedDays.add(properCaseDay);
      }
    }

    // Log for debugging
    logDebug('Initial selected days: ${selectedDays.join(', ')}');

    showCupertinoModalPopup(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => CupertinoActionSheet(
          title: const Text('Assign Days'),
          message: const Text('Choose days for this schedule template'),
          actions: WeekDay.values.map((day) {
            // Properly format day name with first letter capitalized
            final dayName = day.name[0].toUpperCase() + day.name.substring(1).toLowerCase();

            // Check if this day is selected (case-insensitive)
            final isSelected = selectedDays.contains(dayName);

            logDebug('Day $dayName isSelected: $isSelected');

            return CupertinoActionSheetAction(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dayName),
                  if (isSelected)
                    const Icon(CupertinoIcons.checkmark, color: CupertinoColors.systemBlue),
                ],
              ),
              onPressed: () {
                if (isSelected) {
                  // Remove from selection
                  setDialogState(() {
                    selectedDays.remove(dayName);
                    logDebug('Removed $dayName, now: ${selectedDays.join(', ')}');
                  });
                } else {
                  // Add to selection with proper capitalization
                  setDialogState(() {
                    selectedDays.add(dayName);
                    logDebug('Added $dayName, now: ${selectedDays.join(', ')}');
                  });
                }
              },
            );
          }).toList()
            ..add(
              CupertinoActionSheetAction(
                isDefaultAction: true,
                child: const Text('Apply'),
                onPressed: () {
                  setState(() {
                    // Convert to consistent format when applying
                    final days = selectedDays.toList();
                    logDebug('Final selected days: ${days.join(', ')}');

                    _schedule = _schedule.copyWith(day: days);
                    _hasChanges = true;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
      ),
    );
  }

  // Add a new break time slot
  void _addBreakTime() {
    _showTimeSlotDialog(
      title: 'Break Time',
      iconColor: CupertinoColors.systemGreen,
      onSave: (startTime, endTime) {
        setState(() {
          final breakTime = TimeFrame(startTime: startTime, endTime: endTime);
          _schedule = _schedule.copyWith(
            mealBreaks: [..._schedule.mealBreaks, breakTime],
          );
          _hasChanges = true;
        });
      },
    );
  }

  // Edit an existing break time slot
  void _editBreakTime(int index) {
    final breakTime = _schedule.mealBreaks[index];

    _showTimeSlotDialog(
      title: 'Edit Break Time',
      iconColor: CupertinoColors.systemGreen,
      initialStartTime: breakTime.startTime,
      initialEndTime: breakTime.endTime,
      onSave: (startTime, endTime) {
        setState(() {
          final updatedBreakTime = TimeFrame(
            startTime: startTime,
            endTime: endTime,
          );
          final updatedBreaks = List<TimeFrame>.from(_schedule.mealBreaks);
          updatedBreaks[index] = updatedBreakTime;

          _schedule = _schedule.copyWith(mealBreaks: updatedBreaks);
          _hasChanges = true;
        });
      },
    );
  }

  // Remove a break time slot
  void _removeBreakTime(int index) {
    setState(() {
      final updatedBreaks = List<TimeFrame>.from(_schedule.mealBreaks);
      updatedBreaks.removeAt(index);

      _schedule = _schedule.copyWith(mealBreaks: updatedBreaks);
      _hasChanges = true;
    });
  }

  // Add a new meal time slot
  void _addMealTime() {
    _showTimeSlotDialog(
      title: 'Meal Time',
      iconColor: CupertinoColors.systemOrange,
      initialStartTime: const TimeOfDay(hour: 12, minute: 0),
      initialEndTime: const TimeOfDay(hour: 13, minute: 0),
      onSave: (startTime, endTime) {
        setState(() {
          final mealTime = TimeFrame(startTime: startTime, endTime: endTime);
          _schedule = _schedule.copyWith(
            freeTimes: [..._schedule.freeTimes, mealTime],
          );
          _hasChanges = true;
        });
      },
    );
  }

  // Edit an existing meal time slot
  void _editMealTime(int index) {
    final mealTime = _schedule.freeTimes[index];

    _showTimeSlotDialog(
      title: 'Edit Meal Time',
      iconColor: CupertinoColors.systemOrange,
      initialStartTime: mealTime.startTime,
      initialEndTime: mealTime.endTime,
      onSave: (startTime, endTime) {
        setState(() {
          final updatedMealTime = TimeFrame(
            startTime: startTime,
            endTime: endTime,
          );
          final updatedMeals = List<TimeFrame>.from(_schedule.freeTimes);
          updatedMeals[index] = updatedMealTime;

          _schedule = _schedule.copyWith(freeTimes: updatedMeals);
          _hasChanges = true;
        });
      },
    );
  }

  // Remove a meal time slot
  void _removeMealTime(int index) {
    setState(() {
      final updatedMeals = List<TimeFrame>.from(_schedule.freeTimes);
      updatedMeals.removeAt(index);

      _schedule = _schedule.copyWith(freeTimes: updatedMeals);
      _hasChanges = true;
    });
  }

  // Show time picker dialog
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

  // Show dialog for configuring time slots (breaks and meals)
  void _showTimeSlotDialog({
    required String title,
    required Function(TimeOfDay, TimeOfDay) onSave,
    TimeOfDay? initialStartTime,
    TimeOfDay? initialEndTime,
    Color iconColor = CupertinoColors.systemBlue,
  }) {
    var startTime = initialStartTime ?? const TimeOfDay(hour: 12, minute: 0);
    var endTime = initialEndTime ?? const TimeOfDay(hour: 13, minute: 0);

    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setDialogState) => CupertinoActionSheet(
                  title: Text(title),
                  message: Text(
                    'Set your ${title.toLowerCase()} start and end times',
                  ),
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
                      child: Text(
                        initialStartTime == null ? 'Add $title' : 'Save $title',
                      ),
                      onPressed: () {
                        onSave(startTime, endTime);
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

  // Format TimeOfDay for display
  String _formatTimeOfDay(TimeOfDay time) {
    final dateTime = DateTime(2022, 1, 1, time.hour, time.minute);
    return DateTimeFormatter.formatTime(
      dateTime,
      is24HourFormat: _is24HourFormat,
    );
  }

  // Format assigned days for display
  String _formatAssignedDays() {
    final days =
        _schedule.day
            .map((dayName) => dayName[0].toUpperCase() + dayName.substring(1))
            .toList();

    days.sort((a, b) {
      final order = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return order.indexOf(a) - order.indexOf(b);
    });

    if (days.isEmpty) {
      return 'No days assigned';
    }
    if (days.length == 7) {
      return 'All days';
    } else {
      return days.join(', ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.isNewSchedule ? 'New Schedule' : 'Edit Schedule'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () {
            if (_hasChanges) {
              showCupertinoDialog(
                context: context,
                builder:
                    (context) => CupertinoAlertDialog(
                      title: const Text('Unsaved Changes'),
                      content: const Text(
                        'You have unsaved changes. Do you want to discard them?',
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('Discard'),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                        ),
                        CupertinoDialogAction(
                          isDefaultAction: true,
                          child: const Text('Keep Editing'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Save'),
          onPressed: _saveSettings,
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: [
            // Schedule name input section
            SettingsSection(
              title: 'Schedule Name',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: CupertinoTextField(
                    controller: _nameController,
                    placeholder: 'Enter schedule name',
                    onChanged: (value) {
                      _hasChanges = true;
                    },
                    decoration: BoxDecoration(
                      color: CupertinoDynamicColor.resolve(
                        CupertinoColors.systemGrey6,
                        context,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 12.0,
                    ),
                  ),
                ),
              ],
            ),

            // Day selection section
            SettingsSection(
              title: 'Schedule Days',
              children: [
                SettingsItem(
                  label: _formatAssignedDays(),
                  leading: const Icon(
                    CupertinoIcons.calendar,
                    color: CupertinoColors.systemBlue,
                  ),
                  onTap: _showEditDaysDialog,
                ),
              ],
            ),

            // Sleep time settings
            SettingsSection(
              title: 'Sleep Schedule',
              children: [
                SettingsTimePickerItem(
                  label: 'Bedtime',
                  time: _schedule.sleepTime.startTime!,
                  onTimeSelected: (time) => _updateSleepTime(time, null),
                  leading: const Icon(
                    CupertinoIcons.moon_fill,
                    color: CupertinoColors.systemIndigo,
                  ),
                  use24HourFormat: _is24HourFormat,
                ),
                SettingsTimePickerItem(
                  label: 'Wake Up',
                  time: _schedule.sleepTime.endTime!,
                  onTimeSelected: (time) => _updateSleepTime(null, time),
                  leading: const Icon(
                    CupertinoIcons.sunrise_fill,
                    color: CupertinoColors.systemOrange,
                  ),
                  use24HourFormat: _is24HourFormat,
                ),
              ],
            ),

            // Break times section
            SettingsSection(
              title: 'Break Times',
              footerText: 'Set your break times for this schedule.',
              children: [
                ..._schedule.mealBreaks.asMap().entries.map(
                  (entry) => SettingsItem(
                    label:
                        'Break ${_formatTimeOfDay(entry.value.startTime!)} - ${_formatTimeOfDay(entry.value.endTime!)}',
                    leading: const Icon(
                      CupertinoIcons.clock,
                      color: CupertinoColors.systemGreen,
                    ),
                    onTap: () => _editBreakTime(entry.key),
                    showDisclosure: false,
                    trailing: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(
                        CupertinoIcons.delete,
                        color: CupertinoColors.systemRed,
                      ),
                      onPressed: () => _removeBreakTime(entry.key),
                    ),
                  ),
                ),
                SettingsItem(
                  label: 'Add Break Time',
                  leading: const Icon(
                    CupertinoIcons.add_circled,
                    color: CupertinoColors.systemGreen,
                  ),
                  onTap: _addBreakTime,
                ),
              ],
            ),

            // Meal times section
            SettingsSection(
              title: 'Meal Times',
              footerText: 'Set your meal times for this schedule.',
              children: [
                ..._schedule.freeTimes.asMap().entries.map(
                  (entry) => SettingsItem(
                    label:
                        'Meal ${_formatTimeOfDay(entry.value.startTime!)} - ${_formatTimeOfDay(entry.value.endTime!)}',
                    leading: const Icon(
                      CupertinoIcons.clock,
                      color: CupertinoColors.systemOrange,
                    ),
                    onTap: () => _editMealTime(entry.key),
                    showDisclosure: false,
                    trailing: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(
                        CupertinoIcons.delete,
                        color: CupertinoColors.systemRed,
                      ),
                      onPressed: () => _removeMealTime(entry.key),
                    ),
                  ),
                ),
                SettingsItem(
                  label: 'Add Meal Time',
                  leading: const Icon(
                    CupertinoIcons.add_circled,
                    color: CupertinoColors.systemOrange,
                  ),
                  onTap: _addMealTime,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
