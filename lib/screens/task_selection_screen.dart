import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

import '../models/task.dart';
import 'pomodoro_screen.dart';

class TaskSelectionScreen extends StatefulWidget {
  const TaskSelectionScreen({Key? key}) : super(key: key);

  @override
  State<TaskSelectionScreen> createState() => _TaskSelectionScreenState();
}

class _TaskSelectionScreenState extends State<TaskSelectionScreen> {
  Task? _selectedTask;
  int _customDuration = 25 * 60 * 1000; // Default 25 minutes
  bool _useCustomDuration = false;

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

              // Duration selection
              Row(
                children: [
                  CupertinoSwitch(
                    value: _useCustomDuration,
                    onChanged: (value) {
                      setState(() {
                        _useCustomDuration = value;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Use custom duration',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),

              if (_useCustomDuration) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Duration: '),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(_customDuration),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoSlider(
                    min: 5 * 60 * 1000, // 5 minutes
                    max: 60 * 60 * 1000, // 60 minutes
                    divisions: 55,
                    value: _customDuration.toDouble(),
                    onChanged: (value) {
                      setState(() {
                        _customDuration = value.toInt();
                      });
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
                      _selectedTask != null || _useCustomDuration
                          ? () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder:
                                    (context) => PomodoroScreen(
                                      task: _selectedTask,
                                      customDuration:
                                          _useCustomDuration
                                              ? _customDuration
                                              : null,
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
