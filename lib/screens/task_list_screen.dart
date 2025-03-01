import 'package:flowo_client/screens/home_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/tasks_controller/task_manager_cubit.dart';
import '../blocs/tasks_controller/tasks_controller_cubit.dart';
import '../models/task.dart';
import 'task_breakdown_screen.dart';
import 'task_page_screen.dart';

enum TaskFilterType { all, event, task, habit }

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();
  TaskFilterType _selectedFilter = TaskFilterType.all;
  final Map<String, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  TaskFilterType _getTaskType(Task task) {
    final cat = task.category.name.toLowerCase();
    if (cat.contains('event')) return TaskFilterType.event;
    if (cat.contains('habit')) return TaskFilterType.habit;
    return TaskFilterType.task;
  }

  Map<String, List<Task>> _filterGroupedTasks(
      Map<String, List<Task>> groupedTasks) {
    final query = _searchController.text.toLowerCase();
    final Map<String, List<Task>> filtered = {};
    groupedTasks.forEach((category, tasks) {
      final tasksFiltered = tasks.where((task) {
        final matchesQuery = task.title.toLowerCase().contains(query);
        final type = _getTaskType(task);
        final matchesFilter =
            _selectedFilter == TaskFilterType.all || _selectedFilter == type;
        return matchesQuery && matchesFilter;
      }).toList();
      if (tasksFiltered.isNotEmpty) filtered[category] = tasksFiltered;
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGrey6,
      navigationBar: _buildNavigationBar(context),
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildSearchBar(),
                const SizedBox(height: 8),
                _buildTypeFilter(),
                Expanded(child: _buildTaskList(context)),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              children: [
                _buildFAB(context),
                const SizedBox(height: 16),
                _buildScheduleButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  CupertinoNavigationBar _buildNavigationBar(BuildContext context) =>
      const CupertinoNavigationBar(
        middle: Text('Reminders'),
        backgroundColor: CupertinoColors.systemGrey6,
        border: null,
      );

  Widget _buildSearchBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: CupertinoSearchTextField(
          controller: _searchController,
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

  Widget _buildTypeFilter() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: CupertinoSegmentedControl<TaskFilterType>(
          groupValue: _selectedFilter,
          children: const {
            TaskFilterType.all: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('All', style: TextStyle(fontSize: 14)),
            ),
            TaskFilterType.task: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Task', style: TextStyle(fontSize: 14)),
            ),
            TaskFilterType.event: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Event', style: TextStyle(fontSize: 14)),
            ),
            TaskFilterType.habit: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Habit', style: TextStyle(fontSize: 14)),
            ),
          },
          onValueChanged: (value) => setState(() => _selectedFilter = value),
          borderColor: CupertinoColors.systemGrey4,
          selectedColor: CupertinoColors.activeBlue,
          unselectedColor: CupertinoColors.white,
          pressedColor: CupertinoColors.activeBlue.withOpacity(0.2),
        ),
      );

  Widget _buildTaskList(BuildContext context) =>
      FutureBuilder<Map<String, List<Task>>>(
        future: context.read<CalendarCubit>().getTasksGroupedByCategory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: CupertinoColors.systemGrey)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No tasks found',
                    style: TextStyle(color: CupertinoColors.systemGrey)));
          }

          final groupedTasks = _filterGroupedTasks(snapshot.data!);
          if (groupedTasks.isEmpty) {
            return const Center(
                child: Text('No tasks match your filter',
                    style: TextStyle(color: CupertinoColors.systemGrey)));
          }

          return CupertinoScrollbar(
            child: ListView.builder(
              itemCount: groupedTasks.length,
              itemBuilder: (context, index) {
                final category = groupedTasks.keys.elementAt(index);
                final tasks = groupedTasks[category]!;
                final isExpanded = _expandedCategories[category] ?? true;
                return _buildCategorySection(
                    context, category, tasks, isExpanded);
              },
            ),
          );
        },
      );

  Widget _buildCategorySection(BuildContext context, String category,
      List<Task> tasks, bool isExpanded) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () =>
                setState(() => _expandedCategories[category] = !isExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category,
                  style: CupertinoTheme.of(context)
                      .textTheme
                      .navTitleTextStyle
                      .copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.label,
                      ),
                ),
                Icon(
                  isExpanded
                      ? CupertinoIcons.chevron_down
                      : CupertinoIcons.chevron_right,
                  size: 20,
                  color: CupertinoColors.systemGrey,
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 8),
            ...tasks.map((task) => _buildTaskTile(context, task)),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTaskTile(BuildContext context, Task task) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => TaskPageScreen(task: task)),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(task.category.name),
                    borderRadius:
                        const BorderRadius.horizontal(left: Radius.circular(2)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${task.title} ${task.scheduledTasks.length}',
                        style: CupertinoTheme.of(context)
                            .textTheme
                            .textStyle
                            .copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.label,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (task.notes != null && task.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.notes!,
                          style: const TextStyle(
                              fontSize: 14, color: CupertinoColors.systemGrey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  task.isDone
                      ? CupertinoIcons.check_mark_circled
                      : CupertinoIcons.circle,
                  color: task.isDone
                      ? CupertinoColors.activeGreen
                      : CupertinoColors.systemGrey,
                  size: 24,
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.pencil, size: 24),
                  onPressed: () => _editTask(context, task),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.delete, size: 24),
                  onPressed: () => _deleteTask(context, task),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildFAB(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: CupertinoColors.activeBlue,
          ),
          child: const Icon(CupertinoIcons.add,
              color: CupertinoColors.white, size: 28),
        ),
        onPressed: () {
          // Navigate to AddItemScreen or similar
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(builder: (_) => HomeScreen(initialIndex: 2)),
          );
        },
      );

  Widget _buildScheduleButton(BuildContext context) => CupertinoButton(
        padding: EdgeInsets.zero,
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: CupertinoColors.activeGreen,
          ),
          child: const Icon(CupertinoIcons.calendar,
              color: CupertinoColors.white, size: 28),
        ),
        onPressed: () {
          _scheduleTasks();
          context.read<TaskManagerCubit>().manageTasks();
          _scheduleTasks();
        },
      );

  void _scheduleTasks() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Schedule Tasks'),
        content: const Text('Tasks have been scheduled successfully.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _editTask(BuildContext context, Task task) {
    // Implement your edit task logic here
    // For example, navigate to a task edit screen
  }

  void _deleteTask(BuildContext context, Task task) {
    context.read<TaskManagerCubit>().deleteTask(task);
    setState(() {});
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'brainstorm':
        return CupertinoColors.systemBlue;
      case 'design':
        return CupertinoColors.systemGreen;
      case 'workout':
        return CupertinoColors.systemRed;
      case 'event':
        return CupertinoColors.systemPurple;
      case 'habit':
        return CupertinoColors.systemOrange;
      default:
        return CupertinoColors.systemGrey;
    }
  }
}
