import 'package:flowo_client/screens/event/event_form_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for HapticFeedback
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/tasks_controller/task_manager_cubit.dart';
import 'habit/habit_form_screen.dart';
import 'task/task_form_screen.dart';

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
          value: context.read<TaskManagerCubit>(),
          child: TaskFormScreen(selectedDate: widget.selectedDate),
        );
      case 1:
        return BlocProvider.value(
          key: const ValueKey('Event'),
          value: context.read<TaskManagerCubit>(),
          child: EventFormScreen(selectedDate: widget.selectedDate),
        );
      case 2:
        return BlocProvider.value(
          key: const ValueKey('Habit'),
          value: context.read<TaskManagerCubit>(),
          child: HabitFormScreen(selectedDate: widget.selectedDate),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                child: SingleChildScrollView(
                  key: ValueKey('Scroll_${_tabController.index}'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [_buildTabContent(_tabController.index)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector(BuildContext context) {
    final primaryColor = CupertinoTheme.of(context).primaryColor;
    final backgroundColor = CupertinoColors.systemGrey6.resolveFrom(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            _buildTabOption(
              icon: CupertinoIcons.checkmark_circle,
              text: 'Task',
              index: 0,
              primaryColor: primaryColor,
            ),
            _buildTabOption(
              icon: CupertinoIcons.calendar,
              text: 'Event',
              index: 1,
              primaryColor: primaryColor,
            ),
            _buildTabOption(
              icon: CupertinoIcons.repeat,
              text: 'Habit',
              index: 2,
              primaryColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabOption({
    required IconData icon,
    required String text,
    required int index,
    required Color primaryColor,
  }) {
    final isSelected = _tabController.index == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _tabController.index = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: double.infinity,
          decoration: BoxDecoration(
            color:
                isSelected
                    ? CupertinoColors.systemBackground.resolveFrom(context)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          margin: const EdgeInsets.all(2),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color:
                      isSelected
                          ? primaryColor
                          : CupertinoColors.systemGrey.resolveFrom(context),
                  semanticLabel: text,
                ),
                const SizedBox(width: 4),
                Text(
                  text,
                  style: TextStyle(
                    color:
                        isSelected
                            ? primaryColor
                            : CupertinoColors.systemGrey.resolveFrom(context),
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  semanticsLabel: '$text tab',
                ),
              ],
            ),
          ),
        ),
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
