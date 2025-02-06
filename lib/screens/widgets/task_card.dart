import 'package:flutter/material.dart';
import '../../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(task.title),
        subtitle: Text(task.notes ?? ''),
        trailing: Icon(task.isDone ? Icons.check_circle : Icons.circle),
        onTap: () {
          // Handle task tap
        },
      ),
    );
  }
}