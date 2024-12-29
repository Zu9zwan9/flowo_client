import 'package:flutter/material.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task List'),
      ),
      body: ListView.builder(
        itemCount: 10, // Replace with the actual number of tasks
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Task ${index + 1}'), // Replace with actual task data
            subtitle: Text('Task details here'), // Replace with actual task details
            trailing: IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () {
                // Handle task completion
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle adding a new task
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
