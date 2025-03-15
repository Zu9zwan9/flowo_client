import 'package:flowo_client/screens/event_edit_screen.dart';
import 'package:flowo_client/screens/task_edit_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/tasks_controller/task_manager_cubit.dart';
import '../models/task.dart';
import '../utils/category_utils.dart';
import '../utils/logger.dart';

class TaskPageScreen extends StatefulWidget {
  final Task task;
  final bool isEditing;

  const TaskPageScreen({
    required this.task,
    this.isEditing = false,
    super.key,
  });

  @override
  _TaskPageScreenState createState() => _TaskPageScreenState();
}

class _TaskPageScreenState extends State<TaskPageScreen> {
  late Task _task;
  bool _isLoading = false;
  bool _hasBreakdown = false;
  List<Task> _subtasks = [];
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _notesController.text = _task.notes ?? '';
    _loadExistingSubtasks();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _loadExistingSubtasks() {
    setState(() {
      _subtasks = _task.subtasks;
      _hasBreakdown = _subtasks.isNotEmpty;
    });
  }

  Future<void> _generateTaskBreakdown() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the TaskManagerCubit to break down the task using AI
      final generatedSubtasks = await context
          .read<TaskManagerCubit>()
          .breakdownAndScheduleTask(_task);

      setState(() {
        _subtasks = generatedSubtasks;
        _hasBreakdown = true;
        _isLoading = false;
      });

      // No need to save subtasks separately as they're already saved by the TaskManager
      logInfo(
          'Generated ${generatedSubtasks.length} subtasks for ${_task.title}');
    } catch (e) {
      logError('Error generating task breakdown: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to generate task breakdown');
    }
  }

  void _showDeadlinePicker(BuildContext context, StateSetter setState,
      int currentDeadline, Function(int) onDeadlineChanged) {
    DateTime? pickedDate;
    final now = DateTime.now();
    final currentDateTime =
        DateTime.fromMillisecondsSinceEpoch(currentDeadline);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime:
                    currentDateTime.isBefore(now) ? now : currentDateTime,
                minimumDate: now,
                maximumDate:
                    DateTime.fromMillisecondsSinceEpoch(_task.deadline),
                onDateTimeChanged: (val) => pickedDate = val,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CupertinoButton(
                  child: const Text('Cancel',
                      style: TextStyle(color: CupertinoColors.systemGrey)),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: const Text('Done',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: () {
                    if (pickedDate != null) {
                      onDeadlineChanged(pickedDate!.millisecondsSinceEpoch);
                    }
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleSubtasks() {
    if (_subtasks.isEmpty) {
      // If no subtasks exist, schedule the parent task
      setState(() {
        _isLoading = true;
      });

      try {
        // Schedule the parent task
        context.read<TaskManagerCubit>().scheduleTask(_task);

        setState(() {
          _isLoading = false;
        });

        // Show a dialog informing the user that the task has been scheduled
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Task Scheduled'),
            content: const Text(
                'The task has been scheduled in the calendar since there are no subtasks.'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('View in Calendar'),
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to the home screen (which typically has the calendar view)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              )
            ],
          ),
        );
      } catch (e) {
        logError('Error scheduling task: $e');
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Failed to schedule task');
      }
      return;
    }

    // Show a dialog informing the user that subtasks are already scheduled
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Tasks Already Scheduled'),
        content: const Text(
            'Subtasks are automatically scheduled when they are added. You can view them in the calendar.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('View in Calendar'),
            onPressed: () {
              Navigator.pop(context);
              // Navigate to the home screen (which typically has the calendar view)
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          )
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  void _navigateToEditScreen(BuildContext context) {
    // Check if the task is an event (priority 0)
    final isEvent = _task.priority == 0 && _task.category.name == 'Event';

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => isEvent
            ? EventEditScreen(event: _task)
            : TaskEditScreen(task: _task),
      ),
    ).then((_) {
      // Refresh the task data when returning from the edit screen
      setState(() {
        _task = widget.task;
        _notesController.text = _task.notes ?? '';
        _loadExistingSubtasks();
      });
    });
  }

  void _deleteSubtask(Task subtask) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Subtask'),
        content: Text('Are you sure you want to delete "${subtask.title}"?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              final tasksCubit = context.read<TaskManagerCubit>();
              tasksCubit.deleteTask(subtask);
              setState(() {
                _subtasks.remove(subtask);
                _task.subtasks.remove(subtask);
              });
              _task.save();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<int> _showEstimatedTimePicker(BuildContext context) async {
    int? pickedHours;
    int? pickedMinutes;
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 32,
                      onSelectedItemChanged: (index) {
                        pickedHours = index;
                      },
                      children: [
                        for (var i = 0; i <= 120; i++) Text('$i hours'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 32,
                      onSelectedItemChanged: (index) {
                        pickedMinutes = index * 15;
                      },
                      children: [
                        for (var i = 0; i < 4; i++) Text('${i * 15} minutes'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CupertinoButton(
                  child: const Text('Cancel',
                      style: TextStyle(color: CupertinoColors.systemGrey)),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: const Text('Done',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: () {
                    Navigator.pop(
                        context,
                        (pickedHours ?? 0) * 3600000 +
                            (pickedMinutes ?? 0) * 60000);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return (pickedHours ?? 0) * 3600000 + (pickedMinutes ?? 0) * 60000;
  }

  void _showAddSubtaskDialog() {
    final TextEditingController titleController = TextEditingController();
    int selectedEstimatedTime = 0; // Default to 0 milliseconds
    int selectedPriority = 1;
    int selectedDeadline = _task.deadline; // Default to parent task's deadline

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        'Add Subtask',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Add'),
                        onPressed: () {
                          if (_validateSubtaskForm(
                            titleController.text,
                            selectedEstimatedTime,
                            selectedDeadline,
                          )) {
                            _addSubtask(
                              titleController.text,
                              selectedEstimatedTime,
                              selectedPriority,
                              selectedDeadline,
                            );
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Title',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: titleController,
                    placeholder: 'Enter subtask title',
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.systemGrey4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Estimated Time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final estimatedTime =
                          await _showEstimatedTimePicker(context);
                      setState(() => selectedEstimatedTime = estimatedTime);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Time',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: CupertinoColors.systemBlue)),
                          Text(
                              '${(selectedEstimatedTime ~/ 3600000).toString().padLeft(2, '0')}h ${((selectedEstimatedTime % 3600000) ~/ 60000).toString().padLeft(2, '0')}m',
                              style: const TextStyle(
                                  fontSize: 16, color: CupertinoColors.label)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Priority ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        selectedPriority.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlider(
                      min: 1,
                      max: 10,
                      divisions: 9,
                      value: selectedPriority.toDouble(),
                      onChanged: (value) =>
                          setState(() => selectedPriority = value.toInt()),
                      activeColor: CupertinoColors.systemOrange,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Deadline',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showDeadlinePicker(
                        context, setState, selectedDeadline, (newDeadline) {
                      setState(() {
                        selectedDeadline = newDeadline;
                      });
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Date',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: CupertinoColors.systemBlue)),
                          Text(
                            DateTime.fromMillisecondsSinceEpoch(
                                    selectedDeadline)
                                .toLocal()
                                .toString()
                                .split(' ')[0],
                            style: const TextStyle(
                                fontSize: 16, color: CupertinoColors.label),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Category: ${_task.category.name} (inherited from parent task)',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          CategoryUtils.getCategoryColor(_task.category.name),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      // Clean up controllers
      titleController.dispose();
    });
  }

  bool _validateSubtaskForm(String title, int estimatedTimeMs, int deadline) {
    if (title.isEmpty) {
      _showErrorDialog('Please enter a title for the subtask');
      return false;
    }

    if (estimatedTimeMs <= 0) {
      _showErrorDialog('Please select an estimated time greater than 0');
      return false;
    }

    if (estimatedTimeMs > _task.estimatedTime) {
      _showErrorDialog(
          'Subtask estimated time cannot exceed parent task estimated time (${_formatDuration(_task.estimatedTime)})');
      return false;
    }

    if (deadline > _task.deadline) {
      _showErrorDialog(
          'Subtask deadline cannot be later than parent task deadline');
      return false;
    }

    return true;
  }

  void _addSubtask(
      String title, int estimatedTime, int priority, int deadline) {
    // Generate a unique ID for the subtask
    final String subtaskId = DateTime.now().millisecondsSinceEpoch.toString();

    // Create the subtask with the parent task's category
    final Task subtask = Task(
      id: subtaskId,
      title: title,
      priority: priority,
      deadline: deadline,
      estimatedTime: estimatedTime,
      category: _task.category, // Inherit category from parent
      parentTask: _task, // Set parent task reference
    );

    // Add the subtask to the parent task
    setState(() {
      // _subtasks.add(subtask);
      _task.subtasks.add(subtask);
      _hasBreakdown = true;
    });

    // Save the parent task to persist the changes
    _task.save();

    // Schedule the subtask
    context.read<TaskManagerCubit>().scheduleTask(subtask);
  }

  Widget _buildSubtaskItem(Task subtask) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey5.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        CategoryUtils.getCategoryColor(subtask.category.name),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtask.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(CupertinoIcons.time,
                              size: 12, color: CupertinoColors.systemGrey),
                          const SizedBox(width: 4),
                          Text(
                            'Est. time: ${_formatDuration(subtask.estimatedTime)}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.systemGrey),
                          ),
                          const SizedBox(width: 12),
                          const Icon(CupertinoIcons.flag,
                              size: 12, color: CupertinoColors.systemGrey),
                          const SizedBox(width: 4),
                          Text(
                            'Priority: ${subtask.priority}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.systemGrey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.delete, size: 20),
                  onPressed: () => _deleteSubtask(subtask),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 4.0),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.calendar,
                      size: 12, color: CupertinoColors.systemGrey),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${DateTime.fromMillisecondsSinceEpoch(subtask.deadline).toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(
                        fontSize: 12, color: CupertinoColors.systemGrey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    final hours = milliseconds ~/ 3600000;
    final minutes = (milliseconds % 3600000) ~/ 60000;
    return hours > 0
        ? '$hours hr ${minutes > 0 ? '$minutes min' : ''}'
        : minutes > 0
            ? '$minutes min'
            : '< 1 min';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_task.title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.pencil),
              onPressed: () => _navigateToEditScreen(context),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.delete,
                  color: CupertinoColors.destructiveRed),
              onPressed: () {
                final subtaskCount = _task.subtasks.length;
                final message = subtaskCount > 0
                    ? 'Are you sure you want to delete "${_task.title}" and its $subtaskCount subtask${subtaskCount == 1 ? "" : "s"}?'
                    : 'Are you sure you want to delete "${_task.title}"?';

                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('Delete Task'),
                    content: Text(message),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: () {
                          final tasksCubit = context.read<TaskManagerCubit>();
                          tasksCubit.deleteTask(_task);
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Return to previous screen
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildTaskHeader(),
                const SizedBox(height: 24),
                _buildTaskDescription(),
                const SizedBox(height: 24),
                _buildMagicButton(),
                const SizedBox(height: 24),
                _buildSubtasksList(),
                const SizedBox(height: 24),
                _buildScheduleButton(),
                const SizedBox(height: 32),
              ],
            ),
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskHeader() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemGrey5.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            CategoryUtils.getCategoryColor(_task.category.name)
                                .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _task.category.name,
                        style: TextStyle(
                            color: CategoryUtils.getCategoryColor(
                                _task.category.name),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    Text('Priority: ${_task.priority}',
                        style:
                            const TextStyle(color: CupertinoColors.systemGrey)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(CupertinoIcons.time,
                        size: 14, color: CupertinoColors.systemGrey),
                    const SizedBox(width: 4),
                    Text('Est. time: ${_formatDuration(_task.estimatedTime)}',
                        style:
                            const TextStyle(color: CupertinoColors.systemGrey)),
                    const Spacer(),
                    const Icon(CupertinoIcons.calendar,
                        size: 14, color: CupertinoColors.systemGrey),
                    const SizedBox(width: 4),
                    Text(
                      DateTime.fromMillisecondsSinceEpoch(_task.deadline)
                          .toLocal()
                          .toString()
                          .split(' ')[0],
                      style: const TextStyle(color: CupertinoColors.systemGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _estimateTimeWithAI(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(CupertinoIcons.wand_stars,
                                  color: CupertinoColors.systemGreen, size: 16),
                              SizedBox(width: 4),
                              Text('Estimate with AI',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: CupertinoColors.systemGreen,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _rescheduleTask(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color:
                                CupertinoColors.systemOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(CupertinoIcons.calendar_badge_plus,
                                  color: CupertinoColors.systemOrange,
                                  size: 16),
                              SizedBox(width: 4),
                              Text('Reschedule',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: CupertinoColors.systemOrange,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildTaskDescription() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: CupertinoColors.systemGrey5.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Task Description',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _notesController,
              placeholder: 'Add notes about this task...',
              minLines: 3,
              maxLines: 5,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey5),
                  borderRadius: BorderRadius.circular(8)),
              onChanged: (value) {
                _task.notes = value.isEmpty ? null : value;
                _task.save();
              },
            ),
          ],
        ),
      );

  Widget _buildMagicButton() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemIndigo.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: CupertinoColors.systemIndigo.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.sparkles,
                size: 40, color: CupertinoColors.systemIndigo),
            const SizedBox(height: 12),
            const Text('Task Breakdown Options',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.systemIndigo)),
            const SizedBox(height: 8),
            const Text(
                'You can either let AI analyze this task and break it down into manageable subtasks, or add subtasks manually using the "Add Subtask" button in the subtasks section below.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: CupertinoColors.systemGrey, fontSize: 14)),
            const SizedBox(height: 16),
            CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                onPressed: _generateTaskBreakdown,
                child: const Text('Generate Subtasks with AI')),
          ],
        ),
      );

  Widget _buildSubtasksList() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: CupertinoColors.systemGrey5.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(CupertinoIcons.list_bullet,
                    size: 20, color: CupertinoColors.activeBlue),
                const SizedBox(width: 8),
                const Text('Subtasks',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_subtasks.isNotEmpty)
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: _estimateSubtaskTimes,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.wand_stars,
                            size: 16, color: CupertinoColors.systemGreen),
                        SizedBox(width: 4),
                        Text('Estimate Subtasks',
                            style:
                                TextStyle(color: CupertinoColors.systemGreen)),
                      ],
                    ),
                  ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onPressed: _showAddSubtaskDialog,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.add, size: 16),
                      SizedBox(width: 4),
                      Text('Add Subtask'),
                    ],
                  ),
                ),
                Text('${_subtasks.length}',
                    style: const TextStyle(
                        color: CupertinoColors.systemGrey, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ..._subtasks.map(_buildSubtaskItem),
          ],
        ),
      );

  Widget _buildScheduleButton() => CupertinoButton.filled(
        onPressed: _scheduleSubtasks,
        child: const Text('Schedule Task'),
      );

  Widget _buildLoadingOverlay() => Container(
        color: CupertinoColors.systemBackground.withOpacity(0.7),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(radius: 20),
              const SizedBox(height: 16),
              Text(
                  _hasBreakdown
                      ? 'Scheduling tasks...'
                      : 'Breaking down task...',
                  style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );

  Future<void> _estimateTimeWithAI([BuildContext? ctx]) async {
    // Use the provided context or the current context
    final context = ctx ?? this.context;

    // Show loading indicator
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CupertinoAlertDialog(
        title: Text('Estimating Time'),
        content: Padding(
          padding: EdgeInsets.only(top: 16.0),
          child: Center(
            child: CupertinoActivityIndicator(),
          ),
        ),
      ),
    );

    try {
      // Call the TaskManagerCubit to estimate time for the task
      final estimatedTime =
          await context.read<TaskManagerCubit>().estimateTaskTime(_task);

      // Close the loading dialog
      Navigator.pop(context);

      if (mounted) {
        setState(() {
          _task.estimatedTime = estimatedTime;
          _task.save();
        });

        // Show success dialog
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Time Estimated'),
            content: Text(
                'The AI estimates this task will take ${(_task.estimatedTime ~/ 3600000).toString().padLeft(2, '0')}h ${((_task.estimatedTime % 3600000) ~/ 60000).toString().padLeft(2, '0')}m to complete.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Reschedule Now'),
                onPressed: () {
                  Navigator.pop(context);
                  _rescheduleTask(context);
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close the loading dialog
      Navigator.pop(context);

      // Show error dialog
      _showErrorDialog('Failed to estimate time: $e');
    }
  }

  Future<void> _rescheduleTask([BuildContext? ctx]) async {
    // Use the provided context or the current context
    final context = ctx ?? this.context;

    // Show loading indicator
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CupertinoAlertDialog(
        title: Text('Rescheduling Task'),
        content: Padding(
          padding: EdgeInsets.only(top: 16.0),
          child: Center(
            child: CupertinoActivityIndicator(),
          ),
        ),
      ),
    );

    try {
      // Remove previous scheduled tasks
      context.read<TaskManagerCubit>().removeScheduledTasks();

      // Schedule the task
      context.read<TaskManagerCubit>().scheduleTask(_task);

      // Close the loading dialog
      Navigator.pop(context);

      // Show success dialog
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Task Rescheduled'),
          content: const Text(
              'The task has been rescheduled with the new estimated time.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('View in Calendar'),
              onPressed: () {
                Navigator.pop(context);
                // Navigate to the home screen (which typically has the calendar view)
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      );
    } catch (e) {
      // Close the loading dialog
      Navigator.pop(context);

      // Show error dialog
      _showErrorDialog('Failed to reschedule task: $e');
    }
  }

  Future<void> _estimateSubtaskTimes() async {
    if (_subtasks.isEmpty) {
      _showErrorDialog('No subtasks to estimate');
      return;
    }

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a list to track which subtasks were updated
      final updatedSubtasks = <Task>[];

      // For each subtask, estimate its time
      for (final subtask in _subtasks) {
        final estimatedTime =
            await context.read<TaskManagerCubit>().estimateTaskTime(subtask);

        // Update the subtask with the new estimated time
        subtask.estimatedTime = estimatedTime;
        subtask.save();

        updatedSubtasks.add(subtask);
      }

      // Refresh the UI
      setState(() {
        _isLoading = false;
      });

      // Show success dialog
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Subtasks Estimated'),
          content: Text(
              'Estimated time for ${updatedSubtasks.length} subtasks. Would you like to reschedule them now?'),
          actions: [
            CupertinoDialogAction(
              child: const Text('No'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Yes, Reschedule'),
              onPressed: () {
                Navigator.pop(context);
                _rescheduleSubtasks();
              },
            ),
          ],
        ),
      );
    } catch (e) {
      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });

      // Show error dialog
      _showErrorDialog('Failed to estimate subtask times: $e');
    }
  }

  Future<void> _rescheduleSubtasks() async {
    if (_subtasks.isEmpty) {
      _showErrorDialog('No subtasks to reschedule');
      return;
    }

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Remove previous scheduled tasks
      context.read<TaskManagerCubit>().removeScheduledTasks();

      // Schedule each subtask
      for (final subtask in _subtasks) {
        context.read<TaskManagerCubit>().scheduleTask(subtask);
      }

      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });

      // Show success dialog
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Subtasks Rescheduled'),
          content: const Text(
              'All subtasks have been rescheduled with their new estimated times.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('View in Calendar'),
              onPressed: () {
                Navigator.pop(context);
                // Navigate to the home screen (which typically has the calendar view)
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      );
    } catch (e) {
      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });

      // Show error dialog
      _showErrorDialog('Failed to reschedule subtasks: $e');
    }
  }
}
