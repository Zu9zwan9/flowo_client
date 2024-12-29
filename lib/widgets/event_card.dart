import 'package:flutter/material.dart';
import '../models/event_model.dart';

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({required this.event, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(event.title),
        subtitle: Text(event.description ?? ''),
      ),
    );
  }
}
