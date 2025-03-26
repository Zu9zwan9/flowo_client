import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/screens/home_screen.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/tasks_controller/task_manager_cubit.dart';
import '../calendar/calendar_screen.dart';

class TaskEditScreen extends StatefulWidget {
  final Task task;

  const TaskEditScreen({super.key, required this.task});

  @override
  TaskEditScreenState createState() => TaskEditScreenState();
}

class TaskEditScreenState extends State<TaskEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  late int _estimatedTime;
  late int _optimisticTime;
  late int _realisticTime;
  late int _pessimisticTime;
  late DateTime _selectedDate;
  late DateTime _selectedTime;
  late String _selectedCategory;
  late int _priority;
  int? _selectedColor;

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

    // Initialize controllers and variables with task data
    _titleController.text = widget.task.title;
    _notesController.text = widget.task.notes ?? '';
    _estimatedTime = widget.task.estimatedTime;
    _optimisticTime = widget.task.optimisticTime ?? 0;
    _realisticTime = widget.task.realisticTime ?? 0;
    _pessimisticTime = widget.task.pessimisticTime ?? 0;
    _selectedDate = DateTime.fromMillisecondsSinceEpoch(widget.task.deadline);
    _selectedTime = _selectedDate;
    _selectedCategory = widget.task.category.name;
    _priority = widget.task.priority;
    _selectedColor = widget.task.color;

    // Add the task's category to the options if it's not already there
    if (!_categoryOptions.contains(_selectedCategory) &&
        _selectedCategory != 'Add') {
      _categoryOptions.insert(_categoryOptions.length - 1, _selectedCategory);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateEstimatedTime() {
    if (_optimisticTime > 0 && _realisticTime > 0 && _pessimisticTime > 0) {
      _estimatedTime =
          ((_optimisticTime + (4 * _realisticTime) + _pessimisticTime) / 6)
              .round();
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _formatTime(DateTime? time) =>
      time != null
          ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
          : 'Not set';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Edit Task')),
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
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _notesController,
                  placeholder: 'Notes',
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Deadline'),
                const SizedBox(height: 12),
                _buildDateButton(context),
                const SizedBox(height: 12),
                _buildTimeButton(context),
                const SizedBox(height: 20),
                _buildSectionTitle('Estimated Time'),
                const SizedBox(height: 12),
                _buildEstimatedTimeButton(context),
                const SizedBox(height: 20),
                _buildSectionTitle('Category'),
                const SizedBox(height: 12),
                _buildSegmentedControl(
                  options: _categoryOptions,
                  value: _selectedCategory,
                  onChanged: _handleCategoryChange,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildSectionTitle('Priority '),
                    Text(
                      _priority.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPrioritySlider(),
                const SizedBox(height: 20),
                _buildSectionTitle('Color'),
                const SizedBox(height: 12),
                _buildColorSelector(),
                const SizedBox(height: 32),
                _buildSaveButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: CupertinoColors.label,
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) => CupertinoTextField(
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

  Widget _buildDateButton(BuildContext context) => GestureDetector(
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
            style: const TextStyle(fontSize: 16, color: CupertinoColors.label),
          ),
        ],
      ),
    ),
  );

  Widget _buildTimeButton(BuildContext context) => GestureDetector(
    onTap: () => _showTimePicker(context),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: (CupertinoColors.systemBlue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Time',
            style: TextStyle(fontSize: 16, color: CupertinoColors.systemBlue),
          ),
          Text(
            _formatTime(_selectedTime),
            style: const TextStyle(fontSize: 16, color: CupertinoColors.label),
          ),
        ],
      ),
    ),
  );

  Widget _buildSegmentedControl({
    required List<String> options,
    required String value,
    required ValueChanged<String> onChanged,
    Color selectedColor = CupertinoColors.activeBlue,
  }) => CupertinoSegmentedControl<String>(
    children: {
      for (var item in options)
        item: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(item.toString(), style: const TextStyle(fontSize: 14)),
        ),
    },
    groupValue: options.contains(value) ? value : null,
    onValueChanged: onChanged,
    borderColor: CupertinoColors.systemGrey4,
    selectedColor: selectedColor,
    unselectedColor: CupertinoColors.systemGrey6,
    pressedColor: selectedColor.withOpacity(0.2),
  );

  Widget _buildSaveButton(BuildContext context) => Center(
    child: CupertinoButton.filled(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      onPressed: () => _saveTask(context),
      child: const Text(
        'Save Changes',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );

  Widget _buildEstimatedTimeButton(BuildContext context) => Column(
    children: [
      // Optimistic Time Button
      GestureDetector(
        onTap: () async {
          final optimisticTime = await _showEstimatedTimePicker(
            context,
            'optimistic',
          );
          if (mounted) {
            setState(() {
              _optimisticTime = optimisticTime;
              _calculateEstimatedTime();
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Optimistic Time (Best Case)',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemGreen,
                ),
              ),
              Text(
                '${(_optimisticTime ~/ 3600000).toString().padLeft(2, '0')}h ${((_optimisticTime % 3600000) ~/ 60000).toString().padLeft(2, '0')}m',
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.label,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),

      // Realistic Time Button
      GestureDetector(
        onTap: () async {
          final realisticTime = await _showEstimatedTimePicker(
            context,
            'realistic',
          );
          if (mounted) {
            setState(() {
              _realisticTime = realisticTime;
              _calculateEstimatedTime();
            });
          }
        },
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
                'Realistic Time (Most Likely)',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemBlue,
                ),
              ),
              Text(
                '${(_realisticTime ~/ 3600000).toString().padLeft(2, '0')}h ${((_realisticTime % 3600000) ~/ 60000).toString().padLeft(2, '0')}m',
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.label,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),

      // Pessimistic Time Button
      GestureDetector(
        onTap: () async {
          final pessimisticTime = await _showEstimatedTimePicker(
            context,
            'pessimistic',
          );
          if (mounted) {
            setState(() {
              _pessimisticTime = pessimisticTime;
              _calculateEstimatedTime();
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pessimistic Time (Worst Case)',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemOrange,
                ),
              ),
              Text(
                '${(_pessimisticTime ~/ 3600000).toString().padLeft(2, '0')}h ${((_pessimisticTime % 3600000) ~/ 60000).toString().padLeft(2, '0')}m',
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.label,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),

      // Expected Time (PERT)
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Expected Time (PERT)',
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${(_estimatedTime ~/ 3600000).toString().padLeft(2, '0')}h ${((_estimatedTime % 3600000) ~/ 60000).toString().padLeft(2, '0')}m',
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.label,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _estimateTimeWithAI(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      CupertinoIcons.wand_stars,
                      color: CupertinoColors.systemGreen,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Estimate with AI',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _rescheduleTask(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      CupertinoIcons.calendar_badge_plus,
                      color: CupertinoColors.systemOrange,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Reschedule',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _buildPrioritySlider() => SizedBox(
    width: double.infinity,
    child: CupertinoSlider(
      min: 1,
      max: 10,
      divisions: 9,
      // Ensure the value is within the valid range
      value: _priority < 1 ? 1 : (_priority > 10 ? 10 : _priority.toDouble()),
      onChanged: (value) => setState(() => _priority = value.toInt()),
      activeColor: CupertinoColors.systemOrange,
    ),
  );

  Widget _buildColorSelector() => SizedBox(
    height: 50,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _colorOptions.length + 1, // +1 for "No color" option
      itemBuilder: (context, index) {
        if (index == 0) {
          // "No color" option
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = null;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CupertinoColors.white,
                  border: Border.all(
                    color:
                        _selectedColor == null
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.systemGrey,
                    width: 2,
                  ),
                ),
                child:
                    _selectedColor == null
                        ? const Icon(
                          CupertinoIcons.checkmark,
                          color: CupertinoColors.activeBlue,
                        )
                        : null,
              ),
            ),
          );
        }

        final color = _colorOptions[index - 1];
        final colorValue = color.value;
        final isSelected = _selectedColor == colorValue;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = colorValue;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color:
                      isSelected
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.systemGrey,
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? const Icon(
                        CupertinoIcons.checkmark,
                        color: CupertinoColors.white,
                      )
                      : null,
            ),
          ),
        );
      },
    ),
  );

  Future<void> _showDatePicker(BuildContext context) async {
    DateTime? pickedDate;
    final now = DateTime.now();
    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            color: CupertinoColors.systemBackground,
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime:
                        _selectedDate.isBefore(now) ? now : _selectedDate,
                    minimumDate: now,
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

  Future<void> _showTimePicker(BuildContext context) async {
    Duration? pickedDuration;
    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            color: CupertinoColors.systemBackground,
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hm,
                    initialTimerDuration: Duration(
                      hours: (_selectedTime).hour,
                      minutes: (_selectedTime).minute,
                    ),
                    onTimerDurationChanged:
                        (duration) => pickedDuration = duration,
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
        _selectedTime = time;
      });
    }
  }

  Future<int> _showEstimatedTimePicker(
    BuildContext context, [
    String timeType = '',
  ]) async {
    int? pickedHours;
    int? pickedMinutes;

    // Determine initial values based on time type
    int initialHours = 0;
    int initialMinutes = 0;

    switch (timeType) {
      case 'optimistic':
        initialHours = _optimisticTime ~/ 3600000;
        initialMinutes = (_optimisticTime % 3600000) ~/ 60000;
        break;
      case 'realistic':
        initialHours = _realisticTime ~/ 3600000;
        initialMinutes = (_realisticTime % 3600000) ~/ 60000;
        break;
      case 'pessimistic':
        initialHours = _pessimisticTime ~/ 3600000;
        initialMinutes = (_pessimisticTime % 3600000) ~/ 60000;
        break;
      default:
        initialHours = _estimatedTime ~/ 3600000;
        initialMinutes = (_estimatedTime % 3600000) ~/ 60000;
    }

    // Initialize with current values
    pickedHours = initialHours;
    pickedMinutes =
        initialMinutes - (initialMinutes % 15); // Round to nearest 15 minutes

    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            color: CupertinoColors.systemBackground,
            child: Column(
              children: [
                _buildPickerActions(context),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 32,
                          scrollController: FixedExtentScrollController(
                            initialItem: initialHours,
                          ),
                          onSelectedItemChanged: (index) {
                            pickedHours = index;
                          },
                          children: [
                            for (var i = 0; i <= 120; i++) Text('$i hours'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 32,
                          scrollController: FixedExtentScrollController(
                            initialItem: initialMinutes ~/ 15,
                          ),
                          onSelectedItemChanged: (index) {
                            pickedMinutes = index * 15;
                          },
                          children: [
                            for (var i = 0; i < 4; i++)
                              Text('${i * 15} minutes'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );

    return (pickedHours ?? 0) * 3600000 + (pickedMinutes ?? 0) * 60000;
  }

  Widget _buildPickerActions(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      CupertinoButton(
        child: const Text(
          'Cancel',
          style: TextStyle(color: CupertinoColors.systemGrey),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      CupertinoButton(
        child: const Text(
          'Done',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    ],
  );

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
                  final newCategory = controller.text.trim();
                  if (newCategory.isNotEmpty && mounted) {
                    setState(() {
                      if (!_categoryOptions.contains(newCategory)) {
                        _categoryOptions.insert(
                          _categoryOptions.length - 1,
                          newCategory,
                        );
                      }
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

  Future<void> _estimateTimeWithAI(BuildContext context) async {
    // Show loading indicator
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const CupertinoAlertDialog(
            title: Text('Estimating Time'),
            content: Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Center(child: CupertinoActivityIndicator()),
            ),
          ),
    );

    try {
      // Call the TaskManagerCubit to estimate time for the task
      final estimatedTime = await context
          .read<TaskManagerCubit>()
          .estimateTaskTime(widget.task);

      // Close the loading dialog
      Navigator.pop(context);

      if (mounted) {
        setState(() {
          _estimatedTime = estimatedTime;
        });

        // Show success dialog
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Time Estimated'),
                content: Text(
                  'The AI estimates this task will take ${(_estimatedTime ~/ 3600000).toString().padLeft(2, '0')}h ${((_estimatedTime % 3600000) ~/ 60000).toString().padLeft(2, '0')}m to complete.',
                ),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    child: const Text('Reschedule Now'),
                    onPressed: () {
                      Navigator.pop(context);
                      _rescheduleTask(context);
                    },
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      // Close the loading dialog
      Navigator.pop(context);

      // Show error dialog
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Estimation Error'),
              content: Text('Failed to estimate time: $e'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
    }
  }

  Future<void> _rescheduleTask(BuildContext context) async {
    // Show loading indicator
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const CupertinoAlertDialog(
            title: Text('Rescheduling Task'),
            content: Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Center(child: CupertinoActivityIndicator()),
            ),
          ),
    );

    try {
      // Update the task with current values before rescheduling
      final selectedTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      context.read<TaskManagerCubit>().editTask(
        task: widget.task,
        title: _titleController.text,
        priority: _priority,
        estimatedTime: _estimatedTime,
        deadline: selectedTime.millisecondsSinceEpoch,
        category: Category(name: _selectedCategory),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        color: _selectedColor,
      );

      // Close the loading dialog
      Navigator.pop(context);

      // Show success dialog
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Task Rescheduled'),
              content: const Text(
                'The task has been rescheduled with the new estimated time.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate back to home screen
                    Navigator.pushReplacement(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => const CalendarScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
      );
    } catch (e) {
      // Close the loading dialog
      Navigator.pop(context);

      // Show error dialog
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Rescheduling Error'),
              content: Text('Failed to reschedule task: $e'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
    }
  }

  Future<void> _saveTask(BuildContext context) async {
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

    context.read<TaskManagerCubit>().editTask(
      task: widget.task,
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
  }
}
