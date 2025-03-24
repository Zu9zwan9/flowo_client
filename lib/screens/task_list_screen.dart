import 'package:flowo_client/screens/habit_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/tasks_controller/task_manager_cubit.dart';
import '../blocs/tasks_controller/task_manager_state.dart';
import '../models/task.dart';
import '../utils/category_utils.dart';
import '../utils/debouncer.dart';
import 'event_screen.dart';
import 'home_screen.dart';
import 'task_page_screen.dart';
import 'widgets/cupertino_divider.dart';
import 'widgets/task_list_components.dart';
import 'widgets/task_list_item.dart';

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
    if (task.category.name.toLowerCase().contains('event')) {
      return TaskFilterType.event;
    }
    if (task.frequency != null) return TaskFilterType.habit;
    return TaskFilterType.task;
  }

  Map<String, List<Task>>? _filteredTasksCache;
  String? _lastQuery;
  TaskFilterType? _lastFilter;

  Map<String, List<Task>> _filterGroupedTasks(
    Map<String, List<Task>> groupedTasks,
  ) {
    if (_filteredTasksCache != null &&
        _lastQuery == _searchQuery &&
        _lastFilter == _selectedFilter) {
      return _filteredTasksCache!;
    }

    final query = _searchQuery.toLowerCase();
    final filtered = <String, List<Task>>{};

    groupedTasks.forEach((category, tasks) {
      final tasksFiltered =
          tasks.where((task) {
            final matchesQuery = task.title.toLowerCase().contains(query);
            final type = _getTaskType(task);
            final matchesFilter =
                _selectedFilter == TaskFilterType.all ||
                _selectedFilter == type;
            return matchesQuery && matchesFilter;
          }).toList();

      if (tasksFiltered.isNotEmpty) {
        filtered[category] = tasksFiltered;
      }
    });

    _filteredTasksCache = filtered;
    _lastQuery = _searchQuery;
    _lastFilter = _selectedFilter;

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TaskSearchBar(controller: _searchController),
              ),
              const SizedBox(height: 8),
              TaskTypeFilter(
                selectedFilter: _selectedFilter,
                onFilterChanged: (filter) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedFilter = filter;
                    _clearCache();
                  });
                },
              ),
              Expanded(child: _buildTaskList(context)),
            ],
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
        builder:
            (context) =>
                const HomeScreen(initialIndex: 2, initialExpanded: false),
      ),
    );
  }

  void _showScheduleDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    final tasksCubit = context.read<TaskManagerCubit>();
    tasksCubit.scheduleTasks();
    tasksCubit.scheduleHabits();
    _clearCache();
  }

  Widget _buildTaskList(BuildContext context) =>
      BlocBuilder<TaskManagerCubit, TaskManagerState>(
        builder: (context, state) {
          final groupedTasks = _groupTasksByCategory(state.tasks);
          final filteredTasks = _filterGroupedTasks(groupedTasks);
          if (filteredTasks.isEmpty) {
            return const Center(
              child: Text(
                'No tasks match your filter',
                style: TextStyle(color: CupertinoColors.systemGrey),
              ),
            );
          }

          return CupertinoScrollbar(
            child: ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final category = filteredTasks.keys.elementAt(index);
                final tasks = filteredTasks[category]!;
                final isExpanded = _expandedCategories[category] ?? true;
                return _buildCategorySection(
                  context,
                  category,
                  tasks,
                  isExpanded,
                );
              },
            ),
          );
        },
      );

  Map<String, List<Task>> _groupTasksByCategory(List<Task> tasks) {
    final grouped = <String, List<Task>>{};
    for (var task in tasks) {
      if (task.parentTaskId == null) {
        grouped.putIfAbsent(task.category.name, () => []).add(task);
      }
    }
    return grouped;
  }

  Widget _buildCategorySection(
    BuildContext context,
    String category,
    List<Task> tasks,
    bool isExpanded,
  ) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).barBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? CupertinoColors.black.withOpacity(0.2)
                    : CupertinoColors.systemGrey5.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
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
                          .copyWith(fontSize: 17, fontWeight: FontWeight.w600),
                      semanticsLabel: '$category category',
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? CupertinoColors.systemGrey6.darkColor
                                : CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: TextStyle(
                          color:
                              CupertinoTheme.of(
                                context,
                              ).textTheme.tabLabelTextStyle.color,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
                    categoryColor: CategoryUtils.getCategoryColor(
                      task.category.name,
                    ),
                    hasSubtasks: hasSubtasks,
                    isExpanded: isExpanded,
                    onToggleExpand:
                        hasSubtasks
                            ? () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _expandedTasks[task.id] = !isExpanded;
                              });
                            }
                            : null,
                    onToggleCompletion:
                        () => _toggleTaskCompletion(context, task),
                  ),
                  if (hasSubtasks && isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Column(
                        children:
                            task.subtasks.map((subtask) {
                              return Column(
                                children: [
                                  const CupertinoDivider(),
                                  TaskListItem(
                                    task: subtask,
                                    onTap: () => _onTaskTap(context, subtask),
                                    onEdit: () => _editTask(context, subtask),
                                    onDelete:
                                        () => _deleteTask(context, subtask),
                                    categoryColor:
                                        CategoryUtils.getCategoryColor(
                                          subtask.category.name,
                                        ),
                                    hasSubtasks: subtask.subtasks.isNotEmpty,
                                    isExpanded:
                                        _expandedTasks[subtask.id] ?? false,
                                    onToggleExpand:
                                        subtask.subtasks.isNotEmpty
                                            ? () {
                                              HapticFeedback.selectionClick();
                                              setState(() {
                                                _expandedTasks[subtask.id] =
                                                    !(_expandedTasks[subtask
                                                            .id] ??
                                                        false);
                                              });
                                            }
                                            : null,
                                    onToggleCompletion:
                                        () => _toggleTaskCompletion(
                                          context,
                                          subtask,
                                        ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  if (task != tasks.last) const CupertinoDivider(),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  void _onTaskTap(BuildContext context, Task task) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => TaskPageScreen(task: task)),
    );
  }

  void _editTask(BuildContext context, Task task) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) {
          if (task.category.name.toLowerCase().contains('event')) {
            return EventScreen(event: task);
          } else if (task.frequency != null) {
            return HabitScreen(); // TODO: Add analytics data to habit screen
          } else {
            return TaskPageScreen(task: task, isEditing: true);
          }
        },
      ),
    );
  }

  void _deleteTask(BuildContext context, Task task) {
    HapticFeedback.mediumImpact();
    final subtaskCount = task.subtasks.length;
    final message =
        subtaskCount > 0
            ? 'Are you sure you want to delete "${task.title}" and its $subtaskCount subtask${subtaskCount == 1 ? "" : "s"}?'
            : 'Are you sure you want to delete "${task.title}"?';

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
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

  void _toggleTaskCompletion(BuildContext context, Task task) {
    HapticFeedback.selectionClick();
    final tasksCubit = context.read<TaskManagerCubit>();
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    tasksCubit.toggleTaskCompletion(task).then((isCompleted) {
      _clearCache();
      final message =
          isCompleted
              ? 'Task "${task.title}" marked as completed'
              : 'Task "${task.title}" marked as incomplete';

      final overlay = OverlayEntry(
        builder:
            (context) => Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDarkMode
                            ? CupertinoColors.darkBackgroundGray.withOpacity(
                              0.9,
                            )
                            : CupertinoColors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color:
                          CupertinoTheme.of(context).textTheme.textStyle.color,
                    ),
                  ),
                ),
              ),
            ),
      );

      Overlay.of(context).insert(overlay);
      Future.delayed(const Duration(seconds: 1), () {
        overlay.remove();
      });
    });
  }
}
