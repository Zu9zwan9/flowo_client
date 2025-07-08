 import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../blocs/tasks_controller/task_manager_cubit.dart';
import '../../models/day_schedule.dart';
import 'day_schedule_screen.dart';

class ScheduleTemplatesSection extends StatefulWidget {
  const ScheduleTemplatesSection({super.key});

  @override
  State<ScheduleTemplatesSection> createState() =>
      _ScheduleTemplatesSectionState();
}

class _ScheduleTemplatesSectionState extends State<ScheduleTemplatesSection> {
  @override
  Widget build(BuildContext context) {
    final taskManager = context.watch<TaskManagerCubit>().taskManager;
    final schedules = taskManager.userSettings.schedules;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Schedule Templates',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.add, size: 16),
                    SizedBox(width: 4),
                    Text('New'),
                  ],
                ),
                onPressed: () async {
                  if (schedules.length >= 7) {
                    _showMaxTemplatesAlert();
                    return;
                  }

                  final result = await Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder:
                          (context) =>
                              const DayScheduleScreen(isNewSchedule: true),
                    ),
                  );

                  // Force rebuild if we got a result
                  if (result != null && mounted) {
                    setState(() {});
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (schedules.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'No schedule templates yet.\nAdd one to get started!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final schedule = schedules[index];
                return _buildScheduleCard(schedule);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(DaySchedule schedule) {
    final is24Hour =
        context
            .read<TaskManagerCubit>()
            .taskManager
            .userSettings
            .is24HourFormat;

    String formatTime(TimeOfDay time) {
      final hour =
          is24Hour
              ? time.hour.toString().padLeft(2, '0')
              : (time.hour > 12
                      ? time.hour - 12
                      : (time.hour == 0 ? 12 : time.hour))
                  .toString();
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? 'PM' : 'AM';

      return is24Hour ? '$hour:$minute' : '$hour:$minute $period';
    }

    final timeText =
        '${formatTime(schedule.sleepTime.startTime!)} - ${formatTime(schedule.sleepTime.endTime!)}';

    // Format days display
    final days =
        schedule.day
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

    String daysText;
    if (days.length == 7) {
      daysText = 'All days';
    } else if (days.isEmpty) {
      daysText = 'No days assigned';
    } else if (days.length <= 2) {
      daysText = days.join(', ');
    } else {
      daysText = '${days[0]}, ${days[1]}, +${days.length - 2}';
    }

    return Container(
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.systemBackground,
          context,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey5.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          // Delete button
          Positioned(
            top: -8,
            right: -8,
            child: CupertinoButton(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                CupertinoIcons.xmark_circle_fill,
                color: CupertinoColors.systemRed,
                size: 22,
              ),
              onPressed: () => _showDeleteConfirmation(schedule),
            ),
          ),

          // Main content
          GestureDetector(
            onTap: () async {
              final result = await Navigator.of(context).push(
                CupertinoPageRoute(
                  builder:
                      (context) => DayScheduleScreen(initialSchedule: schedule),
                ),
              );

              // Force rebuild if we got a result
              if (result != null && mounted) {
                setState(() {});
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show the schedule name
                Text(
                  schedule.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: 4),
                // Show the days
                Text(
                  daysText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.moon_stars_fill,
                      size: 14,
                      color: CupertinoColors.systemIndigo,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        timeText,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    _buildCountBadge(
                      schedule.mealBreaks.length,
                      CupertinoColors.systemGreen,
                      CupertinoIcons.clock,
                    ),
                    const SizedBox(width: 8),
                    _buildCountBadge(
                      schedule.freeTimes.length,
                      CupertinoColors.systemOrange,
                      CupertinoIcons.clock_fill,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(DaySchedule schedule) {
    // Format days for display
    final days =
        schedule.day
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

    String daysText;
    if (days.length == 7) {
      daysText = 'all days';
    } else if (days.isEmpty) {
      daysText = 'no days';
    } else if (days.length <= 3) {
      daysText = days.join(', ');
    } else {
      daysText = '${days.length} days';
    }

    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: const Text('Delete Schedule'),
            content: Text(
              'Are you sure you want to delete this schedule for $daysText? ',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(dialogContext),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Delete'),
                onPressed: () async {
                  final taskManagerCubit = context.read<TaskManagerCubit>();
                  final userSettings =
                      taskManagerCubit.taskManager.userSettings;

                  // Remove this schedule from the list
                  final updatedSchedules =
                      userSettings.schedules
                          .where((s) => s != schedule)
                          .toList();

                  // Update settings
                  final updatedSettings = userSettings.copyWith(
                    schedules: updatedSchedules,
                  );

                  // Save changes
                  taskManagerCubit.updateUserSettings(updatedSettings);

                  Navigator.pop(dialogContext);

                  // Force rebuild
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
            ],
          ),
    );
  }

  void _showMaxTemplatesAlert() {
    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: const Text('Maximum Templates Reached'),
            content: const Text(
              'You can create up to 7 schedule templates. Please delete an existing template to create a new one.',
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
  }
}
