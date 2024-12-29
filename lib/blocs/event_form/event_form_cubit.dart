import 'package:flutter_bloc/flutter_bloc.dart';
import 'event_form_state.dart';
import '../../models/event_model.dart';

class EventFormCubit extends Cubit<EventFormState> {
  EventFormCubit() : super(EventFormInitial());

  void createEvent(Event event) {
    emit(EventFormLoading());
    try {
      // Simulate a delay for event creation
      Future.delayed(Duration(seconds: 1), () {
        emit(EventFormSuccess(event));
      });
    } catch (e) {
      emit(EventFormFailure(e.toString()));
    }
  }
}
