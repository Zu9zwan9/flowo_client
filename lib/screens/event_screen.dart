import 'dart:io';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/utils/date_time_formatter.dart';
import 'package:flutter/cupertino.dart';
import '../models/task.dart';
import '../design/cupertino_form_theme.dart';
import 'event_form_screen.dart';

class EventScreen extends StatelessWidget {
  final Task event;

  const EventScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final ScheduledTask scheduledTask = event.scheduledTasks.first;
    final theme = CupertinoFormTheme(context);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Event Details'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Edit'),
          onPressed: () {
            // Navigate to editing screen
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => EventFormScreen(),
              ),
            );
          },
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CupertinoFormTheme.horizontalSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Title
              Text(
                'Title: ${event.title}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Start Time
              Text(
                'Start: ${DateTimeFormatter.formatDateTime(
                    scheduledTask.startTime)}',
              ),
              const SizedBox(height: 8),
              // End Time
              Text(
                'End: ${DateTimeFormatter.formatDateTime(
                    scheduledTask.endTime)}',
              ),
              const SizedBox(height: 8),
              // Location (if exists)
              if (event.location != null) Text('Location: ${event.location}'),
              if (event.location != null) const SizedBox(height: 8),
              // Notes (if exists)
              if (event.notes != null && event.notes!.isNotEmpty)
                Text('Notes: ${event.notes}'),
              if (event.notes != null && event.notes!.isNotEmpty)
                const SizedBox(height: 8),
              // Color (if selected)
              if (event.color != null) ...[
                const Text('Color:'),
                const SizedBox(height: 4),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Color(event.color ?? 000000),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // Traveling Time (if set)
              if (scheduledTask.travelingTime > 0)
                Text(
                  'Traveling Time: ${scheduledTask.travelingTime ~/
                      3600000}h ${(scheduledTask.travelingTime % 3600000) ~/
                      60000}m',
                ),
              if (scheduledTask.travelingTime > 0)
                const SizedBox(height: 8),
              // Image (if exists)
              if (event.image != null)
                Image.file(event.image as File, height: 200, fit: BoxFit.cover),
            ],
          ),
        ),
      ),
    );
  }
}
