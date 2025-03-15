import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flowo_client/models/time_frame.dart';
import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flowo_client/models/user_settings.dart';
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
    _minSessionDuration = (_minSessionDuration ?? 15).clamp(5, 120);
    _breakDuration = (_breakDuration ?? 5).clamp(5, 30);
  }

  void _loadSettings() {
    final currentSettings =
        context.read<TaskManagerCubit>().taskManager.userSettings;
    setState(() {
      _sleepTime = currentSettings.sleepTime.isNotEmpty
          ? currentSettings.sleepTime.first.startTime
          : const TimeOfDay(hour: 22, minute: 0);
      _wakeupTime = currentSettings.sleepTime.isNotEmpty
          ? currentSettings.sleepTime.first.endTime
          : const TimeOfDay(hour: 7, minute: 0);
      _breakDuration =
          (currentSettings.breakTime ?? 15 * 60 * 1000) ~/ (60 * 1000);
      _minSessionDuration = currentSettings.minSession ~/ (60 * 1000);
      _mealTimes = List.from(currentSettings.mealBreaks.isNotEmpty
          ? currentSettings.mealBreaks
          : [
              TimeFrame(
                  startTime: const TimeOfDay(hour: 8, minute: 0),
                  endTime: const TimeOfDay(hour: 8, minute: 30)),
              TimeFrame(
                  startTime: const TimeOfDay(hour: 13, minute: 0),
                  endTime: const TimeOfDay(hour: 13, minute: 30)),
              TimeFrame(
                  startTime: const TimeOfDay(hour: 19, minute: 0),
                  endTime: const TimeOfDay(hour: 19, minute: 30)),
            ]);
      _freeTimes = List.from(currentSettings.freeTime.isNotEmpty
          ? currentSettings.freeTime
          : [
              TimeFrame(
                  startTime: const TimeOfDay(hour: 17, minute: 0),
                  endTime: const TimeOfDay(hour: 18, minute: 30))
            ]);
      _activeDays = Map.from(currentSettings.activeDays ??
          {
            'Monday': true,
            'Tuesday': true,
            'Wednesday': true,
            'Thursday': true,
            'Friday': true,
            'Saturday': true,
            'Sunday': true,
          });
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
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Settings Saved'),
        content: const Text('Your schedule preferences have been updated.'),
        actions: [
          CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context))
        ],
      ),
    );
  }

  void _showTimePicker(
      {required TimeOfDay initialTime,
      required Function(TimeOfDay) onTimeSelected}) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 280,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context)),
                CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime:
                    DateTime(2022, 1, 1, initialTime.hour, initialTime.minute),
                onDateTimeChanged: (dateTime) => onTimeSelected(
                    TimeOfDay(hour: dateTime.hour, minute: dateTime.minute)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTimeSlotDialog(
      {required String title,
      required Function(TimeOfDay, TimeOfDay) onAdd,
      Color iconColor = CupertinoColors.systemBlue}) {
    var startTime = const TimeOfDay(hour: 12, minute: 0);
    var endTime = const TimeOfDay(hour: 13, minute: 0);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => CupertinoActionSheet(
          title: Text('Add $title'),
          message: Text('Set your $title start and end times'),
          actions: [
            CupertinoActionSheetAction(
              child: Text('Start Time: ${_formatTimeOfDay(startTime)}'),
              onPressed: () => _showTimePicker(
                initialTime: startTime,
                onTimeSelected: (time) =>
                    setDialogState(() => startTime = time),
              ),
            ),
            CupertinoActionSheetAction(
              child: Text('End Time: ${_formatTimeOfDay(endTime)}'),
              onPressed: () => _showTimePicker(
                initialTime: endTime,
                onTimeSelected: (time) => setDialogState(() => endTime = time),
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
              onPressed: () => Navigator.pop(context)),
        ),
      ),
    );
  }

  void _showAddMealDialog() {
    _showAddTimeSlotDialog(
      title: 'Meal Time',
      iconColor: CupertinoColors.systemOrange,
      onAdd: (startTime, endTime) => setState(() =>
          _mealTimes.add(TimeFrame(startTime: startTime, endTime: endTime))),
    );
  }

  void _showAddFreeTimeDialog() {
    _showAddTimeSlotDialog(
      title: 'Free Time',
      iconColor: CupertinoColors.systemGreen,
      onAdd: (startTime, endTime) => setState(() =>
          _freeTimes.add(TimeFrame(startTime: startTime, endTime: endTime))),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Settings')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionHeader('Theme'),
            const SizedBox(height: 8.0),
            CupertinoSegmentedControl<String>(
              groupValue: themeNotifier.currentThemeName,
              children: const {
                'Light': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('Light')),
                'Night': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('Night')),
                'ADHD': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('ADHD')),
              },
              onValueChanged: (value) => themeNotifier.setTheme(value),
            ),
            const SizedBox(height: 24.0),
            _buildSectionHeader('Sleep Schedule'),
            _buildSettingItem('Sleep Time', _formatTimeOfDay(_sleepTime),
                onTap: () => _showTimePicker(
                    initialTime: _sleepTime,
                    onTimeSelected: (time) =>
                        setState(() => _sleepTime = time))),
            _buildSettingItem('Wake Up Time', _formatTimeOfDay(_wakeupTime),
                onTap: () => _showTimePicker(
                    initialTime: _wakeupTime,
                    onTimeSelected: (time) =>
                        setState(() => _wakeupTime = time))),
            const SizedBox(height: 16.0),
            _buildSectionHeader('Active Days'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Wrap(
                spacing: 8.0,
                children: _activeDays.keys
                    .map((day) => CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 6.0),
                          color: _activeDays[day]!
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.systemGrey5,
                          borderRadius: BorderRadius.circular(16.0),
                          minSize: 0,
                          child: Text(
                            day.substring(0, 3),
                            style: TextStyle(
                                color: _activeDays[day]!
                                    ? CupertinoColors.white
                                    : CupertinoColors.label,
                                fontSize: 14.0),
                          ),
                          onPressed: () => setState(
                              () => _activeDays[day] = !_activeDays[day]!),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16.0),
            _buildSectionHeader('Meal Times'),
            ..._mealTimes
                .map((meal) => _buildTimeSlotItem(
                    meal,
                    CupertinoColors.systemOrange,
                    () => setState(() => _mealTimes.remove(meal))))
                ,
            CupertinoButton(
              onPressed: _showAddMealDialog,
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.add_circled),
                    SizedBox(width: 8.0),
                    Text('Add Meal Time')
                  ]),
            ),
            const SizedBox(height: 16.0),
            _buildSectionHeader('Free Time'),
            ..._freeTimes
                .map((freeTime) => _buildTimeSlotItem(
                    freeTime,
                    CupertinoColors.systemGreen,
                    () => setState(() => _freeTimes.remove(freeTime))))
                ,
            CupertinoButton(
              onPressed: _showAddFreeTimeDialog,
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.add_circled),
                    SizedBox(width: 8.0),
                    Text('Add Free Time')
                  ]),
            ),
            const SizedBox(height: 16.0),
            _buildSectionHeader('Work Settings'),
            _buildSliderItem('Minimum Session (minutes)',
                _minSessionDuration.toDouble().clamp(5.0, 120.0),
                min: 5,
                max: 120,
                divisions: 23,
                onChanged: (value) =>
                    setState(() => _minSessionDuration = value.round())),
            _buildSliderItem('Break Duration (minutes)',
                _breakDuration.toDouble().clamp(5.0, 30.0),
                min: 5,
                max: 30,
                divisions: 5,
                onChanged: (value) =>
                    setState(() => _breakDuration = value.round())),
            const SizedBox(height: 24.0),
            CupertinoButton.filled(
                onPressed: _saveSettings,
                child: const Text('Save Settings')),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)));

  Widget _buildSettingItem(String label, String value,
          {required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: CupertinoColors.systemGrey5, width: 0.5))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 16)),
              Row(
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 16, color: CupertinoColors.systemGrey)),
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.chevron_right,
                      color: CupertinoColors.systemGrey2, size: 18),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildTimeSlotItem(
          TimeFrame timeFrame, Color iconColor, VoidCallback onDelete) =>
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: CupertinoColors.systemGrey5, width: 0.5))),
        child: Row(
          children: [
            Icon(CupertinoIcons.time, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
                child: Text(
                    '${_formatTimeOfDay(timeFrame.startTime)} - ${_formatTimeOfDay(timeFrame.endTime)}',
                    style: const TextStyle(fontSize: 16))),
            CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onDelete,
                child: const Icon(CupertinoIcons.delete,
                    color: CupertinoColors.systemRed)),
          ],
        ),
      );

  Widget _buildSliderItem(String label, double value,
          {required double min,
          required double max,
          required int divisions,
          required Function(double) onChanged}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(label, style: const TextStyle(fontSize: 16)),
              Text('${value.round()}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8.0),
            CupertinoSlider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged),
          ],
        ),
      );
}
