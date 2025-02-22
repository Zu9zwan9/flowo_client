// lib/screens/home_screen.dart
import 'package:cupertino_sidebar/cupertino_sidebar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flowo_client/screens/add_task_page.dart';
import 'package:flowo_client/screens/add_event_page.dart';
import 'package:flowo_client/screens/add_habit_page.dart';
import 'package:flowo_client/screens/profile_screen.dart';
import 'package:flowo_client/screens/settings_screen.dart';
import 'package:flowo_client/screens/task_list_screen.dart';
import 'calendar_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowo_client/blocs/calendar/calendar_cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool isExpanded = false;

  final _pages = const [
    CalendarScreen(),
    TaskListScreen(),
    AddTaskPage(),
    AddEventPage(),
    AddHabitPage(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Center(
            child: BlocProvider.value(
              value: context.read<CalendarCubit>(),
              child: _pages.elementAt(_selectedIndex),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: isExpanded ? 0 : -320,
            top: 0,
            bottom: 0,
            child: CupertinoSidebar(
              selectedIndex: _selectedIndex,
              maxWidth: 200,
              onDestinationSelected: (value) {
                setState(() {
                  _selectedIndex = value;
                  isExpanded = false;
                });
              },
              padding: const EdgeInsets.symmetric(vertical: 80),
              children: const [
                SidebarDestination(
                  icon: Icon(CupertinoIcons.calendar),
                  label: Text('Calendar'),
                ),
                SidebarDestination(
                  icon: Icon(CupertinoIcons.list_bullet),
                  label: Text('Tasks'),
                ),
                SidebarDestination(
                  icon: Icon(CupertinoIcons.add),
                  label: Text('Add Task'),
                ),
                SidebarDestination(
                  icon: Icon(CupertinoIcons.calendar_today),
                  label: Text('Add Event'),
                ),
                SidebarDestination(
                  icon: Icon(CupertinoIcons.repeat),
                  label: Text('Add Habit'),
                ),
                SidebarDestination(
                  icon: Icon(CupertinoIcons.person),
                  label: Text('Profile'),
                ),
                SidebarDestination(
                  icon: Icon(CupertinoIcons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                child: const Icon(CupertinoIcons.sidebar_left),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
