import 'package:flowo_client/screens/widgets/cupertino_task_form.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../blocs/tasks_controller/task_manager_cubit.dart';
import '../../models/category.dart';
import '../../models/task_form_data.dart';
import '../../services/category_service.dart';
import '../../utils/formatter/date_formatter.dart';
import '../../utils/logger.dart';
import '../home_screen.dart';

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

  // Hive box for storing categories
  late final Box<List<dynamic>> _categoriesBox;

  // Animation for button feedback
  late final AnimationController _animationController;
  late final Animation<double> _buttonScaleAnimation;

  // Available task options
  String _selectedCategory = '';
  List<String> _categoryOptions = [];
  final CategoryService _categoryService = CategoryService();

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

    // Open Hive box for categories
    _categoriesBox = Hive.box<List<dynamic>>('categories_box');

    // Initialize form data
    _formData = TaskFormData(
      selectedDate: widget.selectedDate ?? DateTime.now(),
      selectedTime: widget.selectedDate ?? DateTime.now(),
      category: '',
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

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _categoryService.getCategories();
    setState(() {
      _categoryOptions = categories;
      if (_categoryOptions.isNotEmpty && _selectedCategory.isEmpty) {
        _selectedCategory = _categoryOptions[0];
      }
    });
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
    final form = CupertinoTaskForm(context);
    return CupertinoPageScaffold(
      backgroundColor: form.backgroundColor,
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
                      label: 'Optimistic Time',
                      value: _formatDuration(_formData.optimisticTime),
                      onTap: () => _showDurationPicker(context, 'optimistic'),
                      icon: CupertinoIcons.timer,
                    ),
                    form.divider(),
                    form.selectionButton(
                      label: 'Realistic Time',
                      value: _formatDuration(_formData.realisticTime),
                      onTap: () => _showDurationPicker(context, 'realistic'),
                      icon: CupertinoIcons.timer,
                    ),
                    form.divider(),
                    form.selectionButton(
                      label: 'Pessimistic Time',
                      value: _formatDuration(_formData.pessimisticTime),
                      onTap: () => _showDurationPicker(context, 'pessimistic'),
                      icon: CupertinoIcons.timer,
                    ),
                    form.divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Expected Time:', style: form.labelTextStyle()),
                        Text(
                          _formatDuration(_formData.estimatedTime),
                          style: form.valueTextStyle,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: CupertinoTaskForm.sectionSpacing),

                // Category Section
                form.sectionTitle('Category'),
                Center(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: CupertinoTheme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    onPressed: () => _showCategoryManagerDialog(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.settings, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Manage Categories',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: CupertinoTaskForm.elementSpacing),

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
                      onChanged: (value) {
                        setState(() {
                          _formData.priority = value.round();
                        });
                      },
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

  Future<void> _showDurationPicker(
    BuildContext context,
    String timeType,
  ) async {
    // Determine which time estimate to update
    int initialHours = 0;
    int initialMinutes = 0;

    switch (timeType) {
      case 'optimistic':
        initialHours = _formData.optimisticTime ~/ 3600000;
        initialMinutes = (_formData.optimisticTime % 3600000) ~/ 60000;
        break;
      case 'realistic':
        initialHours = _formData.realisticTime ~/ 3600000;
        initialMinutes = (_formData.realisticTime % 3600000) ~/ 60000;
        break;
      case 'pessimistic':
        initialHours = _formData.pessimisticTime ~/ 3600000;
        initialMinutes = (_formData.pessimisticTime % 3600000) ~/ 60000;
        break;
      default:
        initialHours = _formData.estimatedTime ~/ 3600000;
        initialMinutes = (_formData.estimatedTime % 3600000) ~/ 60000;
    }

    // Show the duration picker
    final duration = await showCupertinoModalPopup<int>(
      context: context,
      builder:
          (context) => _buildDurationPickerModal(
            context: context,
            initialHours: initialHours,
            initialMinutes: initialMinutes,
          ),
    );

    // Update state if a duration was picked
    if (duration != null && mounted) {
      setState(() {
        switch (timeType) {
          case 'optimistic':
            _formData.optimisticTime = duration;
            break;
          case 'realistic':
            _formData.realisticTime = duration;
            break;
          case 'pessimistic':
            _formData.pessimisticTime = duration;
            break;
          default:
            _formData.estimatedTime = duration;
        }

        // Calculate the estimated time using the PERT formula
        _formData.calculateEstimatedTime();
      });
    }
  }

  void _showCategoryManagerDialog(BuildContext context) {
    String tempSelectedCategory = _selectedCategory;

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => CupertinoActionSheet(
                  title: const Text('Manage Categories'),
                  message: const Text(
                    'Select, add, edit, or delete categories',
                  ),
                  actions: [
                    ...List.generate(_categoryOptions.length, (index) {
                      final category = _categoryOptions[index];
                      final isSelected = tempSelectedCategory == category;
                      return CupertinoActionSheetAction(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setDialogState(() {
                            tempSelectedCategory = category;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          color:
                              isSelected
                                  ? CupertinoTheme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1)
                                  : CupertinoColors.transparent,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getCategoryIcon(category),
                                    size: 16.0,
                                    color:
                                        isSelected
                                            ? CupertinoTheme.of(
                                              context,
                                            ).primaryColor
                                            : CupertinoColors.systemGrey,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      color:
                                          isSelected
                                              ? CupertinoTheme.of(
                                                context,
                                              ).primaryColor
                                              : CupertinoTheme.of(
                                                    context,
                                                  ).brightness ==
                                                  Brightness.dark
                                              ? CupertinoColors.white
                                              : CupertinoColors.black,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    child: const Icon(
                                      CupertinoIcons.pencil,
                                      size: 16.0,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showEditCategoryDialog(
                                        context,
                                        category,
                                        index,
                                      );
                                    },
                                  ),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    child: const Icon(
                                      CupertinoIcons.delete,
                                      size: 16.0,
                                      color: CupertinoColors.destructiveRed,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showDeleteConfirmation(
                                        context,
                                        category,
                                        index,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    CupertinoActionSheetAction(
                      isDefaultAction: true,
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddCategoryDialog(context);
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.add_circled, size: 16.0),
                          SizedBox(width: 10),
                          Text(
                            'Add New Category',
                            style: TextStyle(fontSize: 14.0),
                          ),
                        ],
                      ),
                    ),
                  ],
                  cancelButton: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CupertinoActionSheetAction(
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 14.0),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      CupertinoActionSheetAction(
                        isDefaultAction: true,
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: CupertinoColors.activeBlue,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            if (_categoryOptions.isNotEmpty) {
                              _selectedCategory = tempSelectedCategory;
                            }
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _showEditCategoryDialog(
    BuildContext context,
    String category,
    int index,
  ) {
    final controller = TextEditingController(text: category);
    final theme = CupertinoTaskForm(context);
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text('Edit "$category"'),
            content: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: CupertinoTextField(
                controller: controller,
                padding: const EdgeInsets.all(10),
                decoration: theme.inputDecoration,
                style: const TextStyle(fontSize: 16.0),
                autofocus: true,
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel', style: TextStyle(fontSize: 14.0)),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Save', style: TextStyle(fontSize: 14.0)),
                onPressed: () async {
                  final newCategoryName = controller.text.trim();
                  if (newCategoryName.isNotEmpty &&
                      mounted &&
                      !_categoryOptions.contains(newCategoryName)) {
                    await _categoryService.updateCategory(
                      category,
                      newCategoryName,
                    );
                    setState(() {
                      _categoryOptions[index] = newCategoryName;
                      if (_selectedCategory == category) {
                        _selectedCategory = newCategoryName;
                      }
                      logInfo(
                        'Category renamed: $category -> $newCategoryName',
                      );
                    });
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String category,
    int index,
  ) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text('Delete "$category"?'),
            content: const Text(
              'This will remove the category from your list. Tasks with this category will not be affected.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel', style: TextStyle(fontSize: 14.0)),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text('Delete', style: TextStyle(fontSize: 14.0)),
                onPressed: () {
                  _deleteCategory(index);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
    );
  }

  void _deleteCategory(int index) async {
    final deletedCategory = _categoryOptions[index];
    await _categoryService.deleteCategory(deletedCategory);
    setState(() {
      _categoryOptions.removeAt(index);
      if (_selectedCategory == deletedCategory) {
        _selectedCategory =
            _categoryOptions.isNotEmpty ? _categoryOptions[0] : '';
      }
      logInfo('Category deleted: $deletedCategory');
    });
  }

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    final theme = CupertinoTaskForm(context);
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
                decoration: theme.inputDecoration,
                style: const TextStyle(fontSize: 16.0),
                autofocus: true,
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel', style: TextStyle(fontSize: 14.0)),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Add', style: TextStyle(fontSize: 14.0)),
                onPressed: () async {
                  final newCategory = controller.text.trim();
                  if (newCategory.isNotEmpty &&
                      mounted &&
                      !_categoryOptions.contains(newCategory)) {
                    await _categoryService.addCategory(newCategory);
                    setState(() {
                      _categoryOptions.add(newCategory);
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

  IconData _getCategoryIcon(String category) {
    final Map<String, IconData> icons = {
      'Brainstorm': CupertinoIcons.lightbulb,
      'Design': CupertinoIcons.pencil_outline,
      'Workout': CupertinoIcons.heart,
    };
    return icons[category] ?? CupertinoIcons.tag;
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
                  child: const Text('OK', style: TextStyle(fontSize: 14.0)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
      return;
    }

    if (_categoryOptions.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('No Categories'),
              content: const Text(
                'Please add a category before saving the task.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Cancel', style: TextStyle(fontSize: 14.0)),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text(
                    'Add Category',
                    style: TextStyle(fontSize: 14.0),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddCategoryDialog(context);
                  },
                ),
              ],
            ),
      );
      return;
    }

    if (_selectedCategory.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Validation Error'),
              content: const Text('Please select a category.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK', style: TextStyle(fontSize: 14.0)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
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
      category: Category(name: _selectedCategory),
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
