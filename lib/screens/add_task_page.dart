import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/tasks_controller/task_manager_cubit.dart';
import '../design/cupertino_form_theme.dart';
import '../design/cupertino_form_widgets.dart';
import '../models/category.dart';
import '../screens/home_screen.dart';
import '../utils/logger.dart';

class AddTaskPage extends StatefulWidget {
  final DateTime? selectedDate;

  const AddTaskPage({super.key, this.selectedDate});

  @override
  AddTaskPageState createState() => AddTaskPageState();
}

class AddTaskPageState extends State<AddTaskPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _selectedDate;
  late DateTime _selectedTime;
  String _selectedCategory = 'Brainstorm';
  int _priority = 1;
  int? _selectedColor;
  int _estimatedTime = 0;
  final List<String> _categoryOptions = [
    'Brainstorm',
    'Design',
    'Workout',
    'Add',
  ];
  final List<Color> _colorOptions = [
    CupertinoColors.systemRed,
    CupertinoColors.systemOrange,
    CupertinoColors.systemYellow,
    CupertinoColors.systemGreen,
    CupertinoColors.systemBlue,
    CupertinoColors.systemPurple,
    CupertinoColors.systemGrey,
  ];

  late AnimationController _animationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _selectedTime = _selectedDate;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CupertinoFormTheme.horizontalSpacing),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CupertinoFormWidgets.formGroup(
                  title: 'Task Details',
                  children: [
                    CupertinoFormWidgets.textField(
                      controller: _titleController,
                      placeholder: 'Task Name *',
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: CupertinoFormTheme.elementSpacing),
                    CupertinoFormWidgets.textField(
                      controller: _notesController,
                      placeholder: 'Notes',
                      maxLines: 3,
                    ),
                  ],
                ),
                SizedBox(height: CupertinoFormTheme.sectionSpacing),
                CupertinoFormWidgets.formGroup(
                  title: 'Deadline',
                  children: [
                    CupertinoFormWidgets.selectionButton(
                      label: 'Date',
                      value: CupertinoFormTheme.formatDate(_selectedDate),
                      onTap: () => _showDatePicker(context),
                      color: CupertinoFormTheme.primaryColor,
                      icon: CupertinoIcons.calendar,
                    ),
                    SizedBox(height: CupertinoFormTheme.elementSpacing),
                    CupertinoFormWidgets.selectionButton(
                      label: 'Time',
                      value: CupertinoFormTheme.formatTime(_selectedTime),
                      onTap: () => _showTimePicker(context),
                      color: CupertinoFormTheme.secondaryColor,
                      icon: CupertinoIcons.time,
                    ),
                  ],
                ),
                SizedBox(height: CupertinoFormTheme.sectionSpacing),
                CupertinoFormWidgets.formGroup(
                  title: 'Estimated Time',
                  children: [
                    CupertinoFormWidgets.selectionButton(
                      label: 'Duration',
                      value:
                          '${(_estimatedTime ~/ 3600000).toString().padLeft(2, '0')}h ${((_estimatedTime % 3600000) ~/ 60000).toString().padLeft(2, '0')}m',
                      onTap: () async {
                        final duration =
                            await CupertinoFormWidgets.showDurationPicker(
                              context: context,
                              initialHours: _estimatedTime ~/ 3600000,
                              initialMinutes:
                                  (_estimatedTime % 3600000) ~/ 60000,
                            );
                        if (mounted) setState(() => _estimatedTime = duration);
                      },
                      color: CupertinoFormTheme.accentColor,
                      icon: CupertinoIcons.timer,
                    ),
                  ],
                ),
                SizedBox(height: CupertinoFormTheme.sectionSpacing),
                CupertinoFormWidgets.formGroup(
                  title: 'Category',
                  children: [
                    CupertinoFormWidgets.segmentedControl(
                      children: {
                        for (var item in _categoryOptions)
                          item: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: CupertinoFormTheme.smallSpacing,
                              vertical: CupertinoFormTheme.smallSpacing / 2,
                            ),
                            child: Text(item),
                          ),
                      },
                      groupValue: _selectedCategory,
                      onValueChanged: _handleCategoryChange,
                    ),
                  ],
                ),
                SizedBox(height: CupertinoFormTheme.sectionSpacing),
                CupertinoFormWidgets.formGroup(
                  title: 'Priority',
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Level: $_priority',
                          style: CupertinoFormTheme.labelTextStyle,
                        ),
                        Text(
                          _priority <= 3
                              ? 'Low'
                              : _priority <= 7
                              ? 'Medium'
                              : 'High',
                          style: CupertinoFormTheme.valueTextStyle.copyWith(
                            color: CupertinoFormTheme.getPriorityColor(
                              _priority,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: CupertinoFormTheme.smallSpacing),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoFormWidgets.prioritySlider(
                        value: _priority,
                        onChanged: (value) => setState(() => _priority = value),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: CupertinoFormTheme.sectionSpacing),
                CupertinoFormWidgets.formGroup(
                  title: 'Color',
                  children: [
                    Text(
                      'Select a color for your task',
                      style: CupertinoFormTheme.helperTextStyle,
                    ),
                    SizedBox(height: CupertinoFormTheme.smallSpacing),
                    CupertinoFormWidgets.colorPicker(
                      colors: _colorOptions,
                      selectedColor: _selectedColor,
                      onColorSelected:
                          (color) => setState(() => _selectedColor = color),
                    ),
                  ],
                ),
                SizedBox(height: CupertinoFormTheme.largeSpacing),
                ScaleTransition(
                  scale: _buttonScaleAnimation,
                  child: CupertinoFormWidgets.primaryButton(
                    text: 'Save Task',
                    onPressed: () {
                      _animationController.forward().then(
                        (_) => _animationController.reverse(),
                      );
                      _saveTask(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await CupertinoFormWidgets.showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      minimumDate: now,
    );
    if (pickedDate != null && mounted) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final now = DateTime.now();
    DateTime initialTime;
    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day &&
        _selectedTime.isBefore(now)) {
      initialTime = now;
    } else {
      initialTime = _selectedTime;
    }

    final pickedTime = await CupertinoFormWidgets.showTimePicker(
      context: context,
      initialTime: initialTime,
      minimumDate:
          _selectedDate.year == now.year &&
                  _selectedDate.month == now.month &&
                  _selectedDate.day == now.day
              ? now
              : null,
    );

    if (pickedTime != null && mounted) {
      setState(() => _selectedTime = pickedTime);
    }
  }

  void _handleCategoryChange(String value) {
    if (value == 'Add') {
      _showAddCategoryDialog(context);
    } else {
      setState(() => _selectedCategory = value);
    }
  }

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Add Custom Category'),
            content: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: CupertinoFormWidgets.textField(
                controller: controller,
                placeholder: 'Category Name',
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
                  final newCategory = controller.text.trim();
                  if (newCategory.isNotEmpty &&
                      mounted &&
                      !_categoryOptions.contains(newCategory)) {
                    setState(() {
                      _categoryOptions.insert(
                        _categoryOptions.length - 1,
                        newCategory,
                      );
                      _selectedCategory = newCategory;
                    });
                    logInfo('Custom category added: $newCategory');
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  void _saveTask(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Validation Error'),
              content: const Text('Please fill in all required fields.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
      return;
    }

    final selectedTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    context.read<TaskManagerCubit>().createTask(
      title: _titleController.text,
      priority: _priority,
      estimatedTime: _estimatedTime,
      deadline: selectedTime.millisecondsSinceEpoch,
      category: Category(name: _selectedCategory),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      color: _selectedColor,
    );

    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (_) => const HomeScreen(initialIndex: 1)),
    );
    logInfo('Saved Task: ${_titleController.text}');
  }
}
