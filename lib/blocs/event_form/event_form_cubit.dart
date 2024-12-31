import 'package:flutter_bloc/flutter_bloc.dart';
import 'event_form_state.dart';
import '../../models/event_model.dart';
import '../../utils/logger.dart';

class EventFormCubit extends Cubit<EventFormState> {
  EventFormCubit() : super(EventFormInitial()) {
    logInfo('EventFormCubit initialized');
  }

  void createEvent(Event event) {
    logInfo('Creating event: ${event.title}');
    emit(EventFormLoading());
    try {
      Future.delayed(Duration(seconds: 1), () {
        emit(EventFormSuccess(event));
        logInfo('Event created successfully: ${event.title}');
      });
    } catch (e) {
      emit(EventFormFailure(e.toString()));
      logError('Failed to create event: $e');
    }
  }

  void updateEvent(Event event) {
    logInfo('Updating event: ${event.title}');
    emit(EventFormLoading());
    try {
      Future.delayed(Duration(seconds: 1), () {
        emit(EventFormSuccess(event));
        logInfo('Event updated successfully: ${event.title}');
      });
    } catch (e) {
      emit(EventFormFailure(e.toString()));
      logError('Failed to update event: $e');
    }
  }
}
