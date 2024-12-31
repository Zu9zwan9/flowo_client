import 'package:flutter/material.dart';
import '../models/event_model.dart';

class TaskBreakdownScreen extends StatelessWidget {
  final Event event;

  const TaskBreakdownScreen({required this.event, super.key});

  Future<List<String>> generateTaskBreakdown(String taskDescription) async {
    // Simulate an API call to generate task breakdown
    await Future.delayed(Duration(seconds: 2));
    return ['Subtask 1', 'Subtask 2', 'Subtask 3'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Breakdown'),
      ),
      body: FutureBuilder<List<String>>(
        future: generateTaskBreakdown(event.description ?? ''),
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
                  title: Text(subtasks[index]),
                );
              },
            );
          }
        },
      ),
    );
  }
}
