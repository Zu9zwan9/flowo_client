import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../models/task.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color categoryColor;
  final bool hasSubtasks;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.categoryColor,
    this.hasSubtasks = false,
    this.isExpanded = false,
    this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: task.color != null ? Color(task.color!) : categoryColor,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(2)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${task.title} (${task.scheduledTasks.length})',
                    style:
                        CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.label,
                            ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.notes?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.notes!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
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
                  color: CupertinoColors.systemGrey,
                ),
              ),
            Icon(
              task.isDone
                  ? CupertinoIcons.check_mark_circled
                  : CupertinoIcons.circle,
              color: task.isDone
                  ? CupertinoColors.activeGreen
                  : CupertinoColors.systemGrey,
              size: 24,
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.pencil, size: 24),
              onPressed: () {
                HapticFeedback.selectionClick();
                onEdit();
              },
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.delete, size: 24),
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
}
