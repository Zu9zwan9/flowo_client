// lib/screens/add_item_screen.dart
import 'package:cupertino_sidebar/cupertino_sidebar.dart';
import 'package:flowo_client/blocs/tasks_controller/tasks_controller_cubit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    _tabController.addListener(() {
      setState(() {});
    });
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
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: CupertinoFloatingTabBar(
                controller: _tabController,
                onDestinationSelected: (index) {
                  setState(() {
                    _tabController.index = index;
                  });
                },
                tabs: const [
                  CupertinoFloatingTab(child: Text('Task')),
                  CupertinoFloatingTab(child: Text('Event')),
                  CupertinoFloatingTab(child: Text('Habit')),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: _buildTabContent(_tabController.index),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
