// lib/screens/home_screen.dart
import 'package:cupertino_sidebar/cupertino_sidebar.dart';
import 'package:flowo_client/blocs/tasks_controller/tasks_controller_cubit.dart';
import 'package:flowo_client/screens/add_item_screen.dart';
import 'package:flowo_client/screens/analytics_screen.dart';
import 'package:flowo_client/screens/profile_screen.dart';
import 'package:flowo_client/screens/settings_screen.dart';
import 'package:flowo_client/screens/task_list_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  final dynamic initialIndex;
  final bool initialExpanded;

  const HomeScreen({
    super.key,
    this.initialIndex = 0,
    this.initialExpanded = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  late bool isExpanded;
  bool _isMenuPressed = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    isExpanded = widget.initialExpanded;
  }

  final _pages = const [
    CalendarScreen(),
    TaskListScreen(),
    AddItemScreen(),
    ProfileScreen(),
    SettingsScreen(),
    AnalyticsScreen(),
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
                  icon: Icon(CupertinoIcons.person),
                  label: Text('Profile'),
                ),
                SidebarDestination(
                  icon: Icon(CupertinoIcons.settings),
                  label: Text('Settings'),
                ),
                SidebarDestination(
                  icon: Icon(CupertinoIcons.chart_bar),
                  label: Text('Analytics'),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: GestureDetector(
                onTapDown: (_) => setState(() => _isMenuPressed = true),
                onTapUp: (_) => setState(() => _isMenuPressed = false),
                onTapCancel: () => setState(() => _isMenuPressed = false),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isMenuPressed
                        ? CupertinoColors.systemGrey6
                        : CupertinoColors.systemBackground.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.1),
                        blurRadius: 0,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.sidebar_left,
                      color: CupertinoColors.label,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
