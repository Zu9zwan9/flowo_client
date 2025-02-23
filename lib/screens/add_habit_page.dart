// lib/screens/add_habit_page.dart
import 'package:flowo_client/blocs/tasks_controller/tasks_controller_cubit.dart';
import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/models/day.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/screens/home_screen.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddHabitPage extends StatefulWidget {
  final DateTime? selectedDate;

  const AddHabitPage({super.key, this.selectedDate});

  @override
  AddHabitPageState createState() => AddHabitPageState();
}

class AddHabitPageState extends State<AddHabitPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _selectedDate;
  late DateTime _startTime;
  DateTime? _endTime;
  String _selectedCategory = 'Brainstorm';
  String _priority = 'Normal';
  final List<Map<String, dynamic>> _frequency = [];
  final List<String> _categoryOptions = [
    'Brainstorm',
    'Design',
    'Workout',
    'Add'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _startTime = _selectedDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _formatTime(DateTime? time) => time != null
      ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
      : 'Not set';

  int _mapPriorityToInt(String priority) =>
      {'Low': 0, 'Normal': 1, 'High': 2}[priority] ?? 1;

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
                _buildSectionTitle('Habit Details'),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _titleController,
                  placeholder: 'Habit Name *',
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                    controller: _notesController,
                    placeholder: 'Notes',
                    maxLines: 3),
                const SizedBox(height: 20),
                _buildSectionTitle('Deadline'),
                const SizedBox(height: 12),
                _buildDateButton(context),
                const SizedBox(height: 12),
                _buildTimeButton(context, isStart: true),
                const SizedBox(height: 12),
                _buildTimeButton(context, isStart: false),
                const SizedBox(height: 20),
                _buildSectionTitle('Frequency'),
                const SizedBox(height: 12),
                _buildFrequencySelector(context),
                const SizedBox(height: 20),
                _buildSectionTitle('Category'),
                const SizedBox(height: 12),
                _buildSegmentedControl(
                  options: _categoryOptions,
                  value: _selectedCategory,
                  onChanged: _handleCategoryChange,
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
                _buildSaveButton(context, 'Habit'),
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
  }) =>
      CupertinoTextField(
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
              const Text('Date',
                  style: TextStyle(
                      fontSize: 16, color: CupertinoColors.systemBlue)),
              Text(_formatDate(_selectedDate),
                  style: const TextStyle(
                      fontSize: 16, color: CupertinoColors.label)),
            ],
          ),
        ),
      );

  Widget _buildTimeButton(BuildContext context, {required bool isStart}) =>
      GestureDetector(
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
              Text(isStart ? 'Start Time' : 'End Time',
                  style: TextStyle(
                      fontSize: 16,
                      color: isStart
                          ? CupertinoColors.systemGreen
                          : CupertinoColors.systemOrange)),
              Text(_formatTime(isStart ? _startTime : _endTime),
                  style: const TextStyle(
                      fontSize: 16, color: CupertinoColors.label)),
            ],
          ),
        ),
      );

  Widget _buildSegmentedControl({
    required List<String> options,
    required String value,
    required ValueChanged<String> onChanged,
    Color selectedColor = CupertinoColors.activeBlue,
  }) =>
      CupertinoSegmentedControl<String>(
        children: {
          for (var item in options)
            item: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(item, style: const TextStyle(fontSize: 14)),
            ),
        },
        groupValue: options.contains(value) ? value : null,
        onValueChanged: onChanged,
        borderColor: CupertinoColors.systemGrey4,
        selectedColor: selectedColor,
        unselectedColor: CupertinoColors.systemGrey6,
        pressedColor: selectedColor.withOpacity(0.2),
      );

  Widget _buildFrequencySelector(BuildContext context) => Column(
        children: [
          if (_frequency.isNotEmpty)
            ..._frequency.map((freq) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(freq['day']),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(CupertinoIcons.trash,
                            size: 20, color: CupertinoColors.systemRed),
                        onPressed: () =>
                            setState(() => _frequency.remove(freq)),
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 8),
          CupertinoButton(
            color: CupertinoColors.systemBlue,
            child: const Text('Add Frequency'),
            onPressed: () => _showFrequencyDialog(context),
          ),
        ],
      );

  Widget _buildSaveButton(BuildContext context, String type) => Center(
        child: CupertinoButton.filled(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          onPressed: () => _saveTask(context, type),
          child: const Text('Save',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      );

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
    if (pickedDate != null && mounted)
      setState(() => _selectedDate = pickedDate!);
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
                        (isStart ? _startTime : _endTime ?? _startTime).minute),
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
            pickedDuration!.inMinutes % 60);
        if (isStart)
          _startTime = time;
        else
          _endTime = time;
      });
    }
  }

  Future<void> _showFrequencyDialog(BuildContext context) async {
    String? selectedDay;
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add Frequency'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Select Day'),
            onPressed: () async {
              await showCupertinoModalPopup(
                context: context,
                builder: (context) => Container(
                  height: 300,
                  color: CupertinoColors.systemBackground,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: CupertinoPicker(
                          itemExtent: 32,
                          onSelectedItemChanged: (index) {
                            selectedDay = [
                              'Monday',
                              'Tuesday',
                              'Wednesday',
                              'Thursday',
                              'Friday',
                              'Saturday',
                              'Sunday'
                            ][index];
                          },
                          children: const [
                            Text('Monday'),
                            Text('Tuesday'),
                            Text('Wednesday'),
                            Text('Thursday'),
                            Text('Friday'),
                            Text('Saturday'),
                            Text('Sunday'),
                          ],
                        ),
                      ),
                      _buildPickerActions(context),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Done'),
          onPressed: () {
            if (selectedDay != null && mounted) {
              setState(() => _frequency.add({'day': selectedDay!}));
              logInfo('Added frequency: $selectedDay');
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildPickerActions(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CupertinoButton(
              child: const Text('Cancel',
                  style: TextStyle(color: CupertinoColors.systemGrey)),
              onPressed: () => Navigator.pop(context)),
          CupertinoButton(
              child: const Text('Done',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onPressed: () => Navigator.pop(context)),
        ],
      );

  void _showAddCategoryDialog(BuildContext context) {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Add Custom Category'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Category Name',
            decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Add'),
            onPressed: () {
              final newCategory = controller.text.trim();
              if (newCategory.isNotEmpty && mounted) {
                setState(() {
                  if (!_categoryOptions.contains(newCategory))
                    _categoryOptions.insert(
                        _categoryOptions.length - 1, newCategory);
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
    if (value == 'Add')
      _showAddCategoryDialog(context);
    else
      setState(() => _selectedCategory = value);
  }

  void _saveTask(BuildContext context, String type) {
    if (!_formKey.currentState!.validate()) {
      showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
                  title: const Text('Validation Error'),
                  content: const Text('Please fill in all required fields.'),
                  actions: [
                    CupertinoDialogAction(
                        child: const Text('OK'),
                        onPressed: () => Navigator.pop(context))
                  ]));
      return;
    }

    final startTime = DateTime(_selectedDate.year, _selectedDate.month,
        _selectedDate.day, _startTime.hour, _startTime.minute);
    final endTime = _endTime != null
        ? DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day,
            _endTime!.hour, _endTime!.minute)
        : startTime.add(const Duration(minutes: 60));

    if (endTime.isBefore(startTime)) {
      showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
                  title: const Text('Invalid Time'),
                  content: const Text('End time must be after start time.'),
                  actions: [
                    CupertinoDialogAction(
                        child: const Text('OK'),
                        onPressed: () => Navigator.pop(context))
                  ]));
      return;
    }

    final task = Task(
      id: UniqueKey().toString(),
      title: _titleController.text,
      priority: _mapPriorityToInt(_priority),
      deadline: startTime.millisecondsSinceEpoch,
      estimatedTime: endTime.difference(startTime).inMilliseconds,
      category: Category(name: _selectedCategory),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      frequency: _frequency.isNotEmpty
          ? _frequency.map((f) => Day(day: f['day'])).toList()
          : null,
      subtasks: const [],
      scheduledTasks: const [],
      isDone: false,
      order: 0,
      overdue: false,
    );

    context.read<CalendarCubit>().addTask(task);
    Navigator.pushReplacement(
            context, CupertinoPageRoute(builder: (_) => const HomeScreen()))
        .then((_) => context.read<CalendarCubit>().selectDate(startTime));
    logInfo('Saved $type: ${task.title}');
  }
}
