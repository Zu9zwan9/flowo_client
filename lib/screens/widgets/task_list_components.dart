import 'package:flutter/cupertino.dart';
import '../../models/task.dart';

class TaskSearchBar extends StatelessWidget {
  final TextEditingController controller;

  const TaskSearchBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CupertinoSearchTextField(
        controller: controller,
        placeholder: 'Search by Name',
        style: const TextStyle(fontSize: 16, color: CupertinoColors.label),
        placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey2),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CupertinoColors.systemGrey5),
        ),
      ),
    );
  }
}

class TaskTypeFilter extends StatelessWidget {
  final TaskFilterType selectedFilter;
  final ValueChanged<TaskFilterType> onFilterChanged;

  const TaskTypeFilter({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CupertinoSegmentedControl<TaskFilterType>(
        groupValue: selectedFilter,
        onValueChanged: onFilterChanged,
        children: const {
          TaskFilterType.all: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('All', style: TextStyle(fontSize: 14)),
          ),
          TaskFilterType.event: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Events', style: TextStyle(fontSize: 14)),
          ),
          TaskFilterType.task: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Tasks', style: TextStyle(fontSize: 14)),
          ),
          TaskFilterType.habit: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Habits', style: TextStyle(fontSize: 14)),
          ),
        },
      ),
    );
  }
}

class TaskActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const TaskActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: onPressed,
      color: CupertinoColors.activeBlue,
      borderRadius: BorderRadius.circular(30),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: CupertinoColors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: CupertinoColors.white)),
        ],
      ),
    );
  }
}

enum TaskFilterType { all, event, task, habit }
