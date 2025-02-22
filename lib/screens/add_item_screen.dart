// lib/screens/add_item_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowo_client/blocs/calendar/calendar_cubit.dart';
import 'add_task_page.dart';
import 'add_event_page.dart';
import 'add_habit_page.dart';

class AddItemScreen extends StatelessWidget {
  final DateTime? selectedDate;

  const AddItemScreen({super.key, this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.list_bullet), label: 'Task'),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.calendar), label: 'Event'),
          BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.repeat), label: 'Habit'),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return BlocProvider.value(
              value: context.read<CalendarCubit>(),
              child: AddTaskPage(selectedDate: selectedDate),
            );
          case 1:
            return BlocProvider.value(
              value: context.read<CalendarCubit>(),
              child: AddEventPage(selectedDate: selectedDate),
            );
          case 2:
            return BlocProvider.value(
              value: context.read<CalendarCubit>(),
              child: AddHabitPage(selectedDate: selectedDate),
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}
