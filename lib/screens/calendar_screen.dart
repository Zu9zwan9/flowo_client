import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../models/event_model.dart';
import '../blocs/calendar/calendar_cubit.dart';
import '../blocs/calendar/calendar_state.dart';
import 'widgets/event_card.dart';
import '../utils/logger.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    logInfo('Building CalendarScreen');
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Calendar'),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: BlocBuilder<CalendarCubit, CalendarState>(
          builder: (context, state) {
            logDebug('CalendarState updated: ${state.status}');
            return Column(
              children: [
                _buildHeader(context, state),
                Expanded(
                  child: SfCalendar(
                    view: CalendarView.month,
                    dataSource: EventDataSource(state.events),
                    onTap: (details) {
                      if (details.appointments != null && details.appointments!.isNotEmpty) {
                        final event = details.appointments!.first as Event;
                        logDebug('Tapped on event: ${event.title}');
                      }
                    },
                    onSelectionChanged: (details) {
                      context.read<CalendarCubit>().selectDate(details.date!);
                      logDebug('Date selected: ${details.date}');
                    },
                  ),
                ),
                Expanded(
                  child: _buildEventsList(context, state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CalendarState state) {
    final selectedDate = state.selectedDate;
    final monthYear = "${selectedDate.month}/${selectedDate.year}";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_left),
          onPressed: () {
            context.read<CalendarCubit>().selectDate(
              DateTime(selectedDate.year, selectedDate.month - 1, selectedDate.day),
            );
            logDebug('Previous month selected');
          },
        ),
        Text(
          monthYear,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: Icon(Icons.arrow_right),
          onPressed: () {
            context.read<CalendarCubit>().selectDate(
              DateTime(selectedDate.year, selectedDate.month + 1, selectedDate.day),
            );
            logDebug('Next month selected');
          },
        ),
      ],
    );
  }

  FutureBuilder<List<Event>> _buildEventsList(BuildContext context, CalendarState state) {
    return FutureBuilder<List<Event>>(
      future: context.read<CalendarCubit>().getEventsForSelectedDate(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          logError('Error loading events: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No events found'));
        } else {
          final events = snapshot.data!;
          logDebug('Loaded ${events.length} events');
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return EventCard(event: event);
            },
          );
        }
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
    switch (appointments![index].category) {
      case 'Brainstorm':
        return Colors.blue;
      case 'Design':
        return Colors.green;
      case 'Workout':
        return Colors.red;
      case 'Meeting':
        return Colors.orange;
      case 'Presentation':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
