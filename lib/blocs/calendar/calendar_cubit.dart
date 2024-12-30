import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import '../../models/event_model.dart';
import 'calendar_state.dart';

class CalendarCubit extends Cubit<CalendarState> {
  final Isar isar;

  CalendarCubit(this.isar) : super(CalendarState(selectedDate: DateTime.now()));

  void selectDate(DateTime date) {
    emit(state.copyWith(selectedDate: date));
  }

  Future<void> addEvent(Event event) async {
    await isar.writeTxn(() async {
      await isar.events.put(event);
    });
    final updatedEvents = await isar.events.where().findAll();
    emit(state.copyWith(events: updatedEvents, status: CalendarStatus.success));
  }

  Future<void> updateEvent(Event event) async {
    await isar.writeTxn(() async {
      await isar.events.put(event);
    });
    final updatedEvents = await isar.events.where().findAll();
    emit(state.copyWith(events: updatedEvents, status: CalendarStatus.success));
  }

  Future<void> deleteEvent(int eventId) async {
    await isar.writeTxn(() async {
      await isar.events.delete(eventId);
    });
    final updatedEvents = await isar.events.where().findAll();
    emit(state.copyWith(events: updatedEvents, status: CalendarStatus.success));
  }

  Future<List<Event>> getEventsForSelectedDate() async {
    return await isar.events
        .filter()
        .startTimeBetween(
      DateTime(state.selectedDate.year, state.selectedDate.month, state.selectedDate.day),
      DateTime(state.selectedDate.year, state.selectedDate.month, state.selectedDate.day, 23, 59, 59),
    )
        .findAll();
  }

  Future<Map<String, List<Event>>> getEventsGroupedByCategory() async {
    final events = await isar.events.where().findAll();
    final Map<String, List<Event>> groupedEvents = {};
    for (var event in events) {
      if (!groupedEvents.containsKey(event.category)) {
        groupedEvents[event.category] = [];
      }
      groupedEvents[event.category]!.add(event);
    }
    return groupedEvents;
  }
}
