import 'package:flutter/cupertino.dart';
import '../models/category.dart';
import '../models/task.dart';

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
  DateTime _startTime = DateTime.now();
  DateTime? _endTime;

  String _selectedCategory = 'Brainstorm';
  String _urgency = 'Low';
  String _priority = 'Normal';

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();

    // If a task was passed in, populate its fields.
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.notes ?? '';
      _selectedDate = DateTime.fromMillisecondsSinceEpoch(widget.task!.deadline);
      _startTime = DateTime.fromMillisecondsSinceEpoch(widget.task!.deadline);
      _endTime = DateTime.fromMillisecondsSinceEpoch(
        widget.task!.deadline + widget.task!.estimatedTime,
      );
      _selectedCategory = widget.task!.category.name;
    }
  }

  /// Helper to convert priority selection to int if needed.
  int _mapPriorityToInt(String priority) {
    switch (priority) {
      case 'Low':
        return 0;
      case 'High':
        return 2;
      default:
        return 1; // 'Normal'
    }
  }

  /// Format a DateTime to "HH:MM:SS" or sets it to "Not set" if null.
  String _formatTime(DateTime? time) {
    if (time == null) return 'Not set';
    return time.toString().split(' ')[1].split('.')[0];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Dismiss keyboard on tapping outside the inputs.
      onTap: () => FocusScope.of(context).unfocus(),
      child: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Add Task'),
          backgroundColor: CupertinoColors.systemGrey.withOpacity(0.5),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              autovalidateMode: AutovalidateMode.always,
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task Info',
                    style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
                  ),
                  const SizedBox(height: 16.0),
                  CupertinoTextFormFieldRow(
                    controller: _titleController,
                    placeholder: 'Task name *',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a task name';
                      }
                      return null;
                    },
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.systemGrey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  CupertinoButton(
                    color: CupertinoColors.activeBlue,
                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                    onPressed: () async {
                      await showCupertinoModalPopup(
                        context: context,
                        builder: (context) {
                          return Container(
                            height: 250,
                            color: CupertinoColors.systemBackground,
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 200,
                                    child: CupertinoDatePicker(
                                      mode: CupertinoDatePickerMode.date,
                                      initialDateTime: _selectedDate,
                                      onDateTimeChanged: (val) {
                                        setState(() {
                                          _selectedDate = val;
                                        });
                                      },
                                    ),
                                  ),
                                  CupertinoButton(
                                    child: const Text('OK'),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Date: ${_selectedDate.toString().split(' ')[0]}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  CupertinoButton(
                    color: CupertinoColors.activeGreen,
                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                    onPressed: () async {
                      await showCupertinoModalPopup(
                        context: context,
                        builder: (context) {
                          return Container(
                            height: 250,
                            color: CupertinoColors.systemBackground,
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 200,
                                    child: CupertinoTimerPicker(
                                      mode: CupertinoTimerPickerMode.hm,
                                      initialTimerDuration: Duration(
                                        hours: _startTime.hour,
                                        minutes: _startTime.minute,
                                      ),
                                      onTimerDurationChanged: (duration) {
                                        setState(() {
                                          _startTime = DateTime(
                                            _selectedDate.year,
                                            _selectedDate.month,
                                            _selectedDate.day,
                                            duration.inHours,
                                            duration.inMinutes % 60,
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                  CupertinoButton(
                                    child: const Text('OK'),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Start Time: ${_formatTime(_startTime)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  CupertinoButton(
                    color: CupertinoColors.activeOrange,
                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                    onPressed: () async {
                      await showCupertinoModalPopup(
                        context: context,
                        builder: (context) {
                          return Container(
                            height: 250,
                            color: CupertinoColors.systemBackground,
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 200,
                                    child: CupertinoTimerPicker(
                                      mode: CupertinoTimerPickerMode.hm,
                                      initialTimerDuration: Duration(
                                        hours: _endTime?.hour ?? _startTime.hour,
                                        minutes: _endTime?.minute ?? _startTime.minute,
                                      ),
                                      onTimerDurationChanged: (duration) {
                                        setState(() {
                                          _endTime = DateTime(
                                            _selectedDate.year,
                                            _selectedDate.month,
                                            _selectedDate.day,
                                            duration.inHours,
                                            duration.inMinutes % 60,
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                  CupertinoButton(
                                    child: const Text('OK'),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'End Time: ${_formatTime(_endTime)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Select Category',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  CupertinoSegmentedControl<String>(
                    children: const {
                      'Brainstorm': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('Brainstorm', style: TextStyle(fontSize: 14)),
                      ),
                      'Design': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('Design', style: TextStyle(fontSize: 14)),
                      ),
                      'Workout': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('Workout', style: TextStyle(fontSize: 14)),
                      ),
                      'Add Category': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('Add Category', style: TextStyle(fontSize: 14)),
                      ),
                    },
                    groupValue: _selectedCategory,
                    onValueChanged: (String value) {
                      if (value == 'Add Category') {
                        _showAddCategoryDialog(context);
                      } else {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },

                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Select Urgency',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  CupertinoSegmentedControl<String>(
                    children: const {
                      'Low': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('Low', style: TextStyle(fontSize: 14)),
                      ),
                      'Medium': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('Medium', style: TextStyle(fontSize: 14)),
                      ),
                      'High': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('High', style: TextStyle(fontSize: 14)),
                      ),
                    },
                    groupValue: _urgency,
                    onValueChanged: (String value) {
                      setState(() {
                        _urgency = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16.0),
                  const Text(
                    'Select Priority',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  CupertinoSegmentedControl<String>(
                    children: const {
                      'Low': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('Low', style: TextStyle(fontSize: 14)),
                      ),
                      'Normal': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('Normal', style: TextStyle(fontSize: 14)),
                      ),
                      'High': Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('High', style: TextStyle(fontSize: 14)),
                      ),
                    },
                    groupValue: _priority,
                    onValueChanged: (String value) {
                      setState(() {
                        _priority = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24.0),
                  Center(
                    child: CupertinoButton.filled(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final startTime = DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day,
                            _startTime.hour,
                            _startTime.minute,
                          );
                          final endTime = _endTime != null
                              ? DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day,
                            _endTime!.hour,
                            _endTime!.minute,
                          )
                              : startTime.add(const Duration(minutes: 1));

                          if (endTime.isBefore(startTime)) {
                            showCupertinoDialog(
                              context: context,
                              builder: (context) {
                                return CupertinoAlertDialog(
                                  title: const Text('Invalid Time'),
                                  content: const Text('End time must be after start time'),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text('OK'),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                  ],
                                );
                              },
                            );
                            return;
                          }

                          final task = Task(
                            id: UniqueKey().toString(),
                            title: _titleController.text,
                            notes: _descriptionController.text.isEmpty
                                ? null
                                : _descriptionController.text,
                            deadline: startTime.millisecondsSinceEpoch,
                            estimatedTime: endTime.difference(startTime).inMilliseconds,
                            category: Category(name: _selectedCategory),
                            priority: _mapPriorityToInt(_priority),
                            subtasks: [],
                            scheduledTasks: [],
                            isDone: false,
                            overdue: false,
                          );
                          Navigator.pop(context, task);
                        }
                      },
                      child: const Text('Save Task'),
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

  void _showAddCategoryDialog(BuildContext context) {
    final categoryController = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Add Category'),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: CupertinoTextField(
              controller: categoryController,
              placeholder: 'Category name',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                setState(() {
                  if (categoryController.text.isNotEmpty) {
                    _selectedCategory = categoryController.text;
                  }
                });
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
