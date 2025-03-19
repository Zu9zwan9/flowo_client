import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/tasks_controller/tasks_controller_cubit.dart';
import '../design/cupertino_form_theme.dart';
import 'add_event_page.dart';
import 'add_habit_page.dart';
import 'add_task_page.dart';

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
          value: context.read<CalendarCubit>(),
          child: AddTaskPage(selectedDate: widget.selectedDate),
        );
      case 1:
        return BlocProvider.value(
          key: const ValueKey('Event'),
          value: context.read<CalendarCubit>(),
          child: AddEventPage(selectedDate: widget.selectedDate),
        );
      case 2:
        return BlocProvider.value(
          key: const ValueKey('Habit'),
          value: context.read<CalendarCubit>(),
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
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Add Item'),
        border: null,
      ),
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
                borderColor: CupertinoColors.systemGrey4,
                selectedColor: theme.primaryColor,
                unselectedColor: CupertinoColors.systemBackground,
                pressedColor: theme.primaryColor.withOpacity(0.2),
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
