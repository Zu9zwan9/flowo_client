import 'package:equatable/equatable.dart';
import '../../models/event_model.dart';

abstract class EventFormState extends Equatable {
  const EventFormState();

  @override
  List<Object?> get props => [];
}

class EventFormInitial extends EventFormState {}

class EventFormLoading extends EventFormState {}

class EventFormSuccess extends EventFormState {
  final Event event;

  const EventFormSuccess(this.event);

  @override
  List<Object?> get props => [event];
}

class EventFormFailure extends EventFormState {
  final String error;

  const EventFormFailure(this.error);

  @override
  List<Object?> get props => [error];
}
