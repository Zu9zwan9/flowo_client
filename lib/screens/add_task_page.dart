import 'package:flowo_client/screens/widgets/cupertino_task_form.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/tasks_controller/task_manager_cubit.dart';
import '../models/category.dart';
import '../models/task_form_data.dart';
import '../screens/home_screen.dart';
import '../utils/date_formatter.dart';
import '../utils/logger.dart';

class AddTaskPage extends StatefulWidget {
  final DateTime? selectedDate;

  const AddTaskPage({super.key, this.selectedDate});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage>
    with SingleTickerProviderStateMixin {
  // MARK: - Form data and controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  // Task data model
  late final TaskFormData _formData;

  // Animation for button feedback
  late final AnimationController _animationController;
  late final Animation<double> _buttonScaleAnimation;

  // Available task options
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

  @override
  void initState() {
    super.initState();

    // Initialize form data
    _formData = TaskFormData(
      selectedDate: widget.selectedDate ?? DateTime.now(),
      selectedTime: widget.selectedDate ?? DateTime.now(),
      category: 'Brainstorm',
      priority: 1,
      estimatedTime: 0,
    );

    // Setup button animation
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
    // Get form styling helper
    final form = CupertinoTaskForm(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('New Task'),
        backgroundColor: form.backgroundColor,
        border: null,
      ),
      backgroundColor: form.secondaryBackgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: CupertinoTaskForm.horizontalSpacing,
            vertical: CupertinoTaskForm.verticalSpacing,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task Details Section
                form.sectionTitle('Task Details'),
                form.formGroup(
                  children: [
                    form.textField(
                      controller: _titleController,
                      placeholder: 'Task Name *',
                      autofocus: true,
                      validator:
                          (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: CupertinoTaskForm.elementSpacing),
                    form.textField(
                      controller: _notesController,
                      placeholder: 'Notes',
                      maxLines: 3,
                    ),
                  ],
                ),

                const SizedBox(height: CupertinoTaskForm.sectionSpacing),

                // Deadline Section
                form.sectionTitle('Deadline'),
                form.formGroup(
                  children: [
                    form.selectionButton(
                      label: 'Date',
                      value: DateFormatter.formatDate(_formData.selectedDate),
                      onTap: () => _showDatePicker(context),
                      icon: CupertinoIcons.calendar,
                    ),
                    form.divider(),
                    form.selectionButton(
                      label: 'Time',
                      value: DateFormatter.formatTime(_formData.selectedTime),
                      onTap: () => _showTimePicker(context),
                      icon: CupertinoIcons.time,
                    ),
                  ],
                ),

                const SizedBox(height: CupertinoTaskForm.sectionSpacing),

                // Duration Section
                form.sectionTitle('Estimated Time'),
                form.formGroup(
                  children: [
                    form.selectionButton(
                      label: 'Duration',
                      value: _formatDuration(_formData.estimatedTime),
                      onTap: () => _showDurationPicker(context),
                      icon: CupertinoIcons.timer,
                    ),
                  ],
                ),

                const SizedBox(height: CupertinoTaskForm.sectionSpacing),

                // Category Section
                form.sectionTitle('Category'),
                form.formGroup(
                  children: [
                    form.segmentedControl(
                      children: {
                        for (var item in _categoryOptions)
                          item: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(item),
                          ),
                      },
                      groupValue: _formData.category,
                      onValueChanged: _handleCategoryChange,
                    ),
                  ],
                ),

                const SizedBox(height: CupertinoTaskForm.sectionSpacing),

                // Priority Section
                form.sectionTitle('Priority'),
                form.formGroup(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Level: ${_formData.priority}',
                          style: form.labelTextStyle(),
                        ),
                        Text(
                          _getPriorityLabel(_formData.priority),
                          style: form.valueTextStyle.copyWith(
                            color: _getPriorityColor(_formData.priority),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CupertinoTaskForm.elementSpacing),
                    form.prioritySlider(
                      value: _formData.priority.toDouble(),
                      onChanged:
                          (value) => setState(
                            () => _formData.priority = value.toInt(),
                          ),
                      getPriorityColor: (value) => _getPriorityColor(value),
                    ),
                  ],
                ),

                const SizedBox(height: CupertinoTaskForm.sectionSpacing),

                // Color Section
                form.sectionTitle('Color'),
                form.formGroup(
                  children: [
                    form.helperText('Select a color for your task'),
                    const SizedBox(height: CupertinoTaskForm.elementSpacing),
                    form.colorSelector(
                      colors: _colorOptions,
                      selectedColorValue: _formData.color,
                      onColorSelected:
                          (color) => setState(() => _formData.color = color),
                    ),
                  ],
                ),

                const SizedBox(height: CupertinoTaskForm.sectionSpacing * 2),

                // Save Button
                Center(
                  child: ScaleTransition(
                    scale: _buttonScaleAnimation,
                    child: form.primaryButton(
                      text: 'Save Task',
                      onPressed: () => _saveTaskWithAnimation(context),
                    ),
                  ),
                ),

                const SizedBox(height: CupertinoTaskForm.verticalSpacing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // MARK: - UI Helpers

  String _formatDuration(int milliseconds) {
    final hours = milliseconds ~/ 3600000;
    final minutes = (milliseconds % 3600000) ~/ 60000;
    return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m';
  }

  String _getPriorityLabel(int priority) {
    if (priority <= 3) return 'Low';
    if (priority <= 7) return 'Medium';
    return 'High';
  }

  Color _getPriorityColor(int priority) {
    if (priority <= 3) {
      return CupertinoColors.systemBlue.resolveFrom(context);
    } else if (priority <= 7) {
      return CupertinoColors.systemOrange.resolveFrom(context);
    } else {
      return CupertinoColors.systemRed.resolveFrom(context);
    }
  }

  // MARK: - Action Methods

  void _saveTaskWithAnimation(BuildContext context) {
    // Play button animation
    _animationController.forward().then((_) => _animationController.reverse());

    // Execute save operation
    _saveTask(context);
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();

    // Show the date picker
    final pickedDate = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder:
          (context) => _buildDatePickerModal(
            context: context,
            initialDate:
                _formData.selectedDate.isBefore(now)
                    ? now
                    : _formData.selectedDate,
            minimumDate: now,
          ),
    );

    // Update state if a date was picked
    if (pickedDate != null && mounted) {
      setState(() => _formData.selectedDate = pickedDate);
    }
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final now = DateTime.now();

    // Determine the initial time to show
    DateTime initialTime;
    bool isSameDay = _isSameDay(_formData.selectedDate, now);

    if (isSameDay && _formData.selectedTime.isBefore(now)) {
      initialTime = now;
    } else {
      initialTime = _formData.selectedTime;
    }

    // Show the time picker
    final pickedTime = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder:
          (context) => _buildTimePickerModal(
            context: context,
            initialTime: initialTime,
            minimumTime: isSameDay ? now : null,
          ),
    );

    // Update state if a time was picked
    if (pickedTime != null && mounted) {
      setState(() => _formData.selectedTime = pickedTime);
    }
  }

  Future<void> _showDurationPicker(BuildContext context) async {
    // Show the duration picker
    final duration = await showCupertinoModalPopup<int>(
      context: context,
      builder:
          (context) => _buildDurationPickerModal(
            context: context,
            initialHours: _formData.estimatedTime ~/ 3600000,
            initialMinutes: (_formData.estimatedTime % 3600000) ~/ 60000,
          ),
    );

    // Update state if a duration was picked
    if (duration != null && mounted) {
      setState(() => _formData.estimatedTime = duration);
    }
  }

  void _handleCategoryChange(String value) {
    if (value == 'Add') {
      _showAddCategoryDialog(context);
    } else {
      setState(() => _formData.category = value);
    }
  }

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    final form = CupertinoTaskForm(context);

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Add Custom Category'),
            content: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: CupertinoTextField(
                controller: controller,
                placeholder: 'Category Name',
                padding: const EdgeInsets.all(10),
                decoration: form.inputDecoration,
                style: form.inputTextStyle,
                autofocus: true,
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
                  _addNewCategory(controller.text.trim());
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  void _addNewCategory(String newCategory) {
    if (newCategory.isNotEmpty &&
        mounted &&
        !_categoryOptions.contains(newCategory)) {
      setState(() {
        _categoryOptions.insert(_categoryOptions.length - 1, newCategory);
        _formData.category = newCategory;
      });
      logInfo('Custom category added: $newCategory');
    }
  }

  void _saveTask(BuildContext context) {
    // Validate the form
    if (!_formKey.currentState!.validate()) {
      _showValidationError(context);
      return;
    }

    // Combine date and time
    final selectedDateTime = DateTime(
      _formData.selectedDate.year,
      _formData.selectedDate.month,
      _formData.selectedDate.day,
      _formData.selectedTime.hour,
      _formData.selectedTime.minute,
    );

    // Create the task via BLoC
    context.read<TaskManagerCubit>().createTask(
      title: _titleController.text,
      priority: _formData.priority,
      estimatedTime: _formData.estimatedTime,
      deadline: selectedDateTime.millisecondsSinceEpoch,
      category: Category(name: _formData.category),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      color: _formData.color,
    );

    // Log and navigate
    logInfo('Saved Task: ${_titleController.text}');
    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (_) => const HomeScreen(initialIndex: 1)),
    );
  }

  void _showValidationError(BuildContext context) {
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
  }

  // MARK: - Helper methods

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // MARK: - Modal Builders

  Widget _buildDatePickerModal({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime minimumDate,
  }) {
    DateTime? selectedDate = initialDate;

    return Container(
      height: 300,
      color: CupertinoTheme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoButton(
                child: const Text('Done'),
                onPressed: () => Navigator.pop(context, selectedDate),
              ),
            ],
          ),
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: initialDate,
              minimumDate: minimumDate,
              maximumDate: DateTime.now().add(const Duration(days: 365)),
              onDateTimeChanged: (date) => selectedDate = date,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerModal({
    required BuildContext context,
    required DateTime initialTime,
    DateTime? minimumTime,
  }) {
    DateTime? selectedTime = initialTime;

    return Container(
      height: 300,
      color: CupertinoTheme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoButton(
                child: const Text('Done'),
                onPressed: () => Navigator.pop(context, selectedTime),
              ),
            ],
          ),
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: initialTime,
              minimumDate: minimumTime,
              use24hFormat: true,
              minuteInterval: 5,
              onDateTimeChanged: (time) => selectedTime = time,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationPickerModal({
    required BuildContext context,
    required int initialHours,
    required int initialMinutes,
  }) {
    int hours = initialHours;
    int minutes = initialMinutes;

    return Container(
      height: 300,
      color: CupertinoTheme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoButton(
                child: const Text('Done'),
                onPressed:
                    () => Navigator.pop(
                      context,
                      hours * 3600000 + minutes * 60000,
                    ),
              ),
            ],
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(
                      initialItem: initialHours,
                    ),
                    onSelectedItemChanged: (index) => hours = index,
                    children: [for (var i = 0; i <= 120; i++) Text('$i hours')],
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(
                      initialItem: initialMinutes ~/ 15,
                    ),
                    onSelectedItemChanged: (index) => minutes = index * 15,
                    children: [
                      for (var i = 0; i < 4; i++) Text('${i * 15} minutes'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
