import 'package:flowo_client/models/habit_task.dart';
import 'package:flowo_client/models/repeat_rule.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'models/event_model.dart';
import 'models/category.dart';
import 'models/coordinates.dart';
import 'models/days.dart';
import 'models/notification_type.dart';
import 'models/scheduled_task.dart';
import 'models/scheduled_task_type.dart';
import 'models/user_settings.dart';
import 'screens/home_screen.dart';
import 'blocs/calendar/calendar_cubit.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register Hive adapters
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(CoordinatesAdapter());
  Hive.registerAdapter(DayAdapter());
  Hive.registerAdapter(EventAdapter());
  Hive.registerAdapter(HabitTaskAdapter());
  Hive.registerAdapter(NotificationTypeAdapter());
  Hive.registerAdapter(RepeatRuleAdapter());
  Hive.registerAdapter(ScheduledTaskAdapter());
  Hive.registerAdapter(ScheduledTaskTypeAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(UserSettingsAdapter());

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
