import 'package:flutter/cupertino.dart';

import '../../models/pomodoro_settings.dart';

class PomodoroSettingsScreen extends StatefulWidget {
  final PomodoroSettings settings;

  const PomodoroSettingsScreen({super.key, required this.settings});

  @override
  State<PomodoroSettingsScreen> createState() => _PomodoroSettingsScreenState();
}

class _PomodoroSettingsScreenState extends State<PomodoroSettingsScreen> {
  late PomodoroSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Pomodoro Settings'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 20),

            // Focus duration
            _buildSettingSection(
              title: 'Focus Duration',
              child: _buildDurationPicker(
                value: PomodoroSettings.millisecondsToMinutes(
                  _settings.focusDuration,
                ),
                onChanged: (value) {
                  setState(() {
                    _settings.focusDuration =
                        PomodoroSettings.minutesToMilliseconds(value);
                  });
                },
                min: 1,
                max: 60,
              ),
            ),

            // Short break duration
            _buildSettingSection(
              title: 'Short Break Duration',
              child: _buildDurationPicker(
                value: PomodoroSettings.millisecondsToMinutes(
                  _settings.shortBreakDuration,
                ),
                onChanged: (value) {
                  setState(() {
                    _settings.shortBreakDuration =
                        PomodoroSettings.minutesToMilliseconds(value);
                  });
                },
                min: 1,
                max: 30,
              ),
            ),

            // Long break duration
            _buildSettingSection(
              title: 'Long Break Duration',
              child: _buildDurationPicker(
                value: PomodoroSettings.millisecondsToMinutes(
                  _settings.longBreakDuration,
                ),
                onChanged: (value) {
                  setState(() {
                    _settings.longBreakDuration =
                        PomodoroSettings.minutesToMilliseconds(value);
                  });
                },
                min: 5,
                max: 60,
              ),
            ),

            // Sessions before long break
            _buildSettingSection(
              title: 'Sessions Before Long Break',
              child: _buildNumberPicker(
                value: _settings.sessionsBeforeLongBreak,
                onChanged: (value) {
                  setState(() {
                    _settings.sessionsBeforeLongBreak = value;
                  });
                },
                min: 1,
                max: 10,
              ),
            ),

            // Auto-start breaks
            _buildSettingSection(
              title: 'Auto-start Breaks',
              child: CupertinoSwitch(
                value: _settings.autoStartBreaks,
                onChanged: (value) {
                  setState(() {
                    _settings.autoStartBreaks = value;
                  });
                },
              ),
            ),

            // Auto-start next session
            _buildSettingSection(
              title: 'Auto-start Next Session',
              child: CupertinoSwitch(
                value: _settings.autoStartNextSession,
                onChanged: (value) {
                  setState(() {
                    _settings.autoStartNextSession = value;
                  });
                },
              ),
            ),

            // Sound enabled
            _buildSettingSection(
              title: 'Sound Notifications',
              child: CupertinoSwitch(
                value: _settings.soundEnabled,
                onChanged: (value) {
                  setState(() {
                    _settings.soundEnabled = value;
                  });
                },
              ),
            ),

            // Vibration enabled
            _buildSettingSection(
              title: 'Vibration',
              child: CupertinoSwitch(
                value: _settings.vibrationEnabled,
                onChanged: (value) {
                  setState(() {
                    _settings.vibrationEnabled = value;
                  });
                },
              ),
            ),

            // Notifications enabled
            _buildSettingSection(
              title: 'Show Notifications',
              child: CupertinoSwitch(
                value: _settings.notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _settings.notificationsEnabled = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            // Reset to defaults button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CupertinoButton(
                color: CupertinoColors.systemRed,
                onPressed: () {
                  _showResetConfirmation();
                },
                child: const Text('Reset to Defaults'),
              ),
            ),

            const SizedBox(height: 20),

            // Apply button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CupertinoButton(
                color: CupertinoTheme.of(context).primaryColor,
                onPressed: () {
                  // Save settings safely
                  try {
                    // Try to save if the object is in a box
                    if (_settings.isInBox) {
                      _settings.save();
                    }
                  } catch (e) {
                    // Ignore the error if the object is not in a box
                    // The settings will still be applied in memory
                  }
                  // Update UI
                  setState(() {});
                  // Return to previous screen
                  Navigator.pop(context);
                },
                child: const Text(
                  'Apply',
                  style: TextStyle(color: CupertinoColors.white),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8.0),
          child,
        ],
      ),
    );
  }

  Widget _buildDurationPicker({
    required int value,
    required ValueChanged<int> onChanged,
    required int min,
    required int max,
  }) {
    return Row(
      children: [
        Text(
          '$value min',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 150,
          child: CupertinoSlider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (value) => onChanged(value.round()),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberPicker({
    required int value,
    required ValueChanged<int> onChanged,
    required int min,
    required int max,
  }) {
    return Row(
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 150,
          child: CupertinoSlider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (value) => onChanged(value.round()),
          ),
        ),
      ],
    );
  }

  void _showResetConfirmation() {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Reset Settings?'),
            content: const Text(
              'This will reset all settings to their default values. This action cannot be undone.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Reset'),
                onPressed: () {
                  _settings.resetToDefaults();
                  Navigator.pop(context);
                  setState(() {});
                },
              ),
            ],
          ),
    );
  }
}
