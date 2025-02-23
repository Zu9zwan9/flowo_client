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

  const CupertinoListTile({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: title,
      ),
    );
  }
}
