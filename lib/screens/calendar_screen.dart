import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../blocs/calendar/calendar_cubit.dart';
import '../blocs/calendar/calendar_state.dart';
import '../widgets/event_card.dart';
import 'add_event_screen.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: BlocBuilder<CalendarCubit, CalendarState>(
        builder: (context, state) {
          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: state.selectedDate,
                selectedDayPredicate: (day) =>
                    isSameDay(state.selectedDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  context.read<CalendarCubit>().selectDate(selectedDay);
                },
                calendarStyle: const CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Color(0xFF6750A4),
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: context
                      .read<CalendarCubit>()
                      .getEventsForSelectedDate()
                      .length,
                  itemBuilder: (context, index) {
                    final events =
                    context.read<CalendarCubit>().getEventsForSelectedDate();
                    final event = events[index];
                    return EventCard(event: event);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEventScreen()),
          );
        },
      ),
    );
  }
}
