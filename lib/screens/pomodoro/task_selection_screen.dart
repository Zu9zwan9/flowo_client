import 'package:flowo_client/screens/pomodoro/pomodoro_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

import '../../models/task.dart';

class TaskSelectionScreen extends StatefulWidget {
  const TaskSelectionScreen({super.key});

  @override
  State<TaskSelectionScreen> createState() => _TaskSelectionScreenState();
}

class _TaskSelectionScreenState extends State<TaskSelectionScreen> {
  Task? _selectedTask;
  Task? _selectedSubtask;
  int _customDuration = 25 * 60 * 1000; // Default 25 minutes

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
                  _selectedTask!.subtasks.isNotEmpty) ...[
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
                    itemCount: _selectedTask!.subtasks.length,
                    itemBuilder: (context, index) {
                      final subtask = _selectedTask!.subtasks[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedSubtask =
                                _selectedSubtask?.id == subtask.id
                                    ? null
                                    : subtask;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                _selectedSubtask?.id == subtask.id
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
                                _selectedSubtask?.id == subtask.id
                                    ? CupertinoIcons.checkmark_circle_fill
                                    : CupertinoIcons.circle,
                                color:
                                    _selectedSubtask?.id == subtask.id
                                        ? CupertinoColors.activeBlue
                                        : CupertinoColors.systemGrey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  subtask.title,
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
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder:
                                    (context) => PomodoroScreen(
                                      task: taskToUse,
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
