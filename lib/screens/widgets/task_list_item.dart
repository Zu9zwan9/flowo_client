import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../blocs/tasks_controller/task_manager_cubit.dart';
import '../../models/task.dart';
import '../../utils/logger.dart';

class TaskListItem extends StatelessWidget {
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
  });

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
    final taskColor = task.color != null ? Color(task.color!) : categoryColor;

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
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
        ),
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
                      Text(
                        task.title,
                        style: CupertinoTheme.of(
                          context,
                        ).textTheme.textStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: task.isDone ? secondaryTextColor : textColor,
                          decoration:
                              task.isDone ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${getScheduledTasksCount(task)} scheduled',
                        style: CupertinoTheme.of(context).textTheme.textStyle
                            .copyWith(fontSize: 12, color: secondaryTextColor),
                      ),
                    ],
                  ),
                  if (task.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.notes!,
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                        decoration:
                            task.isDone ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (hasSubtasks && onToggleExpand != null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onToggleExpand,
                child: Icon(
                  isExpanded
                      ? CupertinoIcons.chevron_down
                      : CupertinoIcons.chevron_right,
                  size: 20,
                  color: secondaryTextColor,
                ),
              ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onToggleCompletion,
              child: Icon(
                task.isDone
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.circle,
                color:
                    task.isDone
                        ? CupertinoColors.activeGreen.resolveFrom(context)
                        : secondaryTextColor,
                size: 24,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(
                CupertinoIcons.pencil,
                size: 24,
                color: secondaryTextColor,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                onEdit();
              },
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(
                CupertinoIcons.delete,
                size: 24,
                color: CupertinoColors.destructiveRed.resolveFrom(context),
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                onDelete();
              },
            ),
          ],
        ),
      ),
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
    var subtasks = taskManagerCubit.getSubtasksForTask(task);
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
