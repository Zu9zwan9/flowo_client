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
  }

  @override
  void dispose() {
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
    final theme = CupertinoFormTheme(context);
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(border: null),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CupertinoFormTheme.horizontalSpacing,
                vertical: CupertinoFormTheme.smallSpacing,
              ),
              child: CupertinoSegmentedControl<int>(
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: CupertinoFormTheme.smallSpacing,
                      vertical: CupertinoFormTheme.smallSpacing / 2,
                    ),
                    child: Text('Task'),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: CupertinoFormTheme.smallSpacing,
                      vertical: CupertinoFormTheme.smallSpacing / 2,
                    ),
                    child: Text('Event'),
                  ),
                  2: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: CupertinoFormTheme.smallSpacing,
                      vertical: CupertinoFormTheme.smallSpacing / 2,
                    ),
                    child: Text('Habit'),
                  ),
                },
                groupValue: _tabController.index,
                onValueChanged:
                    (index) => setState(() => _tabController.index = index),
                borderColor: CupertinoColors.transparent,
                selectedColor:
                    CupertinoTheme.of(context).brightness == Brightness.dark
                        ? CupertinoColors.activeBlue
                        : theme.primaryColor,
                unselectedColor:
                    CupertinoTheme.of(context).brightness == Brightness.dark
                        ? CupertinoColors.systemGrey6.darkColor
                        : CupertinoColors.systemBackground,
                pressedColor: (CupertinoTheme.of(context).brightness ==
                            Brightness.dark
                        ? CupertinoColors.activeBlue
                        : theme.primaryColor)
                    .withOpacity(0.2),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder:
                    (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                child: _buildTabContent(_tabController.index),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
