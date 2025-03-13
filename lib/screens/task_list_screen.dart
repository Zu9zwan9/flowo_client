import 'package:flowo_client/screens/home_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'widgets/cupertino_divider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/tasks_controller/task_manager_cubit.dart';
import '../blocs/tasks_controller/task_manager_state.dart';
import '../models/task.dart';
import '../utils/debouncer.dart';
import '../utils/category_utils.dart';
import 'widgets/task_list_components.dart';
import 'widgets/task_list_item.dart';
import 'task_page_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer();
  TaskFilterType _selectedFilter = TaskFilterType.all;
  final Map<String, bool> _expandedCategories = {};
  final Map<String, bool> _expandedTasks = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _searchDebouncer.call(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  TaskFilterType _getTaskType(Task task) {
    final cat = task.category.name.toLowerCase();
    if (cat.contains('event')) return TaskFilterType.event;
    if (cat.contains('habit')) return TaskFilterType.habit;
    return TaskFilterType.task;
  }

  // Cache for filtered tasks to avoid unnecessary recomputation
  Map<String, List<Task>>? _filteredTasksCache;
  String? _lastQuery;
  TaskFilterType? _lastFilter;

  Map<String, List<Task>> _filterGroupedTasks(
      Map<String, List<Task>> groupedTasks) {
    // Return cached results if nothing has changed
    if (_filteredTasksCache != null &&
        _lastQuery == _searchQuery &&
        _lastFilter == _selectedFilter) {
      return _filteredTasksCache!;
    }

    final query = _searchQuery.toLowerCase();
    final filtered = <String, List<Task>>{};

    groupedTasks.forEach((category, tasks) {
      final tasksFiltered = tasks.where((task) {
        // Check if task title matches search query
        final matchesQuery = task.title.toLowerCase().contains(query);
        // Get task type for filter matching
        final type = _getTaskType(task);
        // Check if task matches selected filter type
        final matchesFilter =
            _selectedFilter == TaskFilterType.all || _selectedFilter == type;
        return matchesQuery && matchesFilter;
      }).toList();

      if (tasksFiltered.isNotEmpty) {
        filtered[category] = tasksFiltered;
      }
    });

    // Update cache and last known state
    _filteredTasksCache = filtered;
    _lastQuery = _searchQuery;
    _lastFilter = _selectedFilter;

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGrey6,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Reminders'),
        backgroundColor: CupertinoColors.systemGrey6,
        border: null,
      ),
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                TaskSearchBar(controller: _searchController),
                const SizedBox(height: 8),
                TaskTypeFilter(
                  selectedFilter: _selectedFilter,
                  onFilterChanged: (filter) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedFilter = filter;
                      _clearCache(); // Clear cache when filter changes
                    });
                  },
                ),
                Expanded(child: _buildTaskList(context)),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TaskActionButton(
                  onPressed: () => _showAddTaskDialog(context),
                  icon: CupertinoIcons.add,
                  label: 'Add Task',
                ),
                const SizedBox(height: 8),
                TaskActionButton(
                  onPressed: () => _showScheduleDialog(context),
                  icon: CupertinoIcons.calendar,
                  label: 'Schedule',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Clear the filtered tasks cache
  void _clearCache() {
    _filteredTasksCache = null;
    _lastQuery = null;
    _lastFilter = null;
  }

  void _showAddTaskDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const HomeScreen(
          initialIndex: 2,
          initialExpanded: false,
        ),
      ),
    );
  }

  void _showScheduleDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    final tasksCubit = context.read<TaskManagerCubit>();
    tasksCubit.scheduleTasks();
    _clearCache(); // Clear cache as tasks will be modified
  }

  Widget _buildTaskList(BuildContext context) =>
      BlocBuilder<TaskManagerCubit, TaskManagerState>(
        builder: (context, state) {
          final groupedTasks = _groupTasksByCategory(state.tasks);
          final filteredTasks = _filterGroupedTasks(groupedTasks);
          if (filteredTasks.isEmpty) {
            return const Center(
                child: Text('No tasks match your filter',
                    style: TextStyle(color: CupertinoColors.systemGrey)));
          }

          return CupertinoScrollbar(
            child: ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final category = filteredTasks.keys.elementAt(index);
                final tasks = filteredTasks[category]!;
                final isExpanded = _expandedCategories[category] ?? true;
                return _buildCategorySection(
                    context, category, tasks, isExpanded);
              },
            ),
          );
        },
      );

  Map<String, List<Task>> _groupTasksByCategory(List<Task> tasks) {
    final grouped = <String, List<Task>>{};
    for (var task in tasks) {
      // Only add top-level tasks (tasks without a parent) to avoid duplicating subtasks
      if (task.parentTaskId == null) {
        grouped.putIfAbsent(task.category.name, () => []).add(task);
      }
    }
    return grouped;
  }

  Widget _buildCategorySection(BuildContext context, String category,
          List<Task> tasks, bool isExpanded) =>
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CupertinoColors.systemGrey5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _expandedCategories[category] = !isExpanded);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${tasks.length}',
                          style: const TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
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
              const CupertinoDivider(),
              ...tasks.map((task) {
                final hasSubtasks = task.subtasks.isNotEmpty;
                final isExpanded = _expandedTasks[task.id] ?? false;
                return Column(
                  children: [
                    TaskListItem(
                      task: task,
                      onTap: () => _onTaskTap(context, task),
                      onEdit: () => _editTask(context, task),
                      onDelete: () => _deleteTask(context, task),
                      categoryColor:
                          CategoryUtils.getCategoryColor(task.category.name),
                      hasSubtasks: hasSubtasks,
                      isExpanded: isExpanded,
                      onToggleExpand: hasSubtasks
                          ? () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _expandedTasks[task.id] = !isExpanded;
                              });
                            }
                          : null,
                    ),
                    if (hasSubtasks && isExpanded)
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Column(
                          children: task.subtasks.map((subtask) {
                            return Column(
                              children: [
                                const CupertinoDivider(),
                                TaskListItem(
                                  task: subtask,
                                  onTap: () => _onTaskTap(context, subtask),
                                  onEdit: () => _editTask(context, subtask),
                                  onDelete: () => _deleteTask(context, subtask),
                                  categoryColor: CategoryUtils.getCategoryColor(
                                      subtask.category.name),
                                  hasSubtasks: subtask.subtasks.isNotEmpty,
                                  isExpanded:
                                      _expandedTasks[subtask.id] ?? false,
                                  onToggleExpand: subtask.subtasks.isNotEmpty
                                      ? () {
                                          HapticFeedback.selectionClick();
                                          setState(() {
                                            _expandedTasks[subtask.id] =
                                                !(_expandedTasks[subtask.id] ??
                                                    false);
                                          });
                                        }
                                      : null,
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    if (task != tasks.last) const CupertinoDivider(),
                  ],
                );
              }).toList(),
            ],
          ],
        ),
      );

  void _onTaskTap(BuildContext context, Task task) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => TaskPageScreen(task: task),
      ),
    );
  }

  void _editTask(BuildContext context, Task task) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => TaskPageScreen(task: task, isEditing: true),
      ),
    );
  }

  void _deleteTask(BuildContext context, Task task) {
    HapticFeedback.mediumImpact();
    final subtaskCount = task.subtasks.length;
    final message = subtaskCount > 0
        ? 'Are you sure you want to delete "${task.title}" and its ${subtaskCount} subtask${subtaskCount == 1 ? "" : "s"}?'
        : 'Are you sure you want to delete "${task.title}"?';

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Task'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              final tasksCubit = context.read<TaskManagerCubit>();
              tasksCubit.deleteTask(task);
              _clearCache();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pushReplacement(
                context,
                CupertinoPageRoute(
                  builder: (_) => const HomeScreen(initialIndex: 2),
                ),
              );
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.activeBlue,
              ),
              child: const Icon(
                CupertinoIcons.add,
                color: CupertinoColors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showScheduleDialog(context);
              _showScheduleConfirmation();
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.activeGreen,
              ),
              child: const Icon(
                CupertinoIcons.calendar,
                color: CupertinoColors.white,
                size: 28,
              ),
            ),
          ),
        ],
      );

  void _showScheduleConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Schedule Tasks'),
        content: const Text('Tasks have been scheduled successfully.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                  context,
                  CupertinoPageRoute(
                      builder: (_) => HomeScreen(initialIndex: 0)));
            },
          ),
        ],
      ),
    );
  }
}
