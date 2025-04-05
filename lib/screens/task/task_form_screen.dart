import 'package:flowo_client/screens/widgets/cupertino_task_form.dart';
import 'package:flowo_client/utils/formatter/date_time_formatter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../blocs/tasks_controller/task_manager_cubit.dart';
import '../../models/category.dart';
import '../../models/task.dart';
import '../../models/task_form_data.dart';
import '../../models/user_settings.dart';
import '../../services/category_service.dart';
import '../../utils/logger.dart';
import '../home_screen.dart';

class TaskFormScreen extends StatefulWidget {
  final DateTime? selectedDate;
  final Task? task;

  const TaskFormScreen({super.key, this.selectedDate, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen>
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

  late UserSettings _userSettings;

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

    _userSettings = context.read<TaskManagerCubit>().taskManager.userSettings;
    _categoriesBox = Hive.box<List<dynamic>>('categories_box');

    if (widget.task != null) {
      _formData = TaskFormData.fromTask(widget.task!);
      _titleController.text = widget.task!.title;
      _notesController.text = widget.task!.notes ?? '';
      _selectedCategory = widget.task!.category.name;
    } else {
      _formData = TaskFormData(
        selectedDateTime:
            widget.selectedDate ?? _roundToNearestFiveMinutes(DateTime.now()),
        category: '',
        priority: 1,
        estimatedTime: 0,
        optimisticTime: 0,
        realisticTime: 0,
        pessimisticTime: 0,
      );
    }

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
      navigationBar:
          widget.task != null
              ? CupertinoNavigationBar(middle: Text('Edit Task'))
              : Navigator.canPop(context)
              ? CupertinoNavigationBar(middle: Text('Create Task'))
              : null,
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
                      label: 'Date & Time',
                      value: DateTimeFormatter.formatDateTime(
                        _formData.selectedDateTime,
                        dateFormat: _userSettings.dateFormat,
                        monthFormat: _userSettings.monthFormat,
                        is24HourFormat: _userSettings.is24HourFormat,
                      ),
                      onTap: () => _showDateTimePicker(context),
                      icon: CupertinoIcons.calendar,
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
                form.sectionTitle('Category'),
                form.formGroup(
                  children: [
                    form.selectionButton(
                      label: 'Category',
                      value:
                          _categoryOptions.isEmpty
                              ? 'Add a category'
                              : _selectedCategory,
                      onTap: () => _showCategoryManagerDialog(context),
                      icon: CupertinoIcons.tag,
                      color: CupertinoTheme.of(context).primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: CupertinoTaskForm.sectionSpacing),

                const SizedBox(height: CupertinoTaskForm.sectionSpacing),
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

  Future<void> _showDateTimePicker(BuildContext context) async {
    final now = _roundToNearestFiveMinutes(DateTime.now());
    final initialDateTime =
        _formData.selectedDateTime.isBefore(now)
            ? now
            : _formData.selectedDateTime;

    final pickedDateTime = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            color: CupertinoTheme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context, initialDateTime),
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime,
                    initialDateTime: initialDateTime,
                    minimumDate: now,
                    maximumDate: DateTime.now().add(const Duration(days: 365)),
                    minuteInterval: 5,
                    use24hFormat: _userSettings.is24HourFormat,
                    onDateTimeChanged: (dateTime) {
                      if (mounted) {
                        setState(() {
                          _formData.selectedDateTime = dateTime;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
    );

    if (pickedDateTime != null && mounted) {
      setState(() {
        _formData.selectedDateTime = pickedDateTime;

        final dateError = _validateForm();
        if (dateError != null && dateError.contains('Deadline')) {
          showCupertinoDialog(
            context: context,
            builder:
                (context) => CupertinoAlertDialog(
                  title: const Text('Date Error'),
                  content: Text(dateError),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('OK'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
          );
          _formData.selectedDateTime = _roundToNearestFiveMinutes(
            DateTime.now(),
          );
        }
      });
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
        }
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

  String? _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      return 'Task name is required';
    }

    if (_categoryOptions.isEmpty || _selectedCategory.isEmpty) {
      return 'Please select or add a category';
    }

    if (_formData.optimisticTime > _formData.realisticTime) {
      return 'Optimistic time should not exceed realistic time';
    }
    if (_formData.realisticTime > _formData.pessimisticTime) {
      return 'Realistic time should not exceed pessimistic time';
    }
    if (_formData.optimisticTime <= 0) {
      return 'Optimistic time must be greater than zero';
    }

    final now = DateTime.now();
    if (_formData.selectedDateTime.isBefore(now)) {
      return 'Deadline cannot be in the past';
    }

    if (_formData.selectedDateTime.difference(now).inMilliseconds < _formData.estimatedTime) {
      return 'Deadline is too close to accommodate the estimated time';
    }

    return null;
  }

  void _saveTask(BuildContext context) {
    final validationError = _validateForm();

    if (validationError != null) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Validation Error'),
              content: Text(validationError),
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

    final taskManagerCubit = context.read<TaskManagerCubit>();

    if (widget.task == null) {
      taskManagerCubit.createTask(
        title: _titleController.text,
        priority: _formData.priority,
        estimatedTime: _formData.estimatedTime,
        deadline: _formData.selectedDateTime.millisecondsSinceEpoch,
        category: Category(name: _selectedCategory),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        color: _formData.color,
        optimisticTime: _formData.optimisticTime,
        realisticTime: _formData.realisticTime,
        pessimisticTime: _formData.pessimisticTime,
      );
    } else {
      taskManagerCubit.editTask(
        task: widget.task!,
        title: _titleController.text,
        priority: _formData.priority,
        estimatedTime: _formData.estimatedTime,
        deadline: _formData.selectedDateTime.millisecondsSinceEpoch,
        category: Category(name: _selectedCategory),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        color: _formData.color,
        optimisticTime: _formData.optimisticTime,
        realisticTime: _formData.realisticTime,
        pessimisticTime: _formData.pessimisticTime,
      );
    }

    logInfo(
      'Task ${widget.task == null ? "Created" : "Updated"}: ${_titleController.text}',
    );

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  DateTime _roundToNearestFiveMinutes(DateTime dateTime) {
    final int minute = dateTime.minute;
    final int remainder = minute % 5;
    final int roundedMinute =
        remainder == 0 ? minute : minute + (5 - remainder);
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      roundedMinute,
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
