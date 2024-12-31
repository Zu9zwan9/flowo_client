import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'models/event_model.dart';
import 'screens/home_screen.dart';
import 'blocs/calendar/calendar_cubit.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Hive.registerAdapter(EventAdapter());
  await Hive.initFlutter();

  Box<Event> eventBox;

  if (kIsWeb) {
    eventBox = await Hive.openBox<Event>('events');
  } else {
    final dir = await getApplicationDocumentsDirectory();
    eventBox = await Hive.openBox<Event>('events');
  }

  logger.i('Hive initialized and event box opened');

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: MyApp(eventBox: eventBox),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Box<Event> eventBox;

  const MyApp({super.key, required this.eventBox});

  @override
  Widget build(BuildContext context) {
    logger.i('Building MyApp');
    return MultiBlocProvider(
      providers: [
        BlocProvider<CalendarCubit>(
          create: (context) => CalendarCubit(eventBox),
        ),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            theme: themeNotifier.currentTheme,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
