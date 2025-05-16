import 'package:flowo_client/blocs/tasks_controller/task_manager_cubit.dart';
import 'package:flowo_client/screens/pomodoro/pomodoro_timer_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../models/scheduled_task.dart';
import '../../models/task.dart';

class TaskSelectionScreen extends StatefulWidget {
  const TaskSelectionScreen({super.key});

  @override
  State<TaskSelectionScreen> createState() => _TaskSelectionScreenState();
}

class _TaskSelectionScreenState extends State<TaskSelectionScreen> {
  Task? _selectedTask;
  Task? _selectedSubtask;
  ScheduledTask? _selectedScheduledTask;
  late final TaskManagerCubit _taskManagerCubit;
  final int _customDuration = 25 * 60 * 1000; // Default 25 minutes

  @override
  void initState() {
    super.initState();
    _taskManagerCubit = context.read<TaskManagerCubit>();
  }

  @override
  Widget build(BuildContext context) {
    final tasksBox = Hive.box<Task>('tasks');
    final tasks = tasksBox.values.where((task) => !task.isDone).toList();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Select Task for Pomodoro'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a task to work on:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Task selection list
              Expanded(
                child:
                    tasks.isEmpty
                        ? const Center(
                          child: Text(
                            'No tasks available. Create a task first.',
                            style: TextStyle(color: CupertinoColors.systemGrey),
                          ),
                        )
                        : ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTask = task;
                                  _selectedSubtask = null;
                                  _selectedScheduledTask = null;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      _selectedTask?.id == task.id
                                          ? CupertinoColors.activeBlue
                                              .withOpacity(0.1)
                                          : CupertinoColors.systemBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        _selectedTask?.id == task.id
                                            ? CupertinoColors.activeBlue
                                            : CupertinoColors.systemGrey4,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _selectedTask?.id == task.id
                                          ? CupertinoIcons.checkmark_circle_fill
                                          : CupertinoIcons.circle,
                                      color:
                                          _selectedTask?.id == task.id
                                              ? CupertinoColors.activeBlue
                                              : CupertinoColors.systemGrey,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            'Estimated time: ${_formatTime(task.estimatedTime)}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: CupertinoColors.systemGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),

              const SizedBox(height: 16),

              // Subtasks selection (only shown when a task is selected)
              if (_selectedTask != null &&
                  _selectedTask!.subtaskIds.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Select a subtask (optional):',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: CupertinoColors.systemGrey4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _selectedTask!.subtaskIds.length,
                    itemBuilder: (context, index) {
                      final subtaskId = _selectedTask!.subtaskIds[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSubtask =
                                _selectedSubtask?.id == subtaskId
                                    ? null
                                    : _taskManagerCubit.getTaskById(subtaskId);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                _selectedSubtask?.id == subtaskId
                                    ? CupertinoColors.activeBlue.withOpacity(
                                      0.1,
                                    )
                                    : CupertinoColors.systemBackground,
                            border: Border(
                              bottom: BorderSide(
                                color: CupertinoColors.systemGrey4,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedSubtask?.id == subtaskId
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : CupertinoIcons.circle,
                                color:
                                    _selectedSubtask?.id == subtaskId
                                        ? CupertinoColors.activeBlue
                                        : CupertinoColors.systemGrey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _taskManagerCubit.getTaskById(subtaskId)!.title,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Scheduled tasks selection (only shown when a task is selected)
              if (_selectedTask != null &&
                  _selectedTask!.scheduledTasks.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Select a scheduled task (optional):',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: CupertinoColors.systemGrey4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _selectedTask!.scheduledTasks.length,
                    itemBuilder: (context, index) {
                      final scheduledTask =
                          _selectedTask!.scheduledTasks[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            // Toggle selection of scheduled task
                            if (_selectedScheduledTask?.scheduledTaskId ==
                                scheduledTask.scheduledTaskId) {
                              _selectedScheduledTask = null;
                            } else {
                              _selectedScheduledTask = scheduledTask;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                _selectedScheduledTask?.scheduledTaskId ==
                                        scheduledTask.scheduledTaskId
                                    ? CupertinoColors.activeBlue.withOpacity(
                                      0.1,
                                    )
                                    : CupertinoColors.systemBackground,
                            border: Border(
                              bottom: BorderSide(
                                color: CupertinoColors.systemGrey4,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedScheduledTask?.scheduledTaskId ==
                                        scheduledTask.scheduledTaskId
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : CupertinoIcons.circle,
                                color:
                                    _selectedScheduledTask?.scheduledTaskId ==
                                            scheduledTask.scheduledTaskId
                                        ? CupertinoColors.activeBlue
                                        : CupertinoColors.systemGrey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${scheduledTask.startTime.hour}:${scheduledTask.startTime.minute.toString().padLeft(2, '0')} - ${scheduledTask.endTime.hour}:${scheduledTask.endTime.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      'Type: ${scheduledTask.type.toString().split('.').last}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: CupertinoColors.systemGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Start button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed:
                      _selectedTask != null
                          ? () {
                            // If a subtask is selected, use that instead of the main task
                            final taskToUse = _selectedSubtask ?? _selectedTask;

                            // If a scheduled task is selected, use its parent task
                            Task? finalTaskToUse = taskToUse;
                            if (_selectedScheduledTask != null) {
                              // Get the parent task from the scheduled task if available
                              final parentTask =
                                  _selectedScheduledTask!.parentTask;
                              if (parentTask != null) {
                                finalTaskToUse = parentTask;
                              }
                            }

                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder:
                                    (context) => PomodoroScreen(
                                      task: finalTaskToUse,
                                      scheduledTask: _selectedScheduledTask,
                                      customDuration:
                                          null, // No more custom duration option
                                    ),
                              ),
                            );
                          }
                          : null,
                  child: const Text('Start Pomodoro'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int milliseconds) {
    final minutes = (milliseconds / 60000).floor();
    final seconds = ((milliseconds % 60000) / 1000).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
