import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/tasks_controller/task_manager_cubit.dart';
import '../../../models/task.dart';

class SubtasksList extends StatefulWidget {
  final List<Task> subtasks;
  final Task parentTask;
  final VoidCallback onAdd;
  final Function(Task) onDelete;

  const SubtasksList({
    required this.subtasks,
    required this.parentTask,
    required this.onAdd,
    required this.onDelete,
    super.key,
  });

  @override
  _SubtasksListState createState() => _SubtasksListState();
}

class _SubtasksListState extends State<SubtasksList> {
  late List<Task> _reorderedSubtasks;
  bool _orderChanged = false;

  @override
  void initState() {
    super.initState();
    _updateSubtasks();
  }

  @override
  void didUpdateWidget(SubtasksList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.subtasks.length != oldWidget.subtasks.length ||
        !_areSubtasksIdentical(widget.subtasks, oldWidget.subtasks)) {
      _updateSubtasks();
    }
  }

  bool _areSubtasksIdentical(List<Task> list1, List<Task> list2) {
    if (list1.length != list2.length) return false;

    final ids1 = list1.map((task) => task.id).toSet();
    final ids2 = list2.map((task) => task.id).toSet();

    return setEquals(ids1, ids2);
  }

  void _updateSubtasks() {
    setState(() {
      _reorderedSubtasks = List<Task>.from(widget.subtasks)
        ..sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
      _orderChanged = false;
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Task item = _reorderedSubtasks.removeAt(oldIndex);
      _reorderedSubtasks.insert(newIndex, item);
      _orderChanged = true;
    });
  }

  void _confirmOrder() {
    final taskManagerCubit = context.read<TaskManagerCubit>();
    for (int i = 0; i < _reorderedSubtasks.length; i++) {
      final task = _reorderedSubtasks[i];
      task.order = i + 1;
      task.save();
    }
    taskManagerCubit.updateTaskOrder(widget.parentTask, _reorderedSubtasks);
    setState(() {
      _orderChanged = false;
    });
  }

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
              const Icon(
                CupertinoIcons.list_bullet,
                size: 20,
                color: CupertinoColors.activeBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Subtasks',
                style: theme.textTheme.navTitleTextStyle.copyWith(fontSize: 18),
              ),
              const Spacer(),
              Flexible(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onPressed: widget.onAdd,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.add, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Add Subtask',
                          style: theme.textTheme.textStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                '${_reorderedSubtasks.length}',
                style: theme.textTheme.textStyle.copyWith(
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: _onReorder,
            children:
                _reorderedSubtasks.asMap().entries.map((entry) {
                  final index = entry.key;
                  final subtask = entry.value;
                  return Container(
                    key: ValueKey(subtask.id),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: SubtaskItem(
                      subtask: subtask,
                      onDelete: widget.onDelete,
                      reorderIndex: index,
                    ),
                  );
                }).toList(),
          ),
          if (_orderChanged) ...[
            const SizedBox(height: 12),
            CupertinoButton.filled(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onPressed: _confirmOrder,
              child: const Text('Confirm Order'),
            ),
          ],
        ],
      ),
    );
  }
}

class SubtaskItem extends StatelessWidget {
  final Task subtask;
  final Function(Task) onDelete;
  final int reorderIndex;
  const SubtaskItem({
    required this.subtask,
    required this.onDelete,
    required this.reorderIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: reorderIndex,
            child: const Icon(
              CupertinoIcons.line_horizontal_3,
              size: 20,
              color: CupertinoColors.systemGrey,
              semanticLabel: 'Drag to reorder',
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color:
                  subtask.color != null
                      ? Color(subtask.color!)
                      : CupertinoColors.systemGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        context
                            .read<TaskManagerCubit>()
                            .toggleTaskCompletion(subtask)
                            .then((isCompleted) {
                              subtask.isDone = isCompleted;
                            });
                      },
                      child: Icon(
                        subtask.isDone
                            ? CupertinoIcons.check_mark_circled_solid
                            : CupertinoIcons.circle,
                        color:
                            subtask.isDone
                                ? CupertinoColors.activeGreen
                                : CupertinoColors.systemGrey,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subtask.title,
                        style: theme.textTheme.textStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration:
                              subtask.isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                          color:
                              subtask.isDone
                                  ? CupertinoColors.systemGrey
                                  : theme.textTheme.textStyle.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.time,
                      size: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Est. time: ${DurationFormatter.format(subtask.estimatedTime)}',
                        style: theme.textTheme.textStyle.copyWith(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      CupertinoIcons.flag,
                      size: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Priority: ${subtask.priority}',
                      style: theme.textTheme.textStyle.copyWith(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.delete, size: 20),
            onPressed: () => onDelete(subtask),
          ),
        ],
      ),
    );
  }
}

/// TODO: Placeholder for DurationFormatter (implement this in your utils)
class DurationFormatter {
  static String format(int? milliseconds) {
    if (milliseconds == null) return 'N/A';
    final duration = Duration(milliseconds: milliseconds);
    return '${duration.inMinutes} min';
  }
}
