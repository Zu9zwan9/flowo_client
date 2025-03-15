import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/services/ai_estimation_service.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flowo_client/utils/task_manager.dart';

// Define the states for the AI estimation feature
abstract class AIEstimationState extends Equatable {
  const AIEstimationState();

  @override
  List<Object?> get props => [];
}

// Initial state
class AIEstimationInitial extends AIEstimationState {}

// Loading state while estimation is in progress
class AIEstimationLoading extends AIEstimationState {
  final String message;

  const AIEstimationLoading({this.message = 'Estimating time...'});

  @override
  List<Object?> get props => [message];
}

// Success state when estimation is complete
class AIEstimationSuccess extends AIEstimationState {
  final Task? task;
  final int? estimatedTime;
  final int updatedCount;

  const AIEstimationSuccess({
    this.task,
    this.estimatedTime,
    this.updatedCount = 0,
  });

  @override
  List<Object?> get props => [task, estimatedTime, updatedCount];
}

// Error state when estimation fails
class AIEstimationError extends AIEstimationState {
  final String message;

  const AIEstimationError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Cubit to handle AI estimation
class AIEstimationCubit extends Cubit<AIEstimationState> {
  final TaskManager taskManager;
  final AIEstimationService _estimationService;

  AIEstimationCubit({required this.taskManager, String? huggingFaceApiKey})
    : _estimationService = AIEstimationService(
        taskManager: taskManager,
        huggingFaceApiKey: huggingFaceApiKey,
      ),
      super(AIEstimationInitial());

  /// Estimates time for a single task using AI
  ///
  /// Updates the task with the estimated time
  /// Emits AIEstimationSuccess with the updated task and estimated time
  Future<void> estimateTaskTime(Task task) async {
    emit(const AIEstimationLoading(message: 'Estimating time for task...'));

    try {
      final estimatedTime = await _estimationService.estimateTaskTime(task);

      // Update the task with the estimated time
      task.estimatedTime = estimatedTime;
      taskManager.tasksDB.put(task.id, task);

      logInfo(
        'Updated task "${task.title}" with estimated time: $estimatedTime minutes',
      );

      emit(AIEstimationSuccess(task: task, estimatedTime: estimatedTime));
    } catch (e) {
      logError('Error estimating time for task: $e');
      emit(
        AIEstimationError(message: 'Failed to estimate time: ${e.toString()}'),
      );
    }
  }

  /// Estimates time for a task and its subtasks using AI
  ///
  /// Updates the task and its subtasks with the estimated times
  /// Emits AIEstimationSuccess with the updated task
  Future<void> estimateTaskAndSubtasks(Task task) async {
    emit(
      const AIEstimationLoading(
        message: 'Estimating time for task and subtasks...',
      ),
    );

    try {
      final updatedTask = await _estimationService.estimateTaskAndSubtasks(
        task,
      );

      logInfo(
        'Updated task "${updatedTask.title}" and its subtasks with AI-estimated times',
      );

      emit(
        AIEstimationSuccess(
          task: updatedTask,
          estimatedTime: updatedTask.estimatedTime,
        ),
      );
    } catch (e) {
      logError('Error estimating time for task and subtasks: $e');
      emit(
        AIEstimationError(message: 'Failed to estimate time: ${e.toString()}'),
      );
    }
  }

  /// Estimates time for all tasks in the system using AI
  ///
  /// Updates all tasks with the estimated times
  /// Emits AIEstimationSuccess with the number of tasks updated
  Future<void> estimateAllTasks() async {
    emit(
      const AIEstimationLoading(message: 'Estimating time for all tasks...'),
    );

    try {
      final updatedCount = await _estimationService.estimateAllTasks();

      logInfo('Updated $updatedCount tasks with AI-estimated times');

      emit(AIEstimationSuccess(updatedCount: updatedCount));
    } catch (e) {
      logError('Error estimating time for all tasks: $e');
      emit(
        AIEstimationError(message: 'Failed to estimate time: ${e.toString()}'),
      );
    }
  }
}
