import 'package:flowo_client/models/repeat_rule.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'blocs/tasks_controller/tasks_controller_cubit.dart';
import 'models/category.dart';
import 'models/coordinates.dart';
import 'models/day.dart';
import 'models/notification_type.dart';
import 'models/scheduled_task.dart';
import 'models/scheduled_task_type.dart';
import 'models/user_settings.dart';
import 'screens/home_screen.dart';
import 'theme_notifier.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register Hive adapters
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(CoordinatesAdapter());
  Hive.registerAdapter(DayAdapter());
  Hive.registerAdapter(NotificationTypeAdapter());
  Hive.registerAdapter(RepeatRuleAdapter());
  Hive.registerAdapter(ScheduledTaskAdapter());
  Hive.registerAdapter(ScheduledTaskTypeAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(UserSettingsAdapter());

  await Hive.initFlutter();

  Box<Task> tasksDB;
  Box<Day> daysDB;

  if (kIsWeb) {
    tasksDB = await Hive.openBox<Task>('tasks');
    daysDB = await Hive.openBox<Day>('scheduled_tasks');
  } else {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    tasksDB = await Hive.openBox<Task>('tasks');
    daysDB = await Hive.openBox<Day>('scheduled_tasks');
  }

  logger.i('Hive initialized and task boxes opened');

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: MyApp(tasksDB: tasksDB, daysDB: daysDB),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Box<Task> tasksDB;
  final Box<Day> daysDB;

  const MyApp({super.key, required this.tasksDB, required this.daysDB});

  @override
  Widget build(BuildContext context) {
    logger.i('Building MyApp');
    return MultiBlocProvider(
      providers: [
        BlocProvider<CalendarCubit>(
          create: (context) => CalendarCubit(tasksDB, daysDB),
        ),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return CupertinoApp(
            debugShowCheckedModeBanner: false,
            theme: CupertinoThemeData(
              brightness: themeNotifier.currentTheme.brightness,
              primaryColor: themeNotifier.currentTheme.primaryColor,
              scaffoldBackgroundColor:
                  themeNotifier.currentTheme.scaffoldBackgroundColor,
            ),
            home: HomeScreen(),
          );
        },
      ),
    );
  }
}
