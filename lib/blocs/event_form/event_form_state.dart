import 'package:equatable/equatable.dart';
import '../../models/task.dart';

abstract class EventFormState extends Equatable {
  const EventFormState();

  @override
  List<Object?> get props => [];
}

class EventFormInitial extends EventFormState {}

class EventFormLoading extends EventFormState {}

class EventFormSuccess extends EventFormState {
  final Task task;

  const EventFormSuccess(this.task);

  @override
  List<Object?> get props => [task];
}

class EventFormFailure extends EventFormState {
  final String error;

  const EventFormFailure(this.error);

  @override
  List<Object?> get props => [error];
}