import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/screens/home_screen.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/tasks_controller/task_manager_cubit.dart';

class AddTaskPage extends StatefulWidget {
  final DateTime? selectedDate;

  const AddTaskPage({super.key, this.selectedDate});

  @override
  AddTaskPageState createState() => AddTaskPageState();
}

class AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  // Store provider references
  late TaskManagerCubit _taskManagerCubit;
  late var _estimatedTime = 0;

  late DateTime _selectedDate;
  late DateTime _selectedTime;
  String _selectedCategory = 'Brainstorm';
  int _priority = 1;
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
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _selectedTime = _selectedDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _formatTime(DateTime? time) =>
      time != null
          ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
          : 'Not set';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
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
                _buildSaveButton(context, 'Task'),
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

  Widget _buildSaveButton(BuildContext context, String type) => Center(
    child: CupertinoButton.filled(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      onPressed: () => _saveTask(context, type),
      child: const Text(
        'Save',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );

  Widget _buildEstimatedTimeButton(BuildContext context) => GestureDetector(
    onTap: () async {
      final estimatedTime = await _showEstimatedTimePicker(context);
      if (mounted) {
        setState(() => _estimatedTime = estimatedTime);
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
            'Estimated Time',
            style: TextStyle(fontSize: 16, color: CupertinoColors.systemBlue),
          ),
          Text(
            '${(_estimatedTime ~/ 3600000).toString().padLeft(2, '0')}h ${((_estimatedTime % 3600000) ~/ 60000).toString().padLeft(2, '0')}m',
            style: const TextStyle(fontSize: 16, color: CupertinoColors.label),
          ),
        ],
      ),
    ),
  );

  Widget _buildPrioritySlider() => SizedBox(
    width: double.infinity,
    child: CupertinoSlider(
      min: 1,
      max: 10,
      divisions: 9,
      value: _priority.toDouble(),
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
    final now = DateTime.now();

    // Calculate initial duration based on current time if needed
    Duration initialDuration;
    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day &&
        _selectedTime.isBefore(now)) {
      // If selected date is today and selected time is before now, use current time
      initialDuration = Duration(hours: now.hour, minutes: now.minute);
    } else {
      // Otherwise use selected time
      initialDuration = Duration(
        hours: _selectedTime.hour,
        minutes: _selectedTime.minute,
      );
    }

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
                    initialTimerDuration: initialDuration,
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

        // If selected date is today, ensure time is not before current time
        if (_selectedDate.year == now.year &&
            _selectedDate.month == now.month &&
            _selectedDate.day == now.day &&
            time.isBefore(now)) {
          _selectedTime = DateTime(
            now.year,
            now.month,
            now.day,
            now.hour,
            now.minute,
          );
        } else {
          _selectedTime = time;
        }
      });
    }
  }

  Future<int> _showEstimatedTimePicker(BuildContext context) async {
    int? pickedHours;
    int? pickedMinutes;
    await showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 300,
            color: CupertinoColors.systemBackground,
            child: Row(
              children: [
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 32,
                    onSelectedItemChanged: (index) {
                      pickedHours = index;
                    },
                    children: [for (var i = 0; i <= 120; i++) Text('$i hours')],
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 32,
                    onSelectedItemChanged: (index) {
                      pickedMinutes = index * 15;
                    },
                    children: [
                      for (var i = 0; i < 4; i++) Text('${i * 15} minutes'),
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

  void _handleCategoryChange(String value) {
    if (value == 'Add') {
      _showAddCategoryDialog(context);
    } else {
      setState(() => _selectedCategory = value);
    }
  }

  Future<void> _saveTask(BuildContext context, String type) async {
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
  }
}
