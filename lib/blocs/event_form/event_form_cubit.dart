import 'package:flutter_bloc/flutter_bloc.dart';
import 'event_form_state.dart';
import '../../models/task.dart';
import '../../utils/logger.dart';

class TaskFormCubit extends Cubit<EventFormState> {
  TaskFormCubit() : super(EventFormInitial()) {
    logInfo('TaskFormCubit initialized');
  }

  void createTask(Task task) {
    logInfo('Creating task: ${task.title}');
    emit(EventFormLoading());
    try {
      Future.delayed(Duration(seconds: 1), () {
        emit(EventFormSuccess(task));
        logInfo('Task created successfully: ${task.title}');
      });
    } catch (e) {
      emit(EventFormFailure(e.toString()));
      logError('Failed to create task: $e');
    }
  }

  void updateTask(Task task) {
    logInfo('Updating task: ${task.title}');
    emit(EventFormLoading());
    try {
      Future.delayed(Duration(seconds: 1), () {
        emit(EventFormSuccess(task));
        logInfo('Task updated successfully: ${task.title}');
      });
    } catch (e) {
      emit(EventFormFailure(e.toString()));
      logError('Failed to update task: $e');
    }
  }
}