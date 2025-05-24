import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/tasks_controller/task_manager_cubit.dart';
import '../../../models/task.dart';
import '../../event/event_screen.dart';
import '../../task/task_page_screen.dart' as task_page;

class AddSubtaskDialog {
  static void show(
    BuildContext context,
    Task parentTask,
    Function(String, int, int, int, int, int?, int?) onAdd,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => _AddSubtaskDialogWidget(parentTask: parentTask, onAdd: onAdd),
    );
  }
}

class _AddSubtaskDialogWidget extends StatefulWidget {
  final Task parentTask;
  final Function(String, int, int, int, int, int?, int?) onAdd;

  const _AddSubtaskDialogWidget({
    required this.parentTask,
    required this.onAdd,
  });

  @override
  _AddSubtaskDialogWidgetState createState() => _AddSubtaskDialogWidgetState();
}

class _AddSubtaskDialogWidgetState extends State<_AddSubtaskDialogWidget> {
  late TextEditingController titleController;
  late int estimatedTime;
  late int priority;
  late int deadline;
  late int order;
  late int? firstNotification;
  late int? secondNotification;
  late List<Task> sortedSubtasks;
  late List<int> orderOptions;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    estimatedTime = 3600000; // Default 1 hour in milliseconds
    priority = 1;
    deadline = widget.parentTask.deadline;
    firstNotification = 5;
    secondNotification = 0;

    // Get existing subtasks to show order options
    final existingSubtasks = context
        .read<TaskManagerCubit>()
        .getSubtasksForTask(widget.parentTask);
    sortedSubtasks = List<Task>.from(existingSubtasks)
      ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    if (sortedSubtasks.isNotEmpty) {
      final lastOrder = sortedSubtasks.last.order ?? 0;
      order = lastOrder + 1;
    } else {
      order = 1;
    }

    orderOptions = <int>[];
    orderOptions.add(0); // Insert at the beginning
    for (int i = 0; i < sortedSubtasks.length; i++) {
      final currentOrder = sortedSubtasks[i].order ?? i;
      orderOptions.add(currentOrder + 1);
    }
    if (!orderOptions.contains(order)) {
      orderOptions.add(order);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  String _getOrderLabel(int order, List<Task> sortedSubtasks) {
    if (sortedSubtasks.isEmpty || order == 0) {
      return 'First position';
    } else if (order > (sortedSubtasks.last.order ?? 0)) {
      return 'Last position';
    } else {
      final beforeTask = sortedSubtasks.lastWhere(
        (t) => (t.order ?? 0) < order,
        orElse: () => sortedSubtasks.first,
      );
      final beforeTitle = beforeTask.title.substring(
        0,
        min(20, beforeTask.title.length),
      );
      return 'After "$beforeTitle${beforeTask.title.length > 20 ? '...' : ''}"';
    }
  }

  String _formatNotificationTime(int? minutes) {
    if (minutes == null) {
      return 'None';
    }
    switch (minutes) {
      case 0:
        return 'At event time';
      case 1:
        return '1 minute before';
      case 5:
        return '5 minutes before';
      case 15:
        return '15 minutes before';
      case 30:
        return '30 minutes before';
      case 60:
        return '1 hour before';
      case 120:
        return '2 hours before';
      case 1440:
        return '1 day before';
      case 2880:
        return '2 days before';
      case 10080:
        return '1 week before';
      default:
        if (minutes < 60) {
          return '$minutes minutes before';
        } else if (minutes < 1440) {
          final hours = minutes ~/ 60;
          final mins = minutes % 60;
          if (mins == 0) {
            return '$hours hours before';
          } else {
            return '$hours hours $mins minutes before';
          }
        } else {
          final days = minutes ~/ 1440;
          return '$days days before';
        }
    }
  }

  Future<void> _showNotificationTimePicker(
    BuildContext context,
    bool isFirstNotification,
    int? currentValue,
    Function(int?) onChanged,
  ) async {
    final List<int?> timeOptions = [
      null,
      0,
      5,
      15,
      30,
      60,
      120,
      1440,
      2880,
      10080,
    ];

    final int initialIndex =
        timeOptions.contains(currentValue)
            ? timeOptions.indexOf(currentValue)
            : 0;

    await showCupertinoModalPopup<void>(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            color: CupertinoTheme.of(context).scaffoldBackgroundColor,
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
                  child: CupertinoPicker(
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(
                      initialItem: initialIndex,
                    ),
                    onSelectedItemChanged: (index) {
                      onChanged(timeOptions[index]);
                    },
                    children:
                        timeOptions
                            .map((time) => Text(_formatNotificationTime(time)))
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
    final theme = CupertinoTheme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(TaskPageConstants.padding),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: CupertinoColors.activeBlue.resolveFrom(context),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Text('Add Subtask', style: theme.textTheme.navTitleTextStyle),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text(
                    'Add',
                    style: TextStyle(
                      color: CupertinoColors.activeBlue.resolveFrom(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      showCupertinoDialog(
                        context: context,
                        builder:
                            (context) => CupertinoAlertDialog(
                              title: const Text('Error'),
                              content: const Text('Title cannot be empty'),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('OK'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                      );
                      return;
                    }

                    // First close the dialog
                    Navigator.pop(context);

                    // Then add the subtask with the specified order
                    widget.onAdd(
                      titleController.text.trim(),
                      estimatedTime,
                      priority,
                      deadline,
                      order,
                      firstNotification,
                      secondNotification,
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Title',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        CupertinoTextField(
                          controller: titleController,
                          placeholder: 'Enter subtask title',
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemFill.resolveFrom(
                              context,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          style: TextStyle(
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Estimated time field
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estimated Time',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            showCupertinoModalPopup(
                              context: context,
                              builder: (BuildContext context) {
                                return Container(
                                  height: 216,
                                  padding: const EdgeInsets.only(top: 6.0),
                                  margin: EdgeInsets.only(
                                    bottom:
                                        MediaQuery.of(
                                          context,
                                        ).viewInsets.bottom,
                                  ),
                                  color: CupertinoColors.systemBackground
                                      .resolveFrom(context),
                                  child: SafeArea(
                                    top: false,
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            CupertinoButton(
                                              child: const Text('Cancel'),
                                              onPressed:
                                                  () =>
                                                      Navigator.of(
                                                        context,
                                                      ).pop(),
                                            ),
                                            CupertinoButton(
                                              child: const Text('Done'),
                                              onPressed:
                                                  () =>
                                                      Navigator.of(
                                                        context,
                                                      ).pop(),
                                            ),
                                          ],
                                        ),
                                        Expanded(
                                          child: CupertinoPicker(
                                            magnification: 1.22,
                                            squeeze: 1.2,
                                            useMagnifier: true,
                                            itemExtent: 32,
                                            scrollController:
                                                FixedExtentScrollController(
                                                  initialItem: (estimatedTime ~/
                                                          900000)
                                                      .clamp(0, 23),
                                                ),
                                            onSelectedItemChanged: (
                                              int selectedItem,
                                            ) {
                                              setState(() {
                                                estimatedTime =
                                                    selectedItem *
                                                    15 *
                                                    60 *
                                                    1000;
                                              });
                                            },
                                            children: List<
                                              Widget
                                            >.generate(24, (int index) {
                                              final hours = index ~/ 4;
                                              final minutes = (index % 4) * 15;
                                              return Center(
                                                child: Text(
                                                  '${hours > 0 ? '$hours hr ' : ''}${minutes > 0
                                                      ? '$minutes min'
                                                      : hours > 0
                                                      ? ''
                                                      : '0 min'}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemFill.resolveFrom(
                                context,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  task_page.DurationFormatter.format(
                                    estimatedTime,
                                  ),
                                  style: TextStyle(
                                    color: CupertinoColors.label.resolveFrom(
                                      context,
                                    ),
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.time,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Priority field
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Priority',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemFill.resolveFrom(
                              context,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: CupertinoSlider(
                                  value: priority.toDouble(),
                                  min: 1,
                                  max: 10,
                                  divisions: 9,
                                  onChanged: (value) {
                                    setState(() {
                                      priority = value.round();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                priority.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: CupertinoColors.label.resolveFrom(
                                    context,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Order field
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtask Order',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.label.resolveFrom(
                                  context,
                                ),
                              ),
                            ),
                            Text(
                              sortedSubtasks.isEmpty
                                  ? 'No existing subtasks'
                                  : '${sortedSubtasks.length} existing subtask${sortedSubtasks.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose where to place this subtask in the list',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            showCupertinoModalPopup(
                              context: context,
                              builder: (BuildContext context) {
                                return Container(
                                  height: 300,
                                  padding: const EdgeInsets.only(top: 6.0),
                                  margin: EdgeInsets.only(
                                    bottom:
                                        MediaQuery.of(
                                          context,
                                        ).viewInsets.bottom,
                                  ),
                                  color: CupertinoColors.systemBackground
                                      .resolveFrom(context),
                                  child: SafeArea(
                                    top: false,
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            CupertinoButton(
                                              child: const Text('Cancel'),
                                              onPressed:
                                                  () =>
                                                      Navigator.of(
                                                        context,
                                                      ).pop(),
                                            ),
                                            Text(
                                              'Select Position',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            CupertinoButton(
                                              child: const Text('Done'),
                                              onPressed:
                                                  () =>
                                                      Navigator.of(
                                                        context,
                                                      ).pop(),
                                            ),
                                          ],
                                        ),
                                        Expanded(
                                          child: CupertinoPicker(
                                            magnification: 1.17,
                                            squeeze: 1.45,
                                            useMagnifier: true,
                                            itemExtent: 44,
                                            scrollController:
                                                FixedExtentScrollController(
                                                  initialItem: orderOptions
                                                      .indexOf(order),
                                                ),
                                            onSelectedItemChanged: (index) {
                                              setState(() {
                                                order = orderOptions[index];
                                              });
                                            },
                                            children:
                                                orderOptions.map((o) {
                                                  String label;
                                                  IconData icon;
                                                  Color iconColor;

                                                  if (o == 0 ||
                                                      (sortedSubtasks.isEmpty &&
                                                          o == 1)) {
                                                    label = 'First position';
                                                    icon =
                                                        CupertinoIcons
                                                            .arrow_up_to_line;
                                                    iconColor = CupertinoColors
                                                        .systemBlue
                                                        .resolveFrom(context);
                                                  } else if (o == order &&
                                                      sortedSubtasks
                                                          .isNotEmpty) {
                                                    label = 'Last position';
                                                    icon =
                                                        CupertinoIcons
                                                            .arrow_down_to_line;
                                                    iconColor = CupertinoColors
                                                        .systemIndigo
                                                        .resolveFrom(context);
                                                  } else {
                                                    final beforeTask =
                                                        sortedSubtasks.lastWhere(
                                                          (t) =>
                                                              (t.order ?? 0) <
                                                              o,
                                                          orElse:
                                                              () =>
                                                                  sortedSubtasks
                                                                      .first,
                                                        );
                                                    final beforeTitle =
                                                        beforeTask.title
                                                            .substring(
                                                              0,
                                                              min(
                                                                45,
                                                                beforeTask
                                                                    .title
                                                                    .length,
                                                              ),
                                                            );
                                                    label =
                                                        'After "$beforeTitle${beforeTask.title.length > 45 ? '...' : ''}"';
                                                    icon =
                                                        CupertinoIcons
                                                            .arrow_right;
                                                    iconColor = CupertinoColors
                                                        .systemGreen
                                                        .resolveFrom(context);
                                                  }

                                                  return Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          icon,
                                                          color: iconColor,
                                                          size: 20,
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            label,
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              color: CupertinoColors
                                                                  .label
                                                                  .resolveFrom(
                                                                    context,
                                                                  ),
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemFill.resolveFrom(
                                context,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: CupertinoColors.activeBlue
                                    .resolveFrom(context)
                                    .withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getOrderLabel(order, sortedSubtasks),
                                  style: TextStyle(
                                    color: CupertinoColors.label.resolveFrom(
                                      context,
                                    ),
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.list_number,
                                  color: CupertinoColors.activeBlue.resolveFrom(
                                    context,
                                  ),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Deadline field
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Deadline',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.label.resolveFrom(
                                  context,
                                ),
                              ),
                            ),
                            CupertinoSwitch(
                              value: deadline != widget.parentTask.deadline,
                              onChanged: (value) {
                                setState(() {
                                  if (value) {
                                    final parentDate =
                                        DateTime.fromMillisecondsSinceEpoch(
                                          widget.parentTask.deadline,
                                        );
                                    final oneDayBefore = parentDate.subtract(
                                      const Duration(days: 1),
                                    );
                                    deadline =
                                        oneDayBefore.millisecondsSinceEpoch;
                                  } else {
                                    deadline = widget.parentTask.deadline;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deadline == widget.parentTask.deadline
                              ? 'Using parent task deadline'
                              : 'Custom deadline (before parent\'s)',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap:
                              deadline != widget.parentTask.deadline
                                  ? () {
                                    showCupertinoModalPopup(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Container(
                                          height: 216,
                                          padding: const EdgeInsets.only(
                                            top: 6.0,
                                          ),
                                          margin: EdgeInsets.only(
                                            bottom:
                                                MediaQuery.of(
                                                  context,
                                                ).viewInsets.bottom,
                                          ),
                                          color: CupertinoColors
                                              .systemBackground
                                              .resolveFrom(context),
                                          child: SafeArea(
                                            top: false,
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    CupertinoButton(
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                      onPressed:
                                                          () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(),
                                                    ),
                                                    CupertinoButton(
                                                      child: const Text('Done'),
                                                      onPressed:
                                                          () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(),
                                                    ),
                                                  ],
                                                ),
                                                Expanded(
                                                  child: CupertinoDatePicker(
                                                    mode:
                                                        CupertinoDatePickerMode
                                                            .date,
                                                    initialDateTime:
                                                        DateTime.fromMillisecondsSinceEpoch(
                                                          deadline,
                                                        ),
                                                    minimumDate: DateTime(
                                                      DateTime.now().year,
                                                      DateTime.now().month,
                                                      DateTime.now().day,
                                                    ),
                                                    maximumDate:
                                                        DateTime.fromMillisecondsSinceEpoch(
                                                          widget
                                                              .parentTask
                                                              .deadline,
                                                        ),
                                                    onDateTimeChanged: (
                                                      DateTime newDate,
                                                    ) {
                                                      setState(() {
                                                        deadline =
                                                            newDate
                                                                .millisecondsSinceEpoch;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                  : null,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemFill.resolveFrom(
                                context,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  deadline != widget.parentTask.deadline
                                      ? Border.all(
                                        color: CupertinoColors.activeBlue
                                            .resolveFrom(context)
                                            .withOpacity(0.3),
                                        width: 1,
                                      )
                                      : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    deadline,
                                  ).toLocal().toString().split(' ')[0],
                                  style: TextStyle(
                                    color:
                                        deadline != widget.parentTask.deadline
                                            ? CupertinoColors.label.resolveFrom(
                                              context,
                                            )
                                            : CupertinoColors.secondaryLabel
                                                .resolveFrom(context),
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.calendar,
                                  color:
                                      deadline != widget.parentTask.deadline
                                          ? CupertinoColors.activeBlue
                                              .resolveFrom(context)
                                          : CupertinoColors.secondaryLabel
                                              .resolveFrom(context),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notification Settings
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification Settings',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            _showNotificationTimePicker(
                              context,
                              true,
                              firstNotification,
                              (value) =>
                                  setState(() => firstNotification = value),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemFill.resolveFrom(
                                context,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: CupertinoColors.activeBlue
                                    .resolveFrom(context)
                                    .withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Alert: ${_formatNotificationTime(firstNotification)}',
                                  style: TextStyle(
                                    color: CupertinoColors.label.resolveFrom(
                                      context,
                                    ),
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.time,
                                  color: CupertinoColors.activeBlue.resolveFrom(
                                    context,
                                  ),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            _showNotificationTimePicker(
                              context,
                              false,
                              secondNotification,
                              (value) =>
                                  setState(() => secondNotification = value),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemFill.resolveFrom(
                                context,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: CupertinoColors.activeBlue
                                    .resolveFrom(context)
                                    .withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Second Alert: ${_formatNotificationTime(secondNotification)}',
                                  style: TextStyle(
                                    color: CupertinoColors.label.resolveFrom(
                                      context,
                                    ),
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.time,
                                  color: CupertinoColors.activeBlue.resolveFrom(
                                    context,
                                  ),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
