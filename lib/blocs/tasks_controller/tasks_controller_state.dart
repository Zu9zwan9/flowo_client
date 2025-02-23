import 'package:equatable/equatable.dart';

import '../../models/task.dart';

enum CalendarStatus { initial, loading, success, failure }

class CalendarState extends Equatable {
  final CalendarStatus status;
  final List<Task> tasksDB;
  final DateTime selectedDate;
  final String? errorMessage;

  const CalendarState({
    this.status = CalendarStatus.initial,
    this.tasksDB = const [],
    required this.selectedDate,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [status, tasksDB, selectedDate, errorMessage];

  CalendarState copyWith({
    CalendarStatus? status,
    List<Task>? tasks,
    DateTime? selectedDate,
    String? errorMessage,
  }) {
    return CalendarState(
      status: status ?? this.status,
      tasksDB: tasks ?? tasksDB,
      selectedDate: selectedDate ?? this.selectedDate,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
