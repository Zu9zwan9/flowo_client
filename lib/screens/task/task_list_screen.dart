import 'package:flowo_client/screens/habit/habit_details_screen.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/tasks_controller/task_manager_cubit.dart';
import '../../blocs/tasks_controller/task_manager_state.dart';
import '../../models/task.dart';
import '../../utils/category_utils.dart';
import '../../utils/debouncer.dart';
import '../event/event_form_screen.dart';
import '../event/event_screen.dart';
import '../habit/habit_form_screen.dart';
import '../home_screen.dart';
import '../widgets/cupertino_divider.dart';
import '../widgets/task_list_components.dart';
import '../widgets/task_list_item.dart';
import '../widgets/aurora_sphere_button.dart';
import '../widgets/add_task_aurora_sphere_button.dart';
import 'task_form_screen.dart';
import 'task_page_screen.dart';
import 'task_statistics_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _searchDebouncer = Debouncer(Duration(milliseconds: 300));
  TaskFilterType _selectedFilter = TaskFilterType.all;
  GroupingOption _selectedGrouping =
      GroupingOption.none; // Selected grouping option
  TaskViewMode _selectedViewMode = TaskViewMode.leaf; // Selected view mode
  final Map<String, bool> _expandedCategories = {};
  final Map<String, bool> _expandedTasks = {};
  String _searchQuery = '';
  late final ScrollController _scrollController;
  final bool _schedulingStatus =
      true; // true = all good, false = needs attention
  final int _tasksToSchedule = 0; // Number of tasks that need scheduling

  // Caching to improve performance
  Map<String, List<Task>>? _filteredTasksCache; // Cache for grouped tasks
  List<Task>? _filteredFlatTasksCache; // Cache for flat list tasks
  String? _lastQuery;
  TaskFilterType? _lastFilter;
  GroupingOption? _lastGrouping;
  TaskViewMode? _lastViewMode;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController = ScrollController();
    WidgetsBinding.instance.addObserver(this);

    // Check scheduling status after a short delay to allow the UI to build
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkSchedulingStatus();
    });
  }

  // Check the scheduling status of tasks
  void _checkSchedulingStatus() {
    if (!mounted) return;

    final tasksCubit = context.read<TaskManagerCubit>();
    final tasks = tasksCubit.state.tasks;
    final scheduledTasks = tasksCubit.getScheduledTasks();
    // TODO: Implement logic to check scheduling status
  }

  // Handle search input changes with debouncing
  void _onSearchChanged() {
    _searchDebouncer.call(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim();
          _clearCache();
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Clear cache when dependencies change (e.g., screen becomes visible)
    _clearCache();
    _checkSchedulingStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebouncer.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Clear cache when app is resumed
      _clearCache();
    }
  }

  // Determine the type of task (task, event, habit)
  TaskFilterType _getTaskType(Task task) {
    final categoryName = task.category.name.toLowerCase();
    if (categoryName.contains('event')) {
      return TaskFilterType.event;
    }
    if (task.frequency != null) {
      return TaskFilterType.habit;
    }
    return TaskFilterType.task;
  }

  // Filter tasks based on search query, filter type, and view mode
  List<Task> _filterTasks(List<Task> tasks) {
    final query = _searchQuery.toLowerCase();
    return tasks.where((task) {
      final matchesQuery = task.title.toLowerCase().contains(query);
      final type = _getTaskType(task);
      final matchesFilter =
          _selectedFilter == TaskFilterType.all || _selectedFilter == type;
      final matchesViewMode =
          _selectedViewMode == TaskViewMode.topLevel
              ? task.parentTaskId == null
              : task.subtaskIds.isEmpty;
      final matchesCategory = task.category.name != 'Free Time Manager';
      return matchesQuery &&
          matchesFilter &&
          matchesViewMode &&
          matchesCategory;
    }).toList();
  }

  // Group tasks by category
  Map<String, List<Task>> _groupTasksByCategory(List<Task> tasks) {
    final Map<String, List<Task>> grouped = {};
    for (final task in tasks) {
      grouped.putIfAbsent(task.category.name, () => []).add(task);
    }
    // Sort categories alphabetically
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  // Get filtered tasks based on grouping option
  dynamic _getFilteredTasks(List<Task> tasks) {
    if (_selectedGrouping == GroupingOption.category) {
      if (_filteredTasksCache != null &&
          _lastQuery == _searchQuery &&
          _lastFilter == _selectedFilter &&
          _lastGrouping == _selectedGrouping &&
          _lastViewMode == _selectedViewMode) {
        return _filteredTasksCache;
      }
      final filtered = _filterTasks(tasks);
      final grouped = _groupTasksByCategory(filtered);
      _filteredTasksCache = grouped;
    } else {
      if (_filteredFlatTasksCache != null &&
          _lastQuery == _searchQuery &&
          _lastFilter == _selectedFilter &&
          _lastGrouping == _selectedGrouping &&
          _lastViewMode == _selectedViewMode) {
        return _filteredFlatTasksCache;
      }
      final filtered = _filterTasks(tasks);
      _filteredFlatTasksCache = filtered;
    }
    _lastQuery = _searchQuery;
    _lastFilter = _selectedFilter;
    _lastGrouping = _selectedGrouping;
    _lastViewMode = _selectedViewMode;
    return _selectedGrouping == GroupingOption.category
        ? _filteredTasksCache
        : _filteredFlatTasksCache;
  }

  // Clear the cache to force re-filtering
  void _clearCache() {
    _filteredTasksCache = null;
    _filteredFlatTasksCache = null;
    _lastQuery = null;
    _lastFilter = null;
    _lastGrouping = null;
    _lastViewMode = null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskManagerCubit, TaskManagerState>(
      listenWhen: (previous, current) {
        return previous.tasks.length != current.tasks.length;
      },
      listener: (context, state) {
        _clearCache();
        _checkSchedulingStatus();
      },
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: TaskSearchBar(controller: _searchController),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildFilterTabs(context),
                ),
                const SizedBox(height: 12),
                // Grouping and view mode controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(child: _buildGroupingControl(context)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildViewModeControl(context)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildTaskList(context)),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AddTaskAuroraSphereButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pushReplacement(
                        context,
                        CupertinoPageRoute(
                          builder:
                              (context) => const HomeScreen(
                                initialIndex: 2,
                                initialExpanded: false,
                              ),
                        ),
                      );
                    },
                    size: 50.0,
                  ),
                  const SizedBox(height: 8),
                  AuroraSphereButton(
                    onPressed: () => _showScheduleDialog(context),
                    status: _schedulingStatus,
                    size: 50.0,
                    label: 'Tasks',
                    tasksToSchedule: _tasksToSchedule,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show scheduling dialog and navigate to statistics screen
  void _showScheduleDialog(BuildContext context) {
    HapticFeedback.mediumImpact();

    final tasksCubit = context.read<TaskManagerCubit>();
    tasksCubit.scheduleHabits();
    tasksCubit.scheduleTasks();
    _clearCache();

    _checkSchedulingStatus();

    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => const TaskStatisticsScreen()),
    ).then((_) {
      _checkSchedulingStatus();
    });
  }

  // Build the task list based on grouping
  Widget _buildTaskList(BuildContext context) =>
      BlocBuilder<TaskManagerCubit, TaskManagerState>(
        builder: (context, state) {
          final tasks = state.tasks;
          final filteredTasks = _getFilteredTasks(tasks);

          if (filteredTasks.isEmpty) {
            return _buildEmptyState(context);
          }

          if (_selectedGrouping == GroupingOption.category) {
            return _buildGroupedTaskList(
              filteredTasks as Map<String, List<Task>>,
            );
          } else {
            return _buildFlatTaskList(filteredTasks as List<Task>);
          }
        },
      );

  // Build a grouped task list by category
  Widget _buildGroupedTaskList(Map<String, List<Task>> groupedTasks) {
    return CupertinoScrollbar(
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: groupedTasks.length,
        itemBuilder: (context, index) {
          final category = groupedTasks.keys.elementAt(index);
          final tasks = groupedTasks[category]!;
          final isExpanded = _expandedCategories[category] ?? true;
          return _buildCategorySection(context, category, tasks, isExpanded);
        },
      ),
    );
  }

  // Build a flat task list
  Widget _buildFlatTaskList(List<Task> tasks) {
    return CupertinoScrollbar(
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          final hasSubtasks = task.subtaskIds.isNotEmpty;
          final isExpanded = _expandedTasks[task.id] ?? false;
          final parentTask =
              _selectedViewMode == TaskViewMode.leaf
                  ? context.read<TaskManagerCubit>().getParentTask(task)
                  : null;
          return _buildTaskListItem(
            context,
            task,
            hasSubtasks,
            isExpanded,
            parentTask,
          );
        },
      ),
    );
  }

  // Build an individual task list item with subtasks
  Widget _buildTaskListItem(
    BuildContext context,
    Task task,
    bool hasSubtasks,
    bool isExpanded, [
    Task? parentTask,
  ]) {
    return Column(
      children: [
        TaskListItem(
          task: task,
          taskManagerCubit: context.read<TaskManagerCubit>(),
          onTap: () => _onTaskTap(context, task),
          onEdit: () => _editTask(context, task),
          onDelete: () => _deleteTask(context, task),
          categoryColor: CategoryUtils.getCategoryColor(task.category.name),
          hasSubtasks: hasSubtasks,
          isExpanded: isExpanded,
          parentTask: parentTask,
          showParentTask:
              _selectedViewMode == TaskViewMode.leaf && parentTask != null,
          onToggleExpand:
              hasSubtasks
                  ? () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _expandedTasks[task.id] = !isExpanded;
                    });
                  }
                  : null,
          onToggleCompletion: () => _toggleTaskCompletion(context, task),
        ),
        if (hasSubtasks && isExpanded)
          Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6
                  .resolveFrom(context)
                  .withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            margin: const EdgeInsets.only(left: 20),
            child: Column(
              children:
                  context.read<TaskManagerCubit>().getSubtasksForTask(task).map(
                    (subtask) {
                      return Column(
                        children: [
                          const CupertinoDivider(),
                          TaskListItem(
                            task: subtask,
                            taskManagerCubit: context.read<TaskManagerCubit>(),
                            onTap: () => _onTaskTap(context, subtask),
                            onEdit: () => _editTask(context, subtask),
                            onDelete: () => _deleteTask(context, subtask),
                            categoryColor: CategoryUtils.getCategoryColor(
                              subtask.category.name,
                            ),
                            hasSubtasks: subtask.subtaskIds.isNotEmpty,
                            isExpanded: _expandedTasks[subtask.id] ?? false,
                            parentTask: task,
                            showParentTask:
                                _selectedViewMode == TaskViewMode.leaf,
                            onToggleExpand:
                                subtask.subtaskIds.isNotEmpty
                                    ? () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _expandedTasks[subtask.id] =
                                            !(_expandedTasks[subtask.id] ??
                                                false);
                                      });
                                    }
                                    : null,
                            onToggleCompletion:
                                () => _toggleTaskCompletion(context, subtask),
                          ),
                        ],
                      );
                    },
                  ).toList(),
            ),
          ),
      ],
    );
  }

  // Build empty state when no tasks match the filter
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.doc_text_search,
            size: 48,
            color: CupertinoTheme.of(context).primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks match your filter',
            style: TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Build a category section for grouped tasks
  Widget _buildCategorySection(
    BuildContext context,
    String category,
    List<Task> tasks,
    bool isExpanded,
  ) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = CupertinoColors.systemBackground.resolveFrom(
      context,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey5
                .resolveFrom(context)
                .withOpacity(isDarkMode ? 0.15 : 0.4),
            blurRadius: 5,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _expandedCategories[category] = !isExpanded);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6
                      .resolveFrom(context)
                      .withOpacity(0.6),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            CategoryUtils.getCategoryIcon(category),
                            size: 18,
                            color: CategoryUtils.getCategoryColor(category),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              category,
                              style: CupertinoTheme.of(
                                context,
                              ).textTheme.navTitleTextStyle.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                overflow: TextOverflow.visible,
                              ),
                              semanticsLabel: '$category category',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoTheme.of(context).primaryColor
                                  .withOpacity(isDarkMode ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${tasks.length}',
                              style: TextStyle(
                                color: CupertinoTheme.of(context).primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                      size: 18,
                      color: CupertinoTheme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded) ...[
              const CupertinoDivider(),
              ...tasks.map((task) {
                final hasSubtasks = task.subtaskIds.isNotEmpty;
                final isExpanded = _expandedTasks[task.id] ?? false;
                return Column(
                  children: [
                    TaskListItem(
                      task: task,
                      taskManagerCubit: context.read<TaskManagerCubit>(),
                      onTap: () => _onTaskTap(context, task),
                      onEdit: () => _editTask(context, task),
                      onDelete: () => _deleteTask(context, task),
                      categoryColor: CategoryUtils.getCategoryColor(
                        task.category.name,
                      ),
                      hasSubtasks: hasSubtasks,
                      isExpanded: isExpanded,
                      parentTask:
                          _selectedViewMode == TaskViewMode.leaf
                              ? context.read<TaskManagerCubit>().getParentTask(
                                task,
                              )
                              : null,
                      showParentTask:
                          _selectedViewMode == TaskViewMode.leaf &&
                          task.parentTaskId != null,
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
                      Container(
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6
                              .resolveFrom(context)
                              .withOpacity(isDarkMode ? 0.5 : 0.3),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        margin: const EdgeInsets.only(left: 20),
                        child: Column(
                          children:
                              context
                                  .read<TaskManagerCubit>()
                                  .getSubtasksForTask(task)
                                  .map((subtask) {
                                    return Column(
                                      children: [
                                        const CupertinoDivider(),
                                        TaskListItem(
                                          task: subtask,
                                          taskManagerCubit:
                                              context.read<TaskManagerCubit>(),
                                          onTap:
                                              () =>
                                                  _onTaskTap(context, subtask),
                                          onEdit:
                                              () => _editTask(context, subtask),
                                          onDelete:
                                              () =>
                                                  _deleteTask(context, subtask),
                                          categoryColor:
                                              CategoryUtils.getCategoryColor(
                                                subtask.category.name,
                                              ),
                                          hasSubtasks:
                                              subtask.subtaskIds.isNotEmpty,
                                          isExpanded:
                                              _expandedTasks[subtask.id] ??
                                              false,
                                          parentTask: task,
                                          showParentTask:
                                              _selectedViewMode ==
                                              TaskViewMode.leaf,
                                          onToggleExpand:
                                              subtask.subtaskIds.isNotEmpty
                                                  ? () {
                                                    HapticFeedback.selectionClick();
                                                    setState(() {
                                                      _expandedTasks[subtask
                                                              .id] =
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
                                  })
                                  .toList(),
                        ),
                      ),
                    if (task != tasks.last) const CupertinoDivider(),
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // Navigate to the appropriate task detail screen
  void _onTaskTap(BuildContext context, Task task) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) {
          if (task.frequency != null) {
            return HabitDetailsScreen(habit: task);
          } else if (task.category.name.toLowerCase().contains('event')) {
            return EventScreen(event: task);
          }
          return TaskPageScreen(task: task);
        },
      ),
    );
  }

  // Navigate to the task editing screen
  void _editTask(BuildContext context, Task task) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) {
          if (task.category.name.toLowerCase().contains('event')) {
            return EventFormScreen(event: task);
          } else if (task.frequency != null) {
            return HabitFormScreen(habit: task);
          } else {
            return TaskFormScreen(task: task);
          }
        },
      ),
    );
  }

  // Show confirmation dialog and delete task
  void _deleteTask(BuildContext context, Task task) {
    HapticFeedback.mediumImpact();
    final subtaskCount = task.subtaskIds.length;
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

  // Toggle task completion and show a toast notification
  void _toggleTaskCompletion(BuildContext context, Task task) {
    HapticFeedback.selectionClick();
    final tasksCubit = context.read<TaskManagerCubit>();
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final textColor = CupertinoTheme.of(context).textTheme.textStyle.color;

    tasksCubit.toggleTaskCompletion(task).then((isCompleted) {
      if (!mounted) return;
      _clearCache();
      final message =
          isCompleted
              ? 'Task "${task.title}" marked as completed'
              : 'Task "${task.title}" marked as incomplete';

      final overlay = OverlayEntry(
        builder:
            (context) => Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: (isDarkMode
                            ? CupertinoColors.systemGrey6.darkColor
                            : CupertinoColors.white)
                        .withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDarkMode
                                ? CupertinoColors.black.withOpacity(0.1)
                                : CupertinoColors.systemGrey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted
                            ? CupertinoIcons.check_mark_circled
                            : CupertinoIcons.xmark_circle,
                        color:
                            isCompleted
                                ? CupertinoColors.activeGreen
                                : CupertinoColors.systemRed,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          message,
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      );
      Overlay.of(context).insert(overlay);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          overlay.remove();
        }
      });
    });
  }

  // Build filter tabs for task types
  Widget _buildFilterTabs(BuildContext context) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    final backgroundColor = CupertinoColors.systemGrey6.resolveFrom(context);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children:
            TaskFilterType.values.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedFilter = filter;
                      _clearCache();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? CupertinoColors.systemBackground.resolveFrom(
                                context,
                              )
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    margin: const EdgeInsets.all(2),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getFilterIcon(filter),
                            size: 18,
                            color:
                                isSelected
                                    ? primaryColor
                                    : CupertinoColors.systemGrey.resolveFrom(
                                      context,
                                    ),
                            semanticLabel: _getFilterName(filter),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getFilterName(filter),
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? primaryColor
                                      : CupertinoColors.systemGrey.resolveFrom(
                                        context,
                                      ),
                              fontSize: 14,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                            semanticsLabel: '${_getFilterName(filter)} filter',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  // Get icon for filter type
  IconData _getFilterIcon(TaskFilterType filter) {
    switch (filter) {
      case TaskFilterType.all:
        return CupertinoIcons.square_grid_2x2;
      case TaskFilterType.task:
        return CupertinoIcons.check_mark_circled;
      case TaskFilterType.event:
        return CupertinoIcons.calendar;
      case TaskFilterType.habit:
        return CupertinoIcons.arrow_2_circlepath;
    }
  }

  // Get name for filter type
  String _getFilterName(TaskFilterType filter) {
    switch (filter) {
      case TaskFilterType.all:
        return 'All';
      case TaskFilterType.task:
        return 'Tasks';
      case TaskFilterType.event:
        return 'Events';
      case TaskFilterType.habit:
        return 'Habits';
    }
  }

  // Build grouping control dropdown
  Widget _buildGroupingControl(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        HapticFeedback.selectionClick();
        showCupertinoModalPopup(
          context: context,
          builder:
              (context) => CupertinoActionSheet(
                title: const Text('Group by'),
                actions:
                    GroupingOption.values.map((option) {
                      return CupertinoActionSheetAction(
                        onPressed: () {
                          setState(() {
                            _selectedGrouping = option;
                            _clearCache();
                          });
                          Navigator.pop(context);
                        },
                        child: Text(option.displayName),
                      );
                    }).toList(),
                cancelButton: CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.group,
              size: 18,
              color: CupertinoTheme.of(context).primaryColor,
            ),
            const SizedBox(width: 4),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Group by: ${_selectedGrouping.displayName}',
                style: TextStyle(
                  color: CupertinoTheme.of(context).primaryColor,
                  fontSize: 14,
                ),
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build view mode segmented control
  Widget _buildViewModeControl(BuildContext context) {
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    final backgroundColor = CupertinoColors.systemGrey6.resolveFrom(context);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children:
            TaskViewMode.values.map((mode) {
              final isSelected = _selectedViewMode == mode;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedViewMode = mode;
                      _clearCache();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? CupertinoColors.systemBackground.resolveFrom(
                                context,
                              )
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    margin: const EdgeInsets.all(2),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getViewModeIcon(mode),
                            size: 18,
                            color:
                                isSelected
                                    ? primaryColor
                                    : CupertinoColors.systemGrey.resolveFrom(
                                      context,
                                    ),
                            semanticLabel: _getViewModeName(mode),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getViewModeName(mode),
                            style: TextStyle(
                              color:
                                  isSelected
                                      ? primaryColor
                                      : CupertinoColors.systemGrey.resolveFrom(
                                        context,
                                      ),
                              fontSize: 14,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                            semanticsLabel:
                                '${_getViewModeName(mode)} view mode',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  // Get icon for view mode
  IconData _getViewModeIcon(TaskViewMode mode) {
    switch (mode) {
      case TaskViewMode.topLevel:
        return CupertinoIcons.square_stack_3d_up;
      case TaskViewMode.leaf:
        return CupertinoIcons.list_bullet_below_rectangle;
    }
  }

  // Get name for view mode
  String _getViewModeName(TaskViewMode mode) {
    switch (mode) {
      case TaskViewMode.topLevel:
        return 'Tasks';
      case TaskViewMode.leaf:
        return 'Leaf';
    }
  }
}

// Enum for grouping options
enum GroupingOption { none, category }

extension GroupingOptionExtension on GroupingOption {
  String get displayName {
    switch (this) {
      case GroupingOption.none:
        return 'None';
      case GroupingOption.category:
        return 'Category';
    }
  }
}

// Enum for task view modes
enum TaskViewMode { topLevel, leaf }

// Enum for task filter types
enum TaskFilterType { all, task, event, habit }

extension TaskFilterTypeExtension on TaskFilterType {
  String get displayName => _getFilterNameForType(this);

  IconData get icon => _getIconForType(this);

  static String _getFilterNameForType(TaskFilterType type) {
    switch (type) {
      case TaskFilterType.all:
        return 'All';
      case TaskFilterType.task:
        return 'Tasks';
      case TaskFilterType.event:
        return 'Events';
      case TaskFilterType.habit:
        return 'Habits';
    }
  }

  static IconData _getIconForType(TaskFilterType type) {
    switch (type) {
      case TaskFilterType.all:
        return CupertinoIcons.square_grid_2x2;
      case TaskFilterType.task:
        return CupertinoIcons.check_mark_circled;
      case TaskFilterType.event:
        return CupertinoIcons.calendar;
      case TaskFilterType.habit:
        return CupertinoIcons.arrow_2_circlepath;
    }
  }
}
