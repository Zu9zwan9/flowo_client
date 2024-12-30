import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/calendar/calendar_cubit.dart';
import '../models/event_model.dart';
import 'task_breakdown_screen.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task List'),
      ),
      body: FutureBuilder<Map<String, List<Event>>>(
        future: context.read<CalendarCubit>().getEventsGroupedByCategory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No tasks found'));
          } else {
            final groupedEvents = snapshot.data!;
            return ListView(
              children: groupedEvents.keys.map((category) {
                return ExpansionTile(
                  title: Text(category),
                  children: groupedEvents[category]!.map((event) {
                    return ListTile(
                      title: Text(event.title),
                      subtitle: Text(event.description ?? ''),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskBreakdownScreen(event: event),
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
