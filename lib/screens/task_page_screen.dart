import 'package:flutter/cupertino.dart';
import '../models/task.dart';

class TaskPageScreen extends StatefulWidget {
  final Task task;
  const TaskPageScreen({required this.task, super.key});

  @override
  Future<_TaskPageScreenState> createState() async => _TaskPageScreenState();
}

class _TaskPageScreenState extends State<TaskPageScreen> {
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  void _calculateMagic() {
    // Here you can perform any complex calculation using the task fields.
    // For demonstration, the magic value is defined as:
    // magicValue = priority * estimatedTime.
    int magicValue = _task.priority * _task.estimatedTime;
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Magic Calculation'),
        content: Text('Magic value: $magicValue'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Convert deadline (int) to DateTime string (if needed)
    String deadlineStr =
        DateTime.fromMillisecondsSinceEpoch(_task.deadline).toString();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Task Details'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildField('ID', _task.id),
              _buildField('Title', _task.title),
              _buildField('Priority', _task.priority.toString()),
              _buildField('Deadline', deadlineStr),
              _buildField('Estimated Time', _task.estimatedTime.toString()),
              _buildField('Category', _task.category.name),
              _buildField('Notes', _task.notes ?? 'None'),
              _buildField('Is Done', _task.isDone ? 'Yes' : 'No'),
              _buildField('Order', _task.order?.toString() ?? 'Not set'),
              _buildField('Overdue', _task.overdue ? 'Yes' : 'No'),
              _buildField(
                  'Frequency',
                  _task.frequency != null
                      ? _task.frequency!.join(', ')
                      : 'None'),
              _buildField(
                  'Subtasks',
                  _task.subtasks.isNotEmpty
                      ? '${_task.subtasks.length} subtasks'
                      : 'None'),
              _buildField(
                  'Scheduled Tasks',
                  _task.scheduledTasks.isNotEmpty
                      ? '${_task.scheduledTasks.length} tasks'
                      : 'None'),
              _buildField('Parent Task',
                  _task.parentTask != null ? _task.parentTask!.title : 'None'),
              // Location
              _buildField(
                  'Location',
                  _task.location != null
                      ? 'Lat: ${_task.location!.latitude}, Long: ${_task.location!.longitude}'
                      : 'Not set'),
              // Image may be a URL or file reference:
              _buildField('Image', _task.image ?? 'None'),
              const SizedBox(height: 32),
              CupertinoButton.filled(
                onPressed: _calculateMagic,
                child: const Text('Magic'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
