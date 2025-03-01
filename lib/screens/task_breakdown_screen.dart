import 'package:flutter/cupertino.dart';

import '../models/category.dart';
import '../models/task.dart';

class TaskBreakdownScreen extends StatelessWidget {
  final Task task;

  const TaskBreakdownScreen({required this.task, super.key});

  Future<List<Task>> generateTaskBreakdown(String taskDescription) async {
    // Simulate an API call to generate task breakdown
    await Future.delayed(Duration(seconds: 2));
    return [
      Task(
          id: UniqueKey().toString(),
          title: 'Subtask 1',
          priority: 1,
          deadline: 0,
          estimatedTime: 0,
          category: Category(name: 'General')),
      Task(
          id: UniqueKey().toString(),
          title: 'Subtask 2',
          priority: 1,
          deadline: 0,
          estimatedTime: 0,
          category: Category(name: 'General')),
      Task(
          id: UniqueKey().toString(),
          title: 'Subtask 3',
          priority: 1,
          deadline: 0,
          estimatedTime: 0,
          category: Category(name: 'General')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('${task.title} - Subtasks'),
      ),
      child: FutureBuilder<List<Task>>(
        future: generateTaskBreakdown(task.notes ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CupertinoActivityIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No subtasks found'));
          } else {
            final subtasks = snapshot.data!;
            return ListView.builder(
              itemCount: subtasks.length,
              itemBuilder: (context, index) {
                return CupertinoListTile(
                  title: Text(subtasks[index].title),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class CupertinoListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double minLeadingWidth;

  const CupertinoListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding,
    this.backgroundColor,
    this.minLeadingWidth = 28.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0);

    Widget content = Row(
      children: [
        if (leading != null) ...[
          SizedBox(
            width: minLeadingWidth,
            child: leading,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DefaultTextStyle(
                style: CupertinoTheme.of(context).textTheme.textStyle,
                child: title,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                DefaultTextStyle(
                  style:
                      CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                            fontSize: 14,
                            color: CupertinoColors.systemGrey,
                          ),
                  child: subtitle!,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? CupertinoColors.systemBackground,
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator,
            width: 0.0,
          ),
        ),
      ),
      child: content,
    );
  }
}
