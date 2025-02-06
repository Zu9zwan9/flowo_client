import 'package:flowo_client/screens/profile_screen.dart';
import 'package:flowo_client/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import 'calendar_screen.dart';
import 'task_list_screen.dart';
import '../screens/add_task_form.dart';
import '../blocs/calendar/calendar_cubit.dart';
import '../utils/logger.dart';
import '../theme_notifier.dart';

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
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    logInfo('Building HomeScreen');
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 60.0,
        items: <Widget>[
          Icon(Icons.calendar_today, size: 30, color: themeNotifier.iconColor),
          Icon(Icons.list, size: 30, color: themeNotifier.iconColor),
          Icon(Icons.add, size: 30, color: Colors.blueAccent),
          Icon(Icons.person, size: 30, color: themeNotifier.iconColor),
          Icon(Icons.settings, size: 30, color: themeNotifier.iconColor),
        ],
        color: themeNotifier.menuBackgroundColor,
        buttonBackgroundColor: themeNotifier.menuBackgroundColor,
        backgroundColor: themeNotifier.menuBackgroundColor,
        onTap: (index) async {
          if (index == 2) {
            final selectedDate = context.read<CalendarCubit>().state.selectedDate;
            final task = await showModalBottomSheet<Task>(
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
                      color: themeNotifier.menuBackgroundColor,
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
            if (mounted && task != null) {
              context.read<CalendarCubit>().addTask(task);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Task added: ${task.title}')),
              );
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Task addition cancelled')),
              );
            }
          } else {
            if (mounted) {
              setState(() {
                _selectedIndex = index;
              });
              logDebug('Navigation index changed: $_selectedIndex');
            }
          }
        },
        letIndexChange: (index) => index < _screens.length,
      ),
    );
  }
}