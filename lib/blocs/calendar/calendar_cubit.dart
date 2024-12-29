import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/event_model.dart';
import 'calendar_state.dart';

class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit()
      : super(CalendarState(selectedDate: DateTime.now()));

  void selectDate(DateTime date) {
    emit(state.copyWith(selectedDate: date));
  }

  void addEvent(Event event) {
    final updatedEvents = List<Event>.from(state.events)..add(event);
    emit(state.copyWith(
      events: updatedEvents,
      status: CalendarStatus.success,
    ));
  }

  void updateEvent(Event event) {
    final updatedEvents = state.events.map((e) {
      return e.id == event.id ? event : e;
    }).toList();

    emit(state.copyWith(
      events: updatedEvents,
      status: CalendarStatus.success,
    ));
  }

  void deleteEvent(String eventId) {
    final updatedEvents = state.events.where((event) => event.id != eventId).toList();
    emit(state.copyWith(
      events: updatedEvents,
      status: CalendarStatus.success,
    ));
  }

  void toggleEventCompletion(String eventId) {
    final updatedEvents = state.events.map((event) {
      if (event.id == eventId) {
        return event.copyWith(isCompleted: !event.isCompleted);
      }
      return event;
    }).toList();

    emit(state.copyWith(
      events: updatedEvents,
      status: CalendarStatus.success,
    ));
  }

  List<Event> getEventsForSelectedDate() {
    return state.events.where((event) =>
    event.date.year == state.selectedDate.year &&
        event.date.month == state.selectedDate.month &&
        event.date.day == state.selectedDate.day).toList();
  }
}
