import 'package:equatable/equatable.dart';
import '../../models/event_model.dart';

enum CalendarStatus { initial, loading, success, failure }

class CalendarState extends Equatable {
  final CalendarStatus status;
  final List<Event> events;
  final DateTime selectedDate;
  final String? errorMessage;

  const CalendarState({
    this.status = CalendarStatus.initial,
    this.events = const [],
    required this.selectedDate,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, events, selectedDate, errorMessage];

  CalendarState copyWith({
    CalendarStatus? status,
    List<Event>? events,
    DateTime? selectedDate,
    String? errorMessage,
  }) {
    return CalendarState(
      status: status ?? this.status,
      events: events ?? this.events,
      selectedDate: selectedDate ?? this.selectedDate,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
