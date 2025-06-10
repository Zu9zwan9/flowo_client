import 'dart:io';

import 'package:flowo_client/config/env_config.dart';
import 'package:flowo_client/models/ambient_scene.dart';
import 'package:flowo_client/models/repeat_rule.dart';
import 'package:flowo_client/models/repeat_rule_instance.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/models/task_session.dart';
import 'package:flowo_client/screens/onboarding/name_input_screen.dart';
import 'package:flowo_client/services/ambient/ambient_service.dart';
import 'package:flowo_client/services/analytics/analytics_service.dart';
import 'package:flowo_client/services/onboarding/onboarding_service.dart';
import 'package:flowo_client/services/security_service.dart';
import 'package:flowo_client/services/web_theme_bridge.dart';
import 'package:flowo_client/utils/task_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'blocs/analytics/analytics_cubit.dart';
import 'blocs/tasks_controller/task_manager_cubit.dart';
import 'blocs/tasks_controller/tasks_controller_cubit.dart';
import 'models/adapters/time_of_day_adapter.dart';
import 'models/app_theme.dart';
import 'models/category.dart';
import 'models/coordinates.dart';
import 'models/day.dart';
import 'models/day_schedule.dart';
import 'models/notification_type.dart';
import 'models/pomodoro_session.dart';
import 'models/scheduled_task.dart';
import 'models/scheduled_task_type.dart';
import 'models/time_frame.dart';
import 'models/user_profile.dart';
import 'models/user_settings.dart';
import 'screens/home_screen.dart';
import 'theme/theme_notifier.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.initialize();

  if (!kIsWeb) {
    final securityService = SecurityService(
      // For Android
      onRootDetected: () => exit(0),
      onEmulatorDetected: () => exit(0),
      onFingerprintDetected: () => exit(0),
      onHookDetected: () => exit(0),
      onTamperDetected: () => exit(0),

      // For iOS
      onSignatureDetected: () => exit(0),
      onRuntimeManipulationDetected: () => exit(0),
      onJailbreakDetected: () => exit(0),
      onPasscodeChangeDetected: () => exit(0),
      onPasscodeDetected: () => exit(0),
      onSimulatorDetected: () => exit(0),
      onMissingSecureEnclaveDetected: () => exit(0),

      // Common for both platforms
      onDebuggerDetected: () => exit(0),
    );

    // Initialize security checks
    await securityService.initialize();
  }

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
  Hive.registerAdapter(PomodoroSessionAdapter());
  Hive.registerAdapter(PomodoroStateAdapter());
  Hive.registerAdapter(AmbientSceneAdapter());
  Hive.registerAdapter(RepeatRuleInstanceAdapter());
  Hive.registerAdapter(AppThemeAdapter());
  Hive.registerAdapter(TaskSessionAdapter());
  Hive.registerAdapter(DayScheduleAdapter());

  await Hive.initFlutter();

  Box<Task> tasksDB;
  Box<Day> daysDB;
  Box<UserSettings> profiles;
  Box<UserProfile> userProfiles;
  Box<PomodoroSession> pomodoroSessionsDB;
  Box<AmbientScene> ambientScenesDB;

  if (kIsWeb) {
    tasksDB = await Hive.openBox<Task>('tasks');
    daysDB = await Hive.openBox<Day>('scheduled_tasks');
    profiles = await Hive.openBox<UserSettings>('user_settings');
    userProfiles = await Hive.openBox<UserProfile>('user_profiles');
    pomodoroSessionsDB = await Hive.openBox<PomodoroSession>(
      'pomodoro_sessions',
    );

    await Hive.openBox<List<dynamic>>('categories_box');
    ambientScenesDB = await Hive.openBox<AmbientScene>('ambient_scenes');
  } else {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    tasksDB = await Hive.openBox<Task>('tasks');
    daysDB = await Hive.openBox<Day>('scheduled_tasks');
    profiles = await Hive.openBox<UserSettings>('user_settings');
    userProfiles = await Hive.openBox<UserProfile>('user_profiles');
    pomodoroSessionsDB = await Hive.openBox<PomodoroSession>(
      'pomodoro_sessions',
    );
    await Hive.openBox<List<dynamic>>('categories_box');
    ambientScenesDB = await Hive.openBox<AmbientScene>('ambient_scenes');
  }

  var isFirstLaunch = profiles.isEmpty;
  appLogger.info('Is first app launch: $isFirstLaunch', 'App');

  DaySchedule createDaySchedule({
    required String day,
    required TimeFrame sleepTime,
    required List<TimeFrame> mealBreaks,
    required List<TimeFrame> freeTimes,
  }) {
    // Updated to match the new constructor signature with name and list of days
    return DaySchedule(
      name: "$day Schedule",
      // Add a name parameter
      day: [day],
      // Change to a List<String> instead of String
      isActive: true,
      sleepTime: sleepTime,
      mealBreaks: mealBreaks,
      freeTimes: freeTimes,
    );
  }

  var selectedProfile =
      profiles.values.isNotEmpty
          ? profiles.values.first
          : UserSettings(
            name: 'Default',
            minSession: 15 * 60 * 1000,
            // Convert to milliseconds
            sleepTime: [
              TimeFrame(
                startTime: const TimeOfDay(hour: 22, minute: 0),
                endTime: const TimeOfDay(hour: 7, minute: 0),
              ),
            ],
            activeDays: {
              'Monday': true,
              'Tuesday': true,
              'Wednesday': true,
              'Thursday': true,
              'Friday': true,
              'Saturday': true,
              'Sunday': true,
            },
            daySchedules: {
              for (var day in [
                'Monday',
                'Tuesday',
                'Wednesday',
                'Thursday',
                'Friday',
                'Saturday',
                'Sunday',
              ])
                day: createDaySchedule(
                  day: day,
                  sleepTime:
                      day == 'Saturday' || day == 'Sunday'
                          ? TimeFrame(
                            startTime: const TimeOfDay(hour: 23, minute: 0),
                            endTime: const TimeOfDay(hour: 9, minute: 0),
                          )
                          : TimeFrame(
                            startTime: const TimeOfDay(hour: 22, minute: 0),
                            endTime: const TimeOfDay(hour: 7, minute: 0),
                          ),
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
                  freeTimes: [
                    TimeFrame(
                      startTime: const TimeOfDay(hour: 19, minute: 0),
                      endTime: const TimeOfDay(hour: 22, minute: 0),
                    ),
                  ],
                ),
            },
            defaultNotificationType: NotificationType.push,
            // Initialize the new schedules property with default values
            schedules: [
              // Weekday schedule
              DaySchedule(
                name: "Weekday Schedule",
                day: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
                isActive: true,
                sleepTime: TimeFrame(
                  startTime: const TimeOfDay(hour: 22, minute: 0),
                  endTime: const TimeOfDay(hour: 7, minute: 0),
                ),
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
                freeTimes: [
                  TimeFrame(
                    startTime: const TimeOfDay(hour: 19, minute: 0),
                    endTime: const TimeOfDay(hour: 22, minute: 0),
                  ),
                ],
              ),
              // Weekend schedule
              DaySchedule(
                name: "Weekend Schedule",
                day: ['Saturday', 'Sunday'],
                isActive: true,
                sleepTime: TimeFrame(
                  startTime: const TimeOfDay(hour: 23, minute: 0),
                  endTime: const TimeOfDay(hour: 9, minute: 0),
                ),
                mealBreaks: [
                  TimeFrame(
                    startTime: const TimeOfDay(hour: 9, minute: 30),
                    endTime: const TimeOfDay(hour: 10, minute: 30),
                  ),
                  TimeFrame(
                    startTime: const TimeOfDay(hour: 13, minute: 0),
                    endTime: const TimeOfDay(hour: 14, minute: 0),
                  ),
                  TimeFrame(
                    startTime: const TimeOfDay(hour: 19, minute: 0),
                    endTime: const TimeOfDay(hour: 20, minute: 0),
                  ),
                ],
                freeTimes: [
                  TimeFrame(
                    startTime: const TimeOfDay(hour: 20, minute: 0),
                    endTime: const TimeOfDay(hour: 23, minute: 0),
                  ),
                ],
              ),
            ],
          );

  // Get API key with fallback to empty string if environment initialization failed
  String apiKey = '';
  try {
    apiKey = EnvConfig.azureApiKey;
  } catch (e) {
    appLogger.error('Failed to get API key: $e', 'App');
    appLogger.info('Using empty API key as fallback', 'App');
  }

  final taskManager = TaskManager(
    daysDB: daysDB,
    tasksDB: tasksDB,
    userSettings: selectedProfile,
    huggingFaceApiKey: apiKey,
  );

  if (isFirstLaunch) {
    appLogger.info('Saving default user settings', 'App');
    profiles.put('current', selectedProfile);

    // Verify the settings were saved
    final savedSettings = profiles.get('current');
    if (savedSettings == null) {
      appLogger.error('Failed to save default user settings', 'App');
    } else {
      appLogger.info(
        'Default user settings saved successfully: name=${savedSettings.name}, minSession=${savedSettings.minSession}',
        'App',
      );
    }

    taskManager.scheduler.createDaysUntil(
      DateTime(DateTime.now().year, DateTime.now().month + 3),
    );
  }

  // Create default user profile if none exists
  if (userProfiles.isEmpty) {
    final defaultProfile = UserProfile(
      name: selectedProfile.name,
      email: 'user@example.com',
      goal: null, // Explicitly set to null
      onboardingCompleted: false, // Explicitly set to false
    );
    userProfiles.put('current', defaultProfile);

    // Verify the profile was saved
    final savedProfile = userProfiles.get('current');
    if (savedProfile == null) {
      appLogger.error('Failed to save default user profile', 'App');
    } else {
      appLogger.info(
        'Created default user profile: name=${savedProfile.name}, goal=${savedProfile.goal}, onboardingCompleted=${savedProfile.onboardingCompleted}',
        'App',
      );
    }
  } else {
    final userProfile = userProfiles.get('current');
    appLogger.info(
      'Using existing user profile: name=${userProfile?.name}, goal=${userProfile?.goal}, onboardingCompleted=${userProfile?.onboardingCompleted}',
      'App',
    );
  }

  appLogger.info('Hive initialized and task boxes opened', 'App');

  final analyticsService = AnalyticsService();
  final ambientService = AmbientService(ambientScenesDB);

  appLogger.info('Hive initialized and task boxes opened', 'App');

  final webThemeBridge = WebThemeBridge();

  runApp(
    MultiProvider(
      providers: [
        Provider<TaskManager>.value(value: taskManager),
        Provider<AnalyticsService>.value(value: analyticsService),
        Provider<Box<UserProfile>>.value(value: userProfiles),
        Provider<Box<PomodoroSession>>.value(value: pomodoroSessionsDB),
        Provider<Box<AmbientScene>>.value(value: ambientScenesDB),
        Provider<WebThemeBridge>.value(value: webThemeBridge),
        ChangeNotifierProvider<AmbientService>.value(value: ambientService),
        ChangeNotifierProvider(
          create:
              (context) => ThemeNotifier(
                webThemeBridge: webThemeBridge,
                userSettings: selectedProfile,
              ),
        ),
        BlocProvider<CalendarCubit>(
          create: (context) => CalendarCubit(tasksDB, daysDB, taskManager),
        ),
        BlocProvider<TaskManagerCubit>(
          create: (context) => TaskManagerCubit(taskManager),
        ),
        BlocProvider<AnalyticsCubit>(
          create: (context) => AnalyticsCubit(analyticsService),
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
    appLogger.info('Building MyApp', 'App');

    if (kIsWeb) {
      try {
        final webThemeBridge = Provider.of<WebThemeBridge>(
          context,
          listen: false,
        );
        webThemeBridge.callJavaScriptFunction('flutterThemeReady');
        appLogger.info('Web theme bridge initialized', 'App');
      } catch (e) {
        appLogger.error('Failed to initialize web theme bridge: $e', 'App');
      }
    }

    // Create onboarding service
    final userProfileBox = Provider.of<Box<UserProfile>>(context);
    final onboardingService = OnboardingService(userProfileBox);

    // Check if onboarding is completed
    final isOnboardingCompleted = onboardingService.isOnboardingCompleted();

    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        final brightness = themeNotifier.currentTheme.brightness;
        return Provider<OnboardingService>.value(
          value: onboardingService,
          child: CupertinoApp(
            debugShowCheckedModeBanner: false,
            theme: themeNotifier.currentTheme,
            localizationsDelegates: const [
              DefaultCupertinoLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en', 'US')],
            home:
                isOnboardingCompleted
                    ? const HomeScreen(initialExpanded: false)
                    : const NameInputScreen(),
          ),
        );
      },
    );
  }
}
