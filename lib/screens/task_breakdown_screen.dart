import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/task.dart';

class TaskBreakdownScreen extends StatelessWidget {
  final Task task;

  const TaskBreakdownScreen({required this.task, super.key});

  Future<List<Task>> generateTaskBreakdown(String taskDescription) async {
    // Simulate an API call to generate task breakdown
    await Future.delayed(Duration(seconds: 2));
    return [
      Task(id: UniqueKey().toString(), title: 'Subtask 1', priority: 1, deadline: 0, estimatedTime: 0, category: Category(name: 'General')),
      Task(id: UniqueKey().toString(), title: 'Subtask 2', priority: 1, deadline: 0, estimatedTime: 0, category: Category(name: 'General')),
      Task(id: UniqueKey().toString(), title: 'Subtask 3', priority: 1, deadline: 0, estimatedTime: 0, category: Category(name: 'General')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${task.title} - Subtasks'),
      ),
      body: FutureBuilder<List<Task>>(
        future: generateTaskBreakdown(task.notes ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No subtasks found'));
          } else {
            final subtasks = snapshot.data!;
            return ListView.builder(
              itemCount: subtasks.length,
              itemBuilder: (context, index) {
                return ListTile(
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
