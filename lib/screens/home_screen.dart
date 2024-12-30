import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    const Center(child: Text('Profile')),
    const Center(child: Text('Settings')),
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
        backgroundColor: Colors.transparent,
        onTap: (index) async {
          if (index == 2) {
            final selectedDate = context.read<CalendarCubit>().state.selectedDate;
            final event = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddTaskForm(selectedDate: selectedDate)),
            );
            if (event != null) {
              setState(() {
                _selectedIndex = 0;
              });
            }
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        letIndexChange: (index) => true,
      ),
    );
  }
}
