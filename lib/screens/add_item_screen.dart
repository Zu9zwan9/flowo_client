import 'package:flowo_client/screens/event/event_form_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/tasks_controller/task_manager_cubit.dart';
import '../design/cupertino_form_theme.dart';
import 'habit/add_habit_page.dart';
import 'task/add_task_page.dart';

class AddItemScreen extends StatefulWidget {
  final DateTime? selectedDate;

  const AddItemScreen({super.key, this.selectedDate});

  @override
  _AddItemScreenState createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return BlocProvider.value(
          key: const ValueKey('Task'),
          value:
              context.read<TaskManagerCubit>(), // Corrected from CalendarCubit
          child: AddTaskPage(selectedDate: widget.selectedDate),
        );
      case 1:
        return BlocProvider.value(
          key: const ValueKey('Event'),
          value:
              context.read<TaskManagerCubit>(), // Corrected from CalendarCubit
          child: EventFormScreen(selectedDate: widget.selectedDate),
        );
      case 2:
        return BlocProvider.value(
          key: const ValueKey('Habit'),
          value:
              context.read<TaskManagerCubit>(), // Corrected from CalendarCubit
          child: AddHabitPage(selectedDate: widget.selectedDate),
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Add New Item'),
        border: null,
        backgroundColor: CupertinoTheme.of(
          context,
        ).barBackgroundColor.withOpacity(0.8),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildTabSelector(context),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder:
                    (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                child: _buildTabContent(_tabController.index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabOption({
    required IconData icon,
    required String text,
    required bool isDarkMode,
  }) {
    final textColor =
        isDarkMode
            ? _tabController.index == getTabIndex(text)
                ? CupertinoColors.activeBlue
                : CupertinoColors.white
            : _tabController.index == getTabIndex(text)
            ? CupertinoTheme.of(context).primaryColor
            : CupertinoColors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CupertinoFormTheme.smallSpacing,
        vertical: CupertinoFormTheme.smallSpacing / 1.5,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight:
                  _tabController.index == getTabIndex(text)
                      ? FontWeight.w600
                      : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(BuildContext context) {
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;
    final primaryColor = CupertinoTheme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: CupertinoFormTheme.horizontalSpacing,
        vertical: CupertinoFormTheme.smallSpacing,
      ),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? CupertinoColors.systemGrey6.darkColor
                : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
      ),
      child: CupertinoSegmentedControl<int>(
        children: {
          0: _buildTabOption(
            icon: CupertinoIcons.checkmark_circle,
            text: 'Task',
            isDarkMode: isDarkMode,
          ),
          1: _buildTabOption(
            icon: CupertinoIcons.calendar,
            text: 'Event',
            isDarkMode: isDarkMode,
          ),
          2: _buildTabOption(
            icon: CupertinoIcons.repeat,
            text: 'Habit',
            isDarkMode: isDarkMode,
          ),
        },
        groupValue: _tabController.index,
        onValueChanged: (index) => setState(() => _tabController.index = index),
        borderColor: CupertinoColors.transparent,
        selectedColor:
            isDarkMode
                ? CupertinoColors.systemBackground.darkColor
                : CupertinoColors.white,
        unselectedColor: CupertinoColors.transparent,
        pressedColor: primaryColor.withOpacity(0.1),
      ),
    );
  }

  int getTabIndex(String tabName) {
    switch (tabName) {
      case 'Task':
        return 0;
      case 'Event':
        return 1;
      case 'Habit':
        return 2;
      default:
        return 0;
    }
  }
}
