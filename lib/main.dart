import 'package:flowo_client/models/repeat_rule.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/utils/task_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'adapters/time_of_day_adapter.dart';
import 'blocs/tasks_controller/task_manager_cubit.dart';
import 'blocs/tasks_controller/tasks_controller_cubit.dart';
import 'models/category.dart';
import 'models/coordinates.dart';
import 'models/day.dart';
import 'models/notification_type.dart';
import 'models/scheduled_task.dart';
import 'models/scheduled_task_type.dart';
import 'models/time_frame.dart';
import 'models/user_profile.dart';
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
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(TimeFrameAdapter());
  Hive.registerAdapter(TimeOfDayAdapter());

  await Hive.initFlutter();

  Box<Task> tasksDB;
  Box<Day> daysDB;
  Box<UserSettings> profiles;
  Box<UserProfile> userProfiles;

  if (kIsWeb) {
    tasksDB = await Hive.openBox<Task>('tasks');
    daysDB = await Hive.openBox<Day>('scheduled_tasks');
    profiles = await Hive.openBox<UserSettings>('user_settings');
    userProfiles = await Hive.openBox<UserProfile>('user_profiles');
  } else {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    tasksDB = await Hive.openBox<Task>('tasks');
    daysDB = await Hive.openBox<Day>('scheduled_tasks');
    profiles = await Hive.openBox<UserSettings>('user_settings');
    userProfiles = await Hive.openBox<UserProfile>('user_profiles');
  }

  var selectedProfile = profiles.values.isNotEmpty
      ? profiles.values.first
      : UserSettings(
          name: 'Default',
          minSession: 15,
          sleepTime: [
            TimeFrame(
              startTime: const TimeOfDay(hour: 22, minute: 0),
              endTime: const TimeOfDay(hour: 7, minute: 0),
            ),
          ],
          mealBreaks: [
            TimeFrame(
              startTime: const TimeOfDay(hour: 8, minute: 0),
              endTime: const TimeOfDay(hour: 8, minute: 30),
            ),
            TimeFrame(
              startTime: const TimeOfDay(hour: 12, minute: 0),
              endTime: const TimeOfDay(hour: 13, minute: 0),
            ),
            TimeFrame(
              startTime: const TimeOfDay(hour: 18, minute: 0),
              endTime: const TimeOfDay(hour: 19, minute: 0),
            ),
          ],
          freeTime: [
            TimeFrame(
              startTime: const TimeOfDay(hour: 19, minute: 0),
              endTime: const TimeOfDay(hour: 22, minute: 0),
            ),
          ],
        );

  // Create default user profile if none exists
  if (userProfiles.isEmpty) {
    final defaultProfile = UserProfile(
      name: selectedProfile.name,
      email: 'user@example.com',
    );
    userProfiles.put('current', defaultProfile);
    logger.i('Created default user profile');
  }

  final taskManager = TaskManager(
    daysDB: daysDB,
    tasksDB: tasksDB,
    userSettings: selectedProfile,
  );

  logger.i('Hive initialized and task boxes opened');

  runApp(
    MultiProvider(
      providers: [
        Provider<TaskManager>.value(value: taskManager),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        BlocProvider<CalendarCubit>(
          create: (context) => CalendarCubit(
            tasksDB,
            daysDB,
            taskManager,
          ),
        ),
        BlocProvider<TaskManagerCubit>(
          create: (context) => TaskManagerCubit(taskManager),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    logger.i('Building MyApp');
    return Consumer<ThemeNotifier>(
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
    );
  }
}
