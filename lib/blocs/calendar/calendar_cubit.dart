import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../../models/event_model.dart';
import 'calendar_state.dart';
import '../../utils/logger.dart';

class CalendarCubit extends Cubit<CalendarState> {
  final Box<Event> eventBox;

  CalendarCubit(this.eventBox) : super(CalendarState(selectedDate: DateTime.now())) {
    logInfo('CalendarCubit initialized');
    _loadEvents();
  }

  void _loadEvents() {
    final events = eventBox.values.toList();
    logDebug('Loaded ${events.length} events from Hive');
    emit(state.copyWith(events: events, status: CalendarStatus.success));
  }

  void selectDate(DateTime date) {
    logDebug('Selected date: $date');
    emit(state.copyWith(selectedDate: date));
  }

  Future<void> addEvent(Event event) async {
    logInfo('Adding event: ${event.title}');
    await eventBox.add(event);
    logDebug('Event added: ${event.title}');
    _loadEvents();
  }

  Future<void> updateEvent(Event event) async {
    logInfo('Updating event: ${event.title}');
    await eventBox.put(event.id, event);
    logDebug('Event updated: ${event.title}');
    _loadEvents();
  }

  Future<void> deleteEvent(String eventId) async {
    logWarning('Deleting event with ID: $eventId');
    await eventBox.delete(eventId);
    logDebug('Event deleted with ID: $eventId');
    _loadEvents();
  }

  Future<List<Event>> getEventsForSelectedDate() async {
    final startOfDay = DateTime(state.selectedDate.year, state.selectedDate.month, state.selectedDate.day);
    final endOfDay = DateTime(state.selectedDate.year, state.selectedDate.month, state.selectedDate.day, 23, 59, 59);

    final eventsForSelectedDate = eventBox.values.where((event) {
      return event.startTime.isAfter(startOfDay) && event.startTime.isBefore(endOfDay);
    }).toList();

    logDebug('Events for selected date: ${eventsForSelectedDate.length}');
    return eventsForSelectedDate;
  }

  Future<Map<String, List<Event>>> getEventsGroupedByCategory() async {
    final events = eventBox.values.toList();
    final Map<String, List<Event>> groupedEvents = {};
    for (var event in events) {
      if (!groupedEvents.containsKey(event.category)) {
        groupedEvents[event.category] = [];
      }
      groupedEvents[event.category]!.add(event);
    }
    logDebug('Events grouped by category: ${groupedEvents.keys.length}');
    return groupedEvents;
  }
}
