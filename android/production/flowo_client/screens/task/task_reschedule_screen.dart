import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/models/task.dart';
import '../../models/scheduled_task.dart';
import 'package:intl/intl.dart';

/// Screen for rescheduling tasks to make room for a specific task
class TaskRescheduleScreen extends StatefulWidget {
  final Task targetTask;
  final Duration timeNeeded;

  const TaskRescheduleScreen({
    super.key,
    required this.targetTask,
    required this.timeNeeded,
  });

  @override
  State<TaskRescheduleScreen> createState() => _TaskRescheduleScreenState();
}

class _TaskRescheduleScreenState extends State<TaskRescheduleScreen> {
  final List<TaskWithSchedules> _reschedulableTasks = [];
  Duration _selectedDuration = Duration.zero;
  bool _isLoading = true;

  // Store pending changes: {scheduledTaskId: updated ScheduledTask}
  final Map<String, ScheduledTask> _pendingTaskUpdates = {};

  // Store pending deletions: {scheduledTaskId}
  final Set<String> _pendingTaskDeletions = {};

  @override
  void initState() {
    super.initState();
    _loadReschedulableTasks();
  }

  Future<void> _loadReschedulableTasks() async {
    final tasksCubit = context.read<TaskManagerCubit>();
    final deadline = widget.targetTask.deadline;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime.fromMillisecondsSinceEpoch(
      widget.targetTask.deadline,
    );
    final deadlineDay = DateTime(
      deadlineDate.year,
      deadlineDate.month,
      deadlineDate.day,
    );

    List<DateTime> dates = List.generate(
      deadlineDay.difference(today).inDays + 1,
      (index) => today.add(Duration(days: index)),
    );

    logInfo('Loading reschedulable tasks for dates: $dates');

    for (var date in dates) {
      _reschedulableTasks.addAll(
        await tasksCubit.getScheduledTasksForDate(date),
      );
    }

    setState(() {
      _isLoading = false;
      logInfo('Tasks loaded: ${_reschedulableTasks.length}');
    });
  }

  void _updatePendingTaskSchedule(ScheduledTask updatedTask) {
    setState(() {
      _pendingTaskUpdates[updatedTask.scheduledTaskId] = updatedTask;
      _updateSelectedDuration();
    });
  }

  void _resetPendingTask(String scheduledTaskId) {
    setState(() {
      _pendingTaskUpdates.remove(scheduledTaskId);
      _updateSelectedDuration();
    });
  }

  void _togglePendingDeletion(String scheduledTaskId) {
    setState(() {
      if (_pendingTaskDeletions.contains(scheduledTaskId)) {
        _pendingTaskDeletions.remove(scheduledTaskId);
      } else {
        _pendingTaskDeletions.add(scheduledTaskId);
        _pendingTaskUpdates.remove(
          scheduledTaskId,
        ); // Clear any pending updates
      }
      _updateSelectedDuration();
    });
  }

  void _updateSelectedDuration() {
    Duration newDuration = Duration.zero;

    // Add duration of deleted tasks
    for (var scheduledTaskId in _pendingTaskDeletions) {
      for (var taskWithSchedules in _reschedulableTasks) {
        for (var task in taskWithSchedules.scheduledTasks) {
          if (task.scheduledTaskId == scheduledTaskId) {
            newDuration += task.endTime.difference(task.startTime);
            break;
          }
        }
      }
    }

    // Add net duration change from modified tasks
    for (var updatedTask in _pendingTaskUpdates.values) {
      if (!_pendingTaskDeletions.contains(updatedTask.scheduledTaskId)) {
        // Find original task
        Duration originalDuration = Duration.zero;
        for (var taskWithSchedules in _reschedulableTasks) {
          for (var task in taskWithSchedules.scheduledTasks) {
            if (task.scheduledTaskId == updatedTask.scheduledTaskId) {
              originalDuration = task.endTime.difference(task.startTime);
              break;
            }
          }
        }
        final newDurationDelta =
            originalDuration -
            updatedTask.endTime.difference(updatedTask.startTime);
        newDuration +=
            newDurationDelta; // Positive if time freed, negative if consumed
      }
    }

    _selectedDuration =
        newDuration > Duration.zero ? newDuration : Duration.zero;
  }

  bool _canReschedule() {
    return _selectedDuration >= widget.timeNeeded;
  }

  void _applyChanges() {
    final tasksCubit = context.read<TaskManagerCubit>();

    // Apply deletions
    for (var scheduledTaskId in _pendingTaskDeletions) {
      for (var taskWithSchedules in _reschedulableTasks) {
        for (var task in taskWithSchedules.scheduledTasks) {
          if (task.scheduledTaskId == scheduledTaskId) {
            tasksCubit.deleteScheduledTask(task);
            break;
          }
        }
      }
    }

    // Apply updates
    for (var updatedTask in _pendingTaskUpdates.values) {
      tasksCubit.updateScheduledTask(updatedTask);
    }

    // Clear pending changes
    setState(() {
      _pendingTaskUpdates.clear();
      _pendingTaskDeletions.clear();
      _reschedulableTasks.clear();
      _selectedDuration = Duration.zero;
      _isLoading = true;
    });
    _loadReschedulableTasks();

    // Show confirmation
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Changes Applied'),
            content: const Text('Selected tasks have been updated or deleted.'),
            actions: [
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to previous screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Reschedule Tasks for ${widget.targetTask.title}'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildInfoCard(),
            Expanded(child: _buildTaskList()),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    // Calculate durations for modified and deleted tasks
    Duration modifiedDuration = Duration.zero;
    Duration deletedDuration = Duration.zero;

    for (var updatedTask in _pendingTaskUpdates.values) {
      if (!_pendingTaskDeletions.contains(updatedTask.scheduledTaskId)) {
        // Find original task
        Duration originalDuration = Duration.zero;
        for (var taskWithSchedules in _reschedulableTasks) {
          for (var task in taskWithSchedules.scheduledTasks) {
            if (task.scheduledTaskId == updatedTask.scheduledTaskId) {
              originalDuration = task.endTime.difference(task.startTime);
              break;
            }
          }
        }
        final newDurationDelta =
            originalDuration -
            updatedTask.endTime.difference(updatedTask.startTime);
        modifiedDuration += newDurationDelta;
      }
    }

    for (var scheduledTaskId in _pendingTaskDeletions) {
      for (var taskWithSchedules in _reschedulableTasks) {
        for (var task in taskWithSchedules.scheduledTasks) {
          if (task.scheduledTaskId == scheduledTaskId) {
            deletedDuration += task.endTime.difference(task.startTime);
            break;
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).barBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? CupertinoColors.black.withOpacity(0.1)
                    : CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Information',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'You need ${widget.timeNeeded.inHours}h ${widget.timeNeeded.inMinutes.remainder(60)}m more time to complete this task.',
            style: CupertinoTheme.of(context).textTheme.textStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Freed: ${_selectedDuration.inHours}h ${_selectedDuration.inMinutes.remainder(60)}m of ${widget.timeNeeded.inHours}h ${widget.timeNeeded.inMinutes.remainder(60)}m needed',
            style: TextStyle(
              color:
                  _canReschedule()
                      ? CupertinoColors.activeGreen.resolveFrom(context)
                      : CupertinoTheme.of(context).textTheme.textStyle.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (modifiedDuration != Duration.zero)
            Text(
              ' • Modified tasks: ${modifiedDuration.inHours >= 0 ? '+' : '-'}${modifiedDuration.inHours.abs()}h ${modifiedDuration.inMinutes.remainder(60).abs()}m',
              style: TextStyle(
                color: CupertinoColors.systemYellow,
                fontSize: 14,
              ),
            ),
          if (deletedDuration > Duration.zero)
            Text(
              ' • Deleted tasks: +${deletedDuration.inHours}h ${deletedDuration.inMinutes.remainder(60)}m',
              style: TextStyle(
                color: CupertinoColors.destructiveRed,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    // Flatten and sort tasks
    List<MapEntry<ScheduledTask, Task>> taskList = [];
    for (var taskWithSchedules in _reschedulableTasks) {
      for (var scheduledTask in taskWithSchedules.scheduledTasks) {
        taskList.add(MapEntry(scheduledTask, taskWithSchedules.task));
      }
    }
    taskList.sort((a, b) => a.key.startTime.compareTo(b.key.startTime));

    if (taskList.isEmpty) {
      logWarning('No tasks available for rescheduling');
      return Center(
        child: Text(
          'No tasks available for rescheduling',
          style: CupertinoTheme.of(context).textTheme.textStyle,
        ),
      );
    }

    // Group tasks by date
    final dateGroups = <DateTime, List<MapEntry<ScheduledTask, Task>>>{};
    for (var taskEntry in taskList) {
      final date = DateTime(
        taskEntry.key.startTime.year,
        taskEntry.key.startTime.month,
        taskEntry.key.startTime.day,
      );
      dateGroups.putIfAbsent(date, () => []).add(taskEntry);
    }

    // Create a flat list of items (headers + tasks)
    final itemList = <dynamic>[];
    dateGroups.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))
      ..forEach((entry) {
        itemList.add(entry.key); // Date header
        itemList.addAll(entry.value); // Tasks for that date
      });

    return ListView.builder(
      itemCount: itemList.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final item = itemList[index];
        if (item is DateTime) {
          // Render date header
          return _buildDateHeader(item);
        } else if (item is MapEntry<ScheduledTask, Task>) {
          final scheduledTask = item.key;
          final parentTask = item.value;
          return _ScheduledTaskSelectionItem(
            scheduledTask: scheduledTask,
            parentTask: parentTask,
            onTaskUpdated: _updatePendingTaskSchedule,
            onTaskDeleted:
                () => _togglePendingDeletion(scheduledTask.scheduledTaskId),
            onTaskReset: () => _resetPendingTask(scheduledTask.scheduledTaskId),
            pendingTask:
                _pendingTaskUpdates[scheduledTask.scheduledTaskId] ??
                scheduledTask,
            isPendingDeletion: _pendingTaskDeletions.contains(
              scheduledTask.scheduledTaskId,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateFormat = DateFormat('dd/MM/yyyy');
    String displayText;

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      displayText = 'Today';
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      displayText = 'Tomorrow';
    } else {
      displayText = dateFormat.format(date);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayText,
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle
                .copyWith(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 1, color: CupertinoColors.separator),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: CupertinoButton.filled(
        onPressed:
            (_pendingTaskUpdates.isNotEmpty ||
                        _pendingTaskDeletions.isNotEmpty) &&
                    _canReschedule()
                ? _applyChanges
                : null,
        child: const Text('Apply Changes'),
      ),
    );
  }
}

class _ScheduledTaskSelectionItem extends StatelessWidget {
  final ScheduledTask scheduledTask;
  final Task parentTask;
  final Function(ScheduledTask) onTaskUpdated;
  final VoidCallback onTaskDeleted;
  final VoidCallback onTaskReset;
  final ScheduledTask pendingTask;
  final bool isPendingDeletion;

  const _ScheduledTaskSelectionItem({
    required this.scheduledTask,
    required this.parentTask,
    required this.onTaskUpdated,
    required this.onTaskDeleted,
    required this.onTaskReset,
    required this.pendingTask,
    required this.isPendingDeletion,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;
    final secondaryColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    TimeOfDay toTimeOfDay(DateTime dateTime) {
      return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    }

    void onStartTimeSelected(TimeOfDay newTime) {
      final newStartTime = DateTime(
        pendingTask.startTime.year,
        pendingTask.startTime.month,
        pendingTask.startTime.day,
        newTime.hour,
        newTime.minute,
      );
      if (newStartTime.isBefore(pendingTask.endTime)) {
        final updatedTask = ScheduledTask(
          scheduledTaskId: pendingTask.scheduledTaskId,
          startTime: newStartTime,
          endTime: pendingTask.endTime,
          parentTaskId: pendingTask.parentTaskId,
          type: pendingTask.type,
          travelingTime: pendingTask.travelingTime,
        );
        onTaskUpdated(updatedTask);
      } else {
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Invalid Time'),
                content: const Text('Start time must be before end time.'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
        );
      }
    }

    void onEndTimeSelected(TimeOfDay newTime) {
      final newEndTime = DateTime(
        pendingTask.endTime.year,
        pendingTask.endTime.month,
        pendingTask.endTime.day,
        newTime.hour,
        newTime.minute,
      );
      if (newEndTime.isAfter(pendingTask.startTime)) {
        final updatedTask = ScheduledTask(
          scheduledTaskId: pendingTask.scheduledTaskId,
          startTime: pendingTask.startTime,
          endTime: newEndTime,
          parentTaskId: pendingTask.parentTaskId,
          type: pendingTask.type,
          travelingTime: pendingTask.travelingTime
        );
        onTaskUpdated(updatedTask);
      } else {
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Invalid Time'),
                content: const Text('End time must be after start time.'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
        );
      }
    }

    String formatDate(DateTime date) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final dateFormat = DateFormat('dd/MM/yyyy');

      if (date.year == today.year &&
          date.month == today.month &&
          date.day == today.day) {
        return 'Today';
      } else if (date.year == tomorrow.year &&
          date.month == tomorrow.month &&
          date.day == tomorrow.day) {
        return 'Tomorrow';
      } else {
        return dateFormat.format(date);
      }
    }

    // Determine background color based on task status
    Color backgroundColor;
    if (isPendingDeletion) {
      backgroundColor = CupertinoColors.destructiveRed.withOpacity(0.2);
    } else if (pendingTask != scheduledTask) {
      backgroundColor = CupertinoColors.systemYellow.withOpacity(0.2);
    } else {
      backgroundColor = CupertinoTheme.of(context).barBackgroundColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  parentTask.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              if (pendingTask !=
                  scheduledTask) // Show reset button for modified tasks
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onTaskReset,
                  child: const Icon(
                    CupertinoIcons.arrow_counterclockwise,
                    color: CupertinoColors.activeBlue,
                    size: 20,
                  ),
                ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onTaskDeleted,
                child: Icon(
                  isPendingDeletion
                      ? CupertinoIcons.trash_fill
                      : CupertinoIcons.trash,
                  color: CupertinoColors.destructiveRed,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Date: ${formatDate(pendingTask.startTime)}',
            style: TextStyle(fontSize: 14, color: secondaryColor),
          ),
          const SizedBox(height: 4),
          SettingsTimePickerItem(
            label: 'Start Time',
            time: toTimeOfDay(pendingTask.startTime),
            onTimeSelected: onStartTimeSelected,
            use24HourFormat: true,
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            enabled: !isPendingDeletion,
          ),
          SettingsTimePickerItem(
            label: 'End Time',
            time: toTimeOfDay(pendingTask.endTime),
            onTimeSelected: onEndTimeSelected,
            use24HourFormat: true,
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            enabled: !isPendingDeletion,
          ),
        ],
      ),
    );
  }
}

class SettingsTimePickerItem extends StatefulWidget {
  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onTimeSelected;
  final bool showDivider;
  final String? subtitle;
  final bool enabled;
  final Color? textColor;
  final TextStyle? labelStyle;
  final TextStyle? timeStyle;
  final TextStyle? subtitleStyle;
  final String? semanticsLabel;
  final EdgeInsetsGeometry padding;
  final Widget? leading;
  final String? timeFormat;
  final bool use24HourFormat;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final int minuteInterval;

  const SettingsTimePickerItem({
    super.key,
    required this.label,
    required this.time,
    required this.onTimeSelected,
    this.showDivider = true,
    this.subtitle,
    this.enabled = true,
    this.textColor,
    this.labelStyle,
    this.timeStyle,
    this.subtitleStyle,
    this.semanticsLabel,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    this.leading,
    this.timeFormat,
    this.use24HourFormat = true,
    this.minimumDate,
    this.maximumDate,
    this.minuteInterval = 1,
  });

  @override
  State<SettingsTimePickerItem> createState() => _SettingsTimePickerItemState();
}

class _SettingsTimePickerItemState extends State<SettingsTimePickerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    if (widget.timeFormat != null) {
      String formatted = widget.timeFormat!;
      final hour =
          widget.use24HourFormat
              ? time.hour.toString().padLeft(2, '0')
              : (time.hour > 12
                      ? (time.hour - 12)
                      : (time.hour == 0 ? 12 : time.hour))
                  .toString();
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour < 12 ? 'AM' : 'PM';
      formatted = formatted.replaceAll('HH', hour);
      formatted = formatted.replaceAll('mm', minute);
      formatted = formatted.replaceAll('a', period);
      return formatted;
    }

    final hour =
        widget.use24HourFormat
            ? time.hour.toString().padLeft(2, '0')
            : (time.hour > 12
                    ? (time.hour - 12)
                    : (time.hour == 0 ? 12 : time.hour))
                .toString();
    final minute = time.minute.toString().padLeft(2, '0');
    final period =
        !widget.use24HourFormat ? (time.hour < 12 ? ' AM' : ' PM') : '';
    return '$hour:$minute$period';
  }

  void _showTimePicker(BuildContext context) {
    if (!widget.enabled) return;

    setState(() => _isSelecting = true);
    _animationController.forward();

    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => Container(
            height: 280,
            color: CupertinoDynamicColor.resolve(
              CupertinoColors.systemBackground,
              context,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() => _isSelecting = false);
                        _animationController.reverse();
                      },
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() => _isSelecting = false);
                        _animationController.reverse();
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                      widget.time.hour,
                      widget.time.minute,
                    ),
                    minimumDate: widget.minimumDate,
                    maximumDate: widget.maximumDate,
                    minuteInterval: widget.minuteInterval,
                    use24hFormat: widget.use24HourFormat,
                    onDateTimeChanged:
                        (dateTime) => widget.onTimeSelected(
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
    ).then((_) {
      if (_isSelecting) {
        setState(() => _isSelecting = false);
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;
    final effectiveTimeStyle =
        widget.timeStyle ??
        TextStyle(
          color: widget.textColor ?? CupertinoColors.systemGrey,
          fontSize: 16,
        );

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label:
          widget.semanticsLabel ??
          '${widget.label}, current time: ${_formatTimeOfDay(widget.time)}',
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: GestureDetector(
          onTap: () => _showTimePicker(context),
          child: Container(
            padding: widget.padding,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style:
                        widget.labelStyle ??
                        TextStyle(
                          fontSize: 16,
                          color: widget.textColor ?? textColor,
                        ),
                  ),
                ),
                Text(_formatTimeOfDay(widget.time), style: effectiveTimeStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
