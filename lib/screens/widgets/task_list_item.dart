import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../../blocs/tasks_controller/task_manager_cubit.dart';
import '../../models/task.dart';
import '../../utils/logger.dart';

/// A widget that displays the parent task information
class _ParentTaskIndicator extends StatelessWidget {
  final Task parentTask;

  const _ParentTaskIndicator({required this.parentTask});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          CupertinoIcons.arrow_turn_up_right,
          size: 12,
          color: CupertinoColors.systemGrey,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'From: ${parentTask.title}',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class TaskListItem extends StatefulWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color categoryColor;
  final bool hasSubtasks;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final VoidCallback? onToggleCompletion;
  final TaskManagerCubit taskManagerCubit;
  final Task? parentTask;
  final bool showParentTask;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.categoryColor,
    required this.taskManagerCubit,
    this.hasSubtasks = false,
    this.isExpanded = false,
    this.onToggleExpand,
    this.onToggleCompletion,
    this.parentTask,
    this.showParentTask = false,
  });

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // Handle task completion toggle with confetti
  void _handleToggleCompletion() {
    if (widget.onToggleCompletion != null) {
      if (!widget.task.isDone) {
        // Only play confetti when marking as completed
        _confettiController.play();
      }
      widget.onToggleCompletion!();
    }
  }

  // Build the parent task indicator widget
  Widget _buildParentTaskIndicator(BuildContext context) {
    return Row(
      children: [
        Icon(
          CupertinoIcons.arrow_turn_up_right,
          size: 12,
          color: CupertinoColors.systemGrey,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'From: ${widget.parentTask!.title}',
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = CupertinoColors.systemBackground.resolveFrom(
      context,
    );
    final textColor = CupertinoColors.label.resolveFrom(context);
    final secondaryTextColor = CupertinoColors.secondaryLabel.resolveFrom(
      context,
    );
    final taskColor =
        widget.task.color != null
            ? Color(widget.task.color!)
            : widget.categoryColor;

    // Create a glassmorphic effect
    final glassEffect = BoxDecoration(
      color: backgroundColor.withOpacity(0.8),
      borderRadius: BorderRadius.circular(12),
      boxShadow:
          isDarkMode
              ? [
                BoxShadow(
                  color: CupertinoColors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
              : [
                BoxShadow(
                  color: CupertinoColors.systemGrey4.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      border: Border.all(
        color:
            isDarkMode
                ? CupertinoColors.systemGrey.withOpacity(0.2)
                : CupertinoColors.systemGrey5.withOpacity(0.5),
        width: 0.5,
      ),
    );

    return Stack(
      children: [
        // Confetti controller positioned at the top center of the task item
        Positioned.fill(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // straight up
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 20,
              minBlastForce: 10,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ),

        // Slidable widget for swipe actions
        Slidable(
          key: ValueKey(widget.task.id),
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (_) {
                  HapticFeedback.selectionClick();
                  widget.onEdit();
                },
                backgroundColor: CupertinoColors.systemBlue,
                foregroundColor: CupertinoColors.white,
                icon: CupertinoIcons.pencil,
                label: 'Edit',
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              SlidableAction(
                onPressed: (_) {
                  HapticFeedback.selectionClick();
                  widget.onDelete();
                },
                backgroundColor: CupertinoColors.destructiveRed,
                foregroundColor: CupertinoColors.white,
                icon: CupertinoIcons.delete,
                label: 'Delete',
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ],
          ),

          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            onPressed: () {
              HapticFeedback.selectionClick();
              widget.onTap();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: glassEffect,
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 46,
                    decoration: BoxDecoration(
                      color: taskColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.showParentTask &&
                                widget.parentTask != null) ...[
                              _ParentTaskIndicator(
                                parentTask: widget.parentTask!,
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              widget.task.title,
                              style: CupertinoTheme.of(
                                context,
                              ).textTheme.textStyle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    widget.task.isDone
                                        ? secondaryTextColor
                                        : textColor,
                                decoration:
                                    widget.task.isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${getScheduledTasksCount(widget.task)} scheduled',
                              style: CupertinoTheme.of(
                                context,
                              ).textTheme.textStyle.copyWith(
                                fontSize: 12,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                        if (widget.task.notes?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.task.notes!,
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryTextColor,
                              decoration:
                                  widget.task.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.hasSubtasks && widget.onToggleExpand != null)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: widget.onToggleExpand,
                      child: Icon(
                        widget.isExpanded
                            ? CupertinoIcons.chevron_down
                            : CupertinoIcons.chevron_right,
                        size: 20,
                        color: secondaryTextColor,
                      ),
                    ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _handleToggleCompletion,
                    child: Icon(
                      widget.task.isDone
                          ? CupertinoIcons.check_mark_circled_solid
                          : CupertinoIcons.circle,
                      color:
                          widget.task.isDone
                              ? CupertinoColors.activeGreen.resolveFrom(context)
                              : secondaryTextColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  int getScheduledTasksCount(Task task) {
    int count = 0;
    List<Task> subtasks = getLowLevelTasks(task);

    for (Task subtask in subtasks) {
      count += subtask.scheduledTasks.length;
    }
    return count;
  }

  List<Task> getLowLevelTasks(Task task) {
    List<Task> lowLevelTasks = [];

    if (task.subtaskIds.isEmpty) {
      lowLevelTasks.add(task);
      return lowLevelTasks;
    }
    var subtasks = widget.taskManagerCubit.getSubtasksForTask(task);
    for (var subtask in subtasks) {
      if (subtask.subtaskIds.isEmpty) {
        lowLevelTasks.add(subtask);
      } else {
        lowLevelTasks.addAll(getLowLevelTasks(subtask));
      }
    }
    return lowLevelTasks;
  }
}
