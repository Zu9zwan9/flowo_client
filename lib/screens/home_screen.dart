import 'package:flowo_client/screens/profile_screen.dart';
import 'package:flowo_client/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/event_model.dart';
import 'calendar_screen.dart';
import 'task_list_screen.dart';
import '../screens/add_task_form.dart';
import '../blocs/calendar/calendar_cubit.dart';
import '../blocs/calendar/calendar_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const CalendarScreen(),
    const TaskListScreen(),
    const Center(child: Text('Add Task')),
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 60.0,
        items: const <Widget>[
          Icon(Icons.calendar_today, size: 30),
          Icon(Icons.list, size: 30),
          Icon(Icons.add, size: 30, color: Colors.blueAccent),
          Icon(Icons.person, size: 30),
          Icon(Icons.settings, size: 30),
        ],
        color: Colors.white,
        buttonBackgroundColor: Colors.white,
        backgroundColor: Colors.white,
        onTap: (index) async {
          if (index == 2) {
            final selectedDate = context.read<CalendarCubit>().state.selectedDate;
            final event = await showModalBottomSheet<Event>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => DraggableScrollableSheet(
                initialChildSize: 0.5,
                minChildSize: 0.4,
                maxChildSize: 0.8,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: AddTaskForm(
                      selectedDate: selectedDate,
                      scrollController: scrollController,
                    ),
                  );
                },
              ),
            );
            if (event != null) {
              context.read<CalendarCubit>().addEvent(event);
            }
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        letIndexChange: (index) => index < _screens.length,
      ),
    );
  }
}
