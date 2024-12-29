import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'blocs/calendar/calendar_cubit.dart';
import 'blocs/event_form/event_form_cubit.dart';
import 'screens/calendar_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => CalendarCubit()),
        BlocProvider(create: (context) => EventFormCubit()),
      ],
      child: MaterialApp(
        title: 'Calendar App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4), // Purple color from design
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: const Color(0xFF6750A4),
            foregroundColor: Colors.white,
          ),
          chipTheme: ChipThemeData(
            selectedColor: const Color(0xFF6750A4),
            secondarySelectedColor: Colors.purple.shade100,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const CalendarScreen(),
    const Center(child: Text('Tasks')),
    const Center(child: Text('Profile')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.task),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
