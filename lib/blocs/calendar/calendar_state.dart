import 'package:equatable/equatable.dart';
import '../../models/task.dart';

enum CalendarStatus { initial, loading, success, failure }

class CalendarState extends Equatable {
  final CalendarStatus status;
  final List<Task> tasks;
  final DateTime selectedDate;
  final String? errorMessage;

  const CalendarState({
    this.status = CalendarStatus.initial,
    this.tasks = const [],
    required this.selectedDate,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, tasks, selectedDate, errorMessage];

  CalendarState copyWith({
    CalendarStatus? status,
    List<Task>? tasks,
    DateTime? selectedDate,
    String? errorMessage,
  }) {
    return CalendarState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      selectedDate: selectedDate ?? this.selectedDate,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
