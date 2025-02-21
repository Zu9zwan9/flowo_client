import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/calendar/calendar_cubit.dart';
import '../models/task.dart';
import 'task_breakdown_screen.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Task List'),
      ),
      child: FutureBuilder<Map<String, List<Task>>>(
        future: context.read<CalendarCubit>().getTasksGroupedByCategory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tasks found'));
          } else {
            final groupedTasks = snapshot.data!;
            return ListView(
              children: groupedTasks.keys.map((category) {
                return CupertinoListTile(
                  title: Text(category),
                  children: groupedTasks[category]!.map((task) {
                    return CupertinoListTile(
                      title: Text(task.title),
                      subtitle: Text(task.notes ?? ''),
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => TaskBreakdownScreen(task: task),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              }).toList(),
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
  final VoidCallback? onTap;
  final List<Widget>? children;

  const CupertinoListTile({
    required this.title,
    this.subtitle,
    this.onTap,
    this.children,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator,
                  width: 0.0,
                ),
              ),
            ),
            child: DefaultTextStyle(
              style: CupertinoTheme.of(context).textTheme.textStyle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  if (subtitle != null) ...[
                    const SizedBox(height: 4.0),
                    DefaultTextStyle(
                      style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                        color: CupertinoColors.systemGrey,
                        fontSize: 14.0,
                      ),
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (children != null) ...children!,
      ],
    );
  }
}
