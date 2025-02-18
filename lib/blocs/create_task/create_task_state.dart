part of 'create_task_cubit.dart';

abstract class CreateTaskState {}

class CreateTaskInitial extends CreateTaskState {}

class CreateTaskSuccess extends CreateTaskState {
  final Task task;

  CreateTaskSuccess(this.task);
}