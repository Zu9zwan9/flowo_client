import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../models/event_model.dart';
import '../blocs/calendar/calendar_cubit.dart';
import '../blocs/calendar/calendar_state.dart';
import '../widgets/event_card.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Calendar'),
      ),
      child: BlocBuilder<CalendarCubit, CalendarState>(
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: SfCalendar(
                  view: CalendarView.month,
                  dataSource: EventDataSource(state.events),
                  onTap: (details) {
                    if (details.appointments != null && details.appointments!.isNotEmpty) {
                      final event = details.appointments!.first as Event;
                      _showEventDialog(context, event);
                    }
                  },
                  onSelectionChanged: (details) {
                    context.read<CalendarCubit>().selectDate(details.date!);
                  },
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Event>>(
                  future: context.read<CalendarCubit>().getEventsForSelectedDate(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No events found'));
                    } else {
                      final events = snapshot.data!;
                      return ListView.builder(
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return EventCard(event: event);
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEventDialog(BuildContext context, Event? event) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(event?.title ?? 'Event'),
          content: Text(event?.description ?? 'No description'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class EventDataSource extends CalendarDataSource {
  EventDataSource(List<Event> events) {
    appointments = events;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].startTime;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].endTime;
  }

  @override
  String getSubject(int index) {
    return appointments![index].title;
  }

  @override
  Color getColor(int index) {
    // Return a color based on the event category or other criteria
    switch (appointments![index].category) {
      case 'Brainstorm':
        return Colors.blue;
      case 'Design':
        return Colors.green;
      case 'Workout':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
