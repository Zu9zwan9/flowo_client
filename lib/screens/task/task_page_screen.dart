import 'dart:async';

import 'package:flutter/cupertino.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/tasks_controller/task_manager_cubit.dart';
import '../../models/task.dart';

import '../../utils/logger.dart';
import 'task_form_screen.dart';
import '../widgets/task_page/task_header.dart';

import '../widgets/task_page/task_description.dart';
import '../widgets/task_page/magic_button.dart';
import '../widgets/task_page/subtasks_list.dart';
import '../widgets/task_page/loading_overlay.dart';
import '../widgets/task_page/sessions_widget.dart';
import '../widgets/task_page/add_subtask_dialog.dart';

class TaskPageConstants {
  static const double padding = 16.0;
  static const double cornerRadius = 12.0;
  static const double shadowBlurRadius = 4.0;
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );
}

// Utility for formatting durations
class DurationFormatter {
  static String format(int milliseconds) {
    final hours = milliseconds ~/ 3600000;
    final minutes = (milliseconds % 3600000) ~/ 60000;
    return hours > 0
        ? '$hours hr ${minutes > 0 ? '$minutes min' : ''}'
        : minutes > 0
        ? '$minutes min'
        : '< 1 min';
  }
}

// Main Screen
class TaskPageScreen extends StatefulWidget {
  final Task task;
  final bool isEditing;

  const TaskPageScreen({required this.task, this.isEditing = false, super.key});

  @override
  State<TaskPageScreen> createState() => _TaskPageScreenState();
}

class _TaskPageScreenState extends State<TaskPageScreen> {
  late Task _task;
  late final TextEditingController _notesController;
  late final TaskManagerCubit _taskManagerCubit;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _taskManagerCubit = context.read<TaskManagerCubit>();
    _task = widget.task;
    _notesController = TextEditingController(text: _task.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _toggleTaskCompletion(TaskManagerCubit cubit) {
    cubit.toggleTaskCompletion(_task).then((isCompleted) {
      setState(() {
        _task.isDone = isCompleted;
      });
      _showAutoDismissDialog(
        context,
        message:
            _task.isDone
                ? 'Task "${_task.title}" completed'
                : 'Task "${_task.title}" incomplete',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_task.title, style: theme.textTheme.navTitleTextStyle),
        trailing: SizedBox(
          width: 90,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: const Icon(CupertinoIcons.pencil, size: 20),
                onPressed: () => _navigateToEditScreen(context),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: const Icon(
                  CupertinoIcons.delete,
                  size: 20,
                  color: CupertinoColors.destructiveRed,
                ),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(TaskPageConstants.padding),
              children: [
                TaskHeader(
                  task: _task,
                  onToggle:
                      () => _toggleTaskCompletion(
                        context.read<TaskManagerCubit>(),
                      ),
                ),
                const SizedBox(height: 24),
                TaskDescription(task: _task, controller: _notesController),
                const SizedBox(height: 24),
                if (_task.subtaskIds.isEmpty)
                  SessionsWidget(
                    task: _task,
                    taskManagerCubit: _taskManagerCubit,
                  ),
                const SizedBox(height: 24),
                MagicButton(onGenerate: _generateTaskBreakdown),
                const SizedBox(height: 24),
                SubtasksList(
                  subtasks: _taskManagerCubit.getSubtasksForTask(_task),
                  parentTask: _task,
                  onAdd: _showAddSubtaskDialog,
                  onDelete: _deleteSubtask,
                ),
                const SizedBox(height: 32),
              ],
            ),
            if (_isLoading) const LoadingOverlay(),
          ],
        ),
      ),
    );
  }

  void _navigateToEditScreen(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => TaskFormScreen(task: _task)),
    ).then((_) {
      setState(() {
        _task = widget.task;
        _notesController.text = _task.notes ?? '';
      });
    });
  }

  void _confirmDelete(BuildContext context) {
    final subtaskCount = _task.subtaskIds.length;
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Delete Task'),
            content: Text(
              subtaskCount > 0
                  ? 'Delete "${_task.title}" and its $subtaskCount subtask${subtaskCount == 1 ? "" : "s"}?'
                  : 'Delete "${_task.title}"?',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  context.read<TaskManagerCubit>().deleteTask(_task);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _generateTaskBreakdown() async {
    setState(() => _isLoading = true);
    try {
      final subtasksCopy = List<Task>.from(
        _taskManagerCubit.getSubtasksForTask(_task),
      );
      for (var task in subtasksCopy) {
        context.read<TaskManagerCubit>().deleteTask(task);
      }

      final subtasks = await context
          .read<TaskManagerCubit>()
          .generateSubtasksFor(_task);

      setState(() {
        _isLoading = false;
        _task = _taskManagerCubit.getTaskById(_task.id) ?? _task;
      });
      logInfo('Generated ${subtasks.length} subtasks for ${_task.title}');
    } catch (e) {
      logError('Error generating breakdown: $e');
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to generate breakdown');
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(message),
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

  void _showAutoDismissDialog(BuildContext context, {required String message}) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => CupertinoAlertDialog(content: Text(message)),
    );
  }

  void _deleteSubtask(Task subtask) {
    showCupertinoDialog(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: const Text('Delete Subtask'),
            content: Text('Delete "${subtask.title}"?'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);

                  context.read<TaskManagerCubit>().deleteTask(subtask);

                  final remainingSubtasks = _taskManagerCubit
                      .getSubtasksForTask(_task);
                  for (int i = 0; i < remainingSubtasks.length; i++) {
                    remainingSubtasks[i].order = i + 1;
                    remainingSubtasks[i].save();
                  }

                  // Update the task manager
                  _taskManagerCubit.updateTaskOrder(_task, remainingSubtasks);
                  setState(() {
                    _task = _taskManagerCubit.getTaskById(_task.id) ?? _task;
                  });
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showAddSubtaskDialog() =>
      AddSubtaskDialog.show(context, _task, _addSubtask);

  void _addSubtask(
    String title,
    int estimatedTime,
    int priority,
    int deadline,
    int order,
    int? firstNotification,
    int? secondNotification,
    bool updateParentTime,
  ) {
    final existingSubtasks = List<Task>.from(
      _taskManagerCubit.getSubtasksForTask(_task),
    );

    _taskManagerCubit.createTask(
      title: title,
      priority: priority,
      estimatedTime: estimatedTime,
      deadline: deadline,
      category: _task.category,
      parentTask: _task,
      order: order,
      color: _task.color,
      firstNotification: firstNotification,
      secondNotification: secondNotification,
    );

    final allSubtasks = _taskManagerCubit.getSubtasksForTask(_task);

    Task? newTask;
    for (final task in allSubtasks) {
      if (!existingSubtasks.any((t) => t.id == task.id)) {
        newTask = task;
        break;
      }
    }

    if (newTask != null) {
      allSubtasks.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
      allSubtasks.removeWhere((task) => task.id == newTask!.id);

      int targetIndex = 0;
      for (; targetIndex < allSubtasks.length; targetIndex++) {
        if ((allSubtasks[targetIndex].order ?? 0) >= order) {
          break;
        }
      }
      allSubtasks.insert(targetIndex, newTask);

      for (int i = 0; i < allSubtasks.length; i++) {
        final task = allSubtasks[i];
        task.order = i + 1;
        task.save();
      }

      _taskManagerCubit.updateTaskOrder(_task, allSubtasks);
    }

    // Update parent task's estimated time if needed
    if (updateParentTime) {
      // Calculate total estimated time of all subtasks
      int totalSubtasksTime = 0;
      for (final subtask in allSubtasks) {
        totalSubtasksTime += subtask.estimatedTime;
      }

      // Update the task in the database
      _taskManagerCubit.editTask(task: _task, estimatedTime: totalSubtasksTime);
    }

    setState(() {
      _task = _taskManagerCubit.getTaskById(_task.id) ?? _task;
    });
  }
}
