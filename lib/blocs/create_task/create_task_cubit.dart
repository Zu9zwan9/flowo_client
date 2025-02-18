import 'package:bloc/bloc.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/models/category.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

part 'create_task_state.dart';

class CreateTaskCubit extends Cubit<CreateTaskState> {
  final Box<Task> taskBox;

  CreateTaskCubit(this.taskBox) : super(CreateTaskInitial());

  void createTask(String title, int priority, int estimatedTime, int deadline, Category category, String? notes) {
    final task = Task(
      id: UniqueKey().toString(),
      title: title,
      priority: priority,
      estimatedTime: estimatedTime,
      deadline: deadline,
      category: category,
      notes: notes,
    );
    taskBox.put(task.id, task);
    emit(CreateTaskSuccess(task));
  }
}