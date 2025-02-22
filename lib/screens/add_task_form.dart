import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowo_client/blocs/calendar/calendar_cubit.dart';
import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/models/task.dart';

import 'calendar_screen.dart';

class AddTaskForm extends StatefulWidget {
  final DateTime? selectedDate;
  final Task? task;

  const AddTaskForm({super.key, this.selectedDate, this.task});

  @override
  AddTaskFormState createState() => AddTaskFormState();
}

class AddTaskFormState extends State<AddTaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late DateTime _selectedDate;
  late DateTime _startTime;
  DateTime? _endTime;
  String _selectedCategory = 'Brainstorm';
  String _urgency = 'Low';
  String _priority = 'Normal';

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _startTime = _selectedDate;

    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.notes ?? '';
      _selectedDate =
          DateTime.fromMillisecondsSinceEpoch(widget.task!.deadline);
      _startTime = DateTime.fromMillisecondsSinceEpoch(widget.task!.deadline);
      _endTime = DateTime.fromMillisecondsSinceEpoch(
        widget.task!.deadline + widget.task!.estimatedTime,
      );
      _selectedCategory = widget.task!.category.name;
      _priority = _intToPriority(widget.task!.priority);
      // _urgency = _intToPriority(widget.task!.urgency);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _intToPriority(int priority) {
    switch (priority) {
      case 0:
        return 'Low';
      case 2:
        return 'High';
      default:
        return 'Normal';
    }
  }

  int _mapPriorityToInt(String priority) {
    switch (priority) {
      case 'Low':
        return 0;
      case 'High':
        return 2;
      default:
        return 1;
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
  String _formatTime(DateTime? time) => time != null
      ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
      : 'Not set';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('New Task'),
          backgroundColor: CupertinoColors.systemBackground,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Task Details'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _titleController,
                    placeholder: 'Task Name *',
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Timing'),
                  const SizedBox(height: 12),
                  _buildDateButton(context),
                  const SizedBox(height: 12),
                  _buildTimeButton(context, isStart: true),
                  const SizedBox(height: 12),
                  _buildTimeButton(context, isStart: false),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Category'),
                  const SizedBox(height: 12),
                  _buildSegmentedControl(
                    options: const ['Brainstorm', 'Design', 'Workout', 'Add'],
                    value: _selectedCategory,
                    onChanged: (value) => value == 'Add'
                        ? _showAddCategoryDialog(context)
                        : setState(() => _selectedCategory = value),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Urgency'),
                  const SizedBox(height: 12),
                  _buildSegmentedControl(
                    options: const ['Low', 'Medium', 'High'],
                    value: _urgency,
                    onChanged: (value) => setState(() => _urgency = value),
                    selectedColor: CupertinoColors.systemRed,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Priority'),
                  const SizedBox(height: 12),
                  _buildSegmentedControl(
                    options: const ['Low', 'Normal', 'High'],
                    value: _priority,
                    onChanged: (value) => setState(() => _priority = value),
                    selectedColor: CupertinoColors.systemOrange,
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      onPressed: _saveTask,
                      child: const Text(
                        'Save Task',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      maxLines: maxLines,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CupertinoColors.systemGrey4),
      ),
      style: const TextStyle(fontSize: 16),
      placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey2),
    );
  }

  Widget _buildDateButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDatePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Date',
              style: TextStyle(fontSize: 16, color: CupertinoColors.systemBlue),
            ),
            Text(
              _formatDate(_selectedDate),
              style:
                  const TextStyle(fontSize: 16, color: CupertinoColors.label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton(BuildContext context, {required bool isStart}) {
    return GestureDetector(
      onTap: () => _showTimePicker(context, isStart: isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: (isStart
                  ? CupertinoColors.systemGreen
                  : CupertinoColors.systemOrange)
              .withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isStart ? 'Start Time' : 'End Time',
              style: TextStyle(
                fontSize: 16,
                color: isStart
                    ? CupertinoColors.systemGreen
                    : CupertinoColors.systemOrange,
              ),
            ),
            Text(
              _formatTime(isStart ? _startTime : _endTime),
              style:
                  const TextStyle(fontSize: 16, color: CupertinoColors.label),
            ),
          ],
        ),
      ),
    );
  }
// lib/screens/add_task_form.dart

  Widget _buildSegmentedControl({
    required List<String> options,
    required String value,
    required ValueChanged<String> onChanged,
    Color selectedColor = CupertinoColors.activeBlue,
  }) {
    return CupertinoSegmentedControl<String>(
      children: {
        for (var item in options)
          item: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Text(
              item,
              style: const TextStyle(fontSize: 14.0),
            ),
          )
      },
      groupValue: value,
      onValueChanged: onChanged,
      borderColor: CupertinoColors.systemGrey4,
      selectedColor: selectedColor,
      unselectedColor: CupertinoColors.systemGrey6,
      pressedColor: selectedColor.withOpacity(0.2),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    DateTime? pickedDate;
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                onDateTimeChanged: (val) => pickedDate = val,
              ),
            ),
            _buildPickerActions(context),
          ],
        ),
      ),
    );
    if (pickedDate != null && mounted) {
      setState(() => _selectedDate = pickedDate!);
    }
  }

  Future<void> _showTimePicker(BuildContext context,
      {required bool isStart}) async {
    Duration? pickedDuration;
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: CupertinoTimerPicker(
                mode: CupertinoTimerPickerMode.hm,
                initialTimerDuration: Duration(
                  hours: (isStart ? _startTime : _endTime ?? _startTime).hour,
                  minutes:
                      (isStart ? _startTime : _endTime ?? _startTime).minute,
                ),
                onTimerDurationChanged: (duration) => pickedDuration = duration,
              ),
            ),
            _buildPickerActions(context),
          ],
        ),
      ),
    );
    if (pickedDuration != null && mounted) {
      setState(() {
        final time = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          pickedDuration!.inHours,
          pickedDuration!.inMinutes % 60,
        );
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  Widget _buildPickerActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CupertinoButton(
          child: const Text('Cancel',
              style: TextStyle(color: CupertinoColors.systemGrey)),
          onPressed: () => Navigator.pop(context),
        ),
        CupertinoButton(
          child:
              const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Add Category'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Category Name',
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Add'),
            onPressed: () {
              if (controller.text.isNotEmpty && mounted) {
                setState(() => _selectedCategory = controller.text);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final startTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final endTime = _endTime != null
          ? DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day,
              _endTime!.hour, _endTime!.minute)
          : startTime.add(const Duration(minutes: 30));

      if (endTime.isBefore(startTime)) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Invalid Time'),
            content: const Text('End time must be after start time.'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
        return;
      }

      final task = Task(
        id: widget.task?.id ?? UniqueKey().toString(),
        title: _titleController.text,
        notes: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        deadline: startTime.millisecondsSinceEpoch,
        estimatedTime: endTime.difference(startTime).inMilliseconds,
        category: Category(name: _selectedCategory),
        priority: _mapPriorityToInt(_priority),
        subtasks: widget.task?.subtasks ?? [],
        scheduledTasks: widget.task?.scheduledTasks ?? [],
        isDone: widget.task?.isDone ?? false,
        overdue: widget.task?.overdue ?? false,
      );

      final cubit = context.read<CalendarCubit>();
      widget.task != null ? cubit.updateTask(task) : cubit.addTask(task);
      Navigator.pushReplacement(
          context, CupertinoPageRoute(builder: (_) => const CalendarScreen()));
    }
  }
}
