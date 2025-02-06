import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/calendar/calendar_cubit.dart';
import '../models/task.dart';
import 'task_breakdown_screen.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task List'),
      ),
      body: FutureBuilder<Map<String, List<Task>>>(
        future: context.read<CalendarCubit>().getTasksGroupedByCategory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No tasks found'));
          } else {
            final groupedTasks = snapshot.data!;
            return ListView(
              children: groupedTasks.keys.map((category) {
                return ExpansionTile(
                  title: Text(category),
                  children: groupedTasks[category]!.map((task) {
                    return ListTile(
                      title: Text(task.title),
                      subtitle: Text(task.notes ?? ''),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
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