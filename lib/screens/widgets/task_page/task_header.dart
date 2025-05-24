import 'package:flutter/cupertino.dart';

import '../../../models/task.dart';
import '../../task/task_page_screen.dart';
import 'category_tag.dart';
import 'completion_toggle.dart';

class TaskHeader extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  const TaskHeader({required this.task, required this.onToggle, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryTag(categoryName: task.category.name),
              const SizedBox(width: 8),
              Expanded(
                child: CompletionToggle(
                  isDone: task.isDone,
                  onPressed: onToggle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Priority: ${task.priority}',
                  style: theme.textTheme.textStyle.copyWith(
                    color: CupertinoColors.systemGrey,
                  ),
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Vertical spacing between rows
          Row(
            children: [
              const Icon(
                CupertinoIcons.time, // Time icon
                size: 14,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  DurationFormatter.format(
                    task.estimatedTime,
                  ), // Format and display estimated time
                  style: theme.textTheme.textStyle.copyWith(
                    color: CupertinoColors.systemGrey,
                  ),
                  overflow: TextOverflow.visible,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                CupertinoIcons.calendar, // Calendar icon
                size: 14,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  DateTime.fromMillisecondsSinceEpoch(task.deadline)
                      .toLocal()
                      .toString()
                      .split(' ')[0], // Format and display deadline date
                  style: theme.textTheme.textStyle.copyWith(
                    color: CupertinoColors.systemGrey,
                  ),
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
