import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../../models/event_model.dart';
import 'calendar_state.dart';

class CalendarCubit extends Cubit<CalendarState> {
  final Box<Event> eventBox;

  CalendarCubit(this.eventBox) : super(CalendarState(selectedDate: DateTime.now()));

  void selectDate(DateTime date) {
    emit(state.copyWith(selectedDate: date));
  }

  Future<void> addEvent(Event event) async {
    await eventBox.add(event); // Добавляем событие в Box
    final updatedEvents = eventBox.values.toList(); // Получаем все события из Box
    emit(state.copyWith(events: updatedEvents, status: CalendarStatus.success));
  }

  Future<void> updateEvent(Event event) async {
    await eventBox.put(event.id, event); // Обновляем событие в Box по id
    final updatedEvents = eventBox.values.toList(); // Получаем все события из Box
    emit(state.copyWith(events: updatedEvents, status: CalendarStatus.success));
  }

  Future<void> deleteEvent(String eventId) async {
    await eventBox.delete(eventId); // Удаляем событие по id
    final updatedEvents = eventBox.values.toList(); // Получаем все события из Box
    emit(state.copyWith(events: updatedEvents, status: CalendarStatus.success));
  }

  Future<List<Event>> getEventsForSelectedDate() async {
    final startOfDay = DateTime(state.selectedDate.year, state.selectedDate.month, state.selectedDate.day);
    final endOfDay = DateTime(state.selectedDate.year, state.selectedDate.month, state.selectedDate.day, 23, 59, 59);

    // Фильтруем события по времени, чтобы получить события за выбранную дату
    final eventsForSelectedDate = eventBox.values.where((event) {
      return event.startTime.isAfter(startOfDay) && event.startTime.isBefore(endOfDay);
    }).toList();

    return eventsForSelectedDate;
  }

  Future<Map<String, List<Event>>> getEventsGroupedByCategory() async {
    final events = eventBox.values.toList(); // Получаем все события из Box
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
