import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/tasks_controller/task_manager_cubit.dart';
import '../models/category.dart';
import '../models/task.dart';
import '../utils/logger.dart';
import '../utils/category_utils.dart';
import '../utils/hugging_face_api.dart';

class TaskPageScreen extends StatefulWidget {
  final Task task;
  final bool isEditing;

  const TaskPageScreen({
    required this.task,
    this.isEditing = false,
    super.key,
  });

  @override
  _TaskPageScreenState createState() => _TaskPageScreenState();
}

class _TaskPageScreenState extends State<TaskPageScreen> {
  late Task _task;
  bool _isLoading = false;
  bool _hasBreakdown = false;
  List<Task> _subtasks = [];
  final TextEditingController _notesController = TextEditingController();

  // Hugging Face API service
  final HuggingFaceAPI _huggingFaceAPI = HuggingFaceAPI(
    apiKey: "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",
  );

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _notesController.text = _task.notes ?? '';
    _loadExistingSubtasks();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _loadExistingSubtasks() {
    setState(() {
      _subtasks = _task.subtasks;
      _hasBreakdown = _subtasks.isNotEmpty;
    });
  }

  Future<void> _generateTaskBreakdown() async {
    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Generate subtasks using the AI service
      final generatedSubtasks = await _aiTaskBreakdown(_task);

      // Update UI with generated subtasks
      setState(() {
        _subtasks = generatedSubtasks;
        _hasBreakdown = true;
        _isLoading = false;
      });

      // Save the generated subtasks
      _saveSubtasks(generatedSubtasks);

      // Show success message
      _showSuccessDialog(
          'Successfully generated ${generatedSubtasks.length} subtasks using AI');
    } catch (e) {
      logError('Error generating task breakdown: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to generate task breakdown: ${e.toString()}');
    }
  }

  Future<List<Task>> _aiTaskBreakdown(Task parentTask) async {
    try {
      // Use the Hugging Face API to generate subtasks
      final generatedSubtasks =
          await _huggingFaceAPI.generateSubtasks(parentTask);

      // If no subtasks were generated, fall back to the default implementation
      if (generatedSubtasks.isEmpty) {
        logWarning('No subtasks generated from API, using fallback method');
        return _fallbackTaskBreakdown(parentTask);
      }

      return generatedSubtasks;
    } catch (e) {
      logError('Error in AI task breakdown: $e');
      // Fall back to the default implementation if there's an error
      return _fallbackTaskBreakdown(parentTask);
    }
  }

  // Fallback method for generating subtasks if the API fails
  List<Task> _fallbackTaskBreakdown(Task parentTask) {
    final complexity = parentTask.estimatedTime ~/ 3600000;
    final subtasks = <Task>[];
    final baseTitle = parentTask.title;
    final taskTypes = ['Research', 'Plan', 'Draft', 'Review', 'Finalize'];

    for (int i = 0; i < (complexity.clamp(3, 5)); i++) {
      final subtask = Task(
        id: UniqueKey().toString(),
        title: '${taskTypes[i % taskTypes.length]} $baseTitle',
        priority: parentTask.priority,
        deadline: parentTask.deadline,
        estimatedTime: parentTask.estimatedTime ~/ (complexity + 1),
        category: parentTask.category,
        notes: 'Subtask ${i + 1} for $baseTitle',
        parentTask: parentTask,
      );
      subtasks.add(subtask);
    }
    return subtasks;
  }

  void _saveSubtasks(List<Task> subtasks) {
    _task.subtasks.clear();
    for (var subtask in subtasks) {
      _task.subtasks.add(subtask);
      subtask.parentTask = _task;
      context.read<TaskManagerCubit>().createTask(
            title: subtask.title,
            priority: subtask.priority,
            estimatedTime: subtask.estimatedTime,
            deadline: subtask.deadline,
            category: subtask.category,
            parentTask: subtask.parentTask,
            notes: subtask.notes,
          );
    }
    _task.save();
    logInfo('Saved ${subtasks.length} subtasks for ${_task.title}');
  }

  void _scheduleSubtasks() {
    if (_subtasks.isEmpty) {
      _showErrorDialog('Please generate subtasks first');
      return;
    }

    setState(() => _isLoading = true);

    try {
      for (var subtask in _subtasks) {
        context.read<TaskManagerCubit>().scheduleTask(subtask);
      }
      setState(() => _isLoading = false);

      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Tasks Scheduled'),
          content: Text(
              '${_subtasks.length} subtasks have been scheduled successfully.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      );
    } catch (e) {
      logError('Error scheduling subtasks: $e');
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to schedule subtasks');
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
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

  void _showInfoDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Information'),
        content: Text(message),
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

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Success'),
        content: Text(message),
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

  void _deleteSubtask(Task subtask) {
    setState(() {
      _subtasks.remove(subtask);
      _task.subtasks.remove(subtask);
    });
    _task.save();
  }

  Widget _buildSubtaskItem(Task subtask) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey5.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: CategoryUtils.getCategoryColor(subtask.category.name),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtask.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Est. time: ${_formatDuration(subtask.estimatedTime)}',
                    style: const TextStyle(
                        fontSize: 12, color: CupertinoColors.systemGrey),
                  ),
                ],
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.delete, size: 20),
              onPressed: () => _deleteSubtask(subtask),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    final hours = milliseconds ~/ 3600000;
    final minutes = (milliseconds % 3600000) ~/ 60000;
    return hours > 0
        ? '$hours hr ${minutes > 0 ? '$minutes min' : ''}'
        : minutes > 0
            ? '$minutes min'
            : '< 1 min';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(_task.title)),
      child: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildTaskHeader(),
                const SizedBox(height: 24),
                _buildTaskDescription(),
                const SizedBox(height: 24),
                _buildMagicButton(),
                const SizedBox(height: 24),
                if (_hasBreakdown) ...[
                  _buildSubtasksList(),
                  const SizedBox(height: 24),
                  _buildScheduleButton(),
                  const SizedBox(height: 32),
                ],
              ],
            ),
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskHeader() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemGrey5.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            CategoryUtils.getCategoryColor(_task.category.name)
                                .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _task.category.name,
                        style: TextStyle(
                            color: CategoryUtils.getCategoryColor(
                                _task.category.name),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    Text('Priority: ${_task.priority}',
                        style:
                            const TextStyle(color: CupertinoColors.systemGrey)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(CupertinoIcons.time,
                        size: 14, color: CupertinoColors.systemGrey),
                    const SizedBox(width: 4),
                    Text('Est. time: ${_formatDuration(_task.estimatedTime)}',
                        style:
                            const TextStyle(color: CupertinoColors.systemGrey)),
                    const Spacer(),
                    const Icon(CupertinoIcons.calendar,
                        size: 14, color: CupertinoColors.systemGrey),
                    const SizedBox(width: 4),
                    Text(
                      DateTime.fromMillisecondsSinceEpoch(_task.deadline)
                          .toLocal()
                          .toString()
                          .split(' ')[0],
                      style: const TextStyle(color: CupertinoColors.systemGrey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildTaskDescription() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: CupertinoColors.systemGrey5.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Task Description',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _notesController,
              placeholder: 'Add notes about this task...',
              minLines: 3,
              maxLines: 5,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey5),
                  borderRadius: BorderRadius.circular(8)),
              onChanged: (value) {
                _task.notes = value.isEmpty ? null : value;
                _task.save();
              },
            ),
          ],
        ),
      );

  Widget _buildMagicButton() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemIndigo.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: CupertinoColors.systemIndigo.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.sparkles,
                size: 40, color: CupertinoColors.systemIndigo),
            const SizedBox(height: 12),
            const Text('Magic Task Breakdown',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.systemIndigo)),
            const SizedBox(height: 8),
            const Text(
                'Let AI analyze this task and break it down into manageable subtasks',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: CupertinoColors.systemGrey, fontSize: 14)),
            const SizedBox(height: 16),
            CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: const Text('Generate Subtasks'),
                onPressed: _generateTaskBreakdown),
          ],
        ),
      );

  Widget _buildSubtasksList() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: CupertinoColors.systemGrey5.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(CupertinoIcons.list_bullet,
                    size: 20, color: CupertinoColors.activeBlue),
                const SizedBox(width: 8),
                const Text('Generated Subtasks',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${_subtasks.length}',
                    style: const TextStyle(
                        color: CupertinoColors.systemGrey, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ..._subtasks.map(_buildSubtaskItem),
          ],
        ),
      );

  Widget _buildScheduleButton() => CupertinoButton.filled(
        onPressed: _scheduleSubtasks,
        child: const Text('Schedule All Subtasks'),
      );

  Widget _buildLoadingOverlay() => Container(
        color: CupertinoColors.systemBackground.withOpacity(0.7),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(radius: 20),
              const SizedBox(height: 16),
              Text(
                  _hasBreakdown
                      ? 'Scheduling tasks...'
                      : 'Breaking down task...',
                  style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
}
