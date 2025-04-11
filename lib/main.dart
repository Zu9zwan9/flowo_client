import 'dart:io';

import 'package:flowo_client/models/ambient_scene.dart';
import 'package:flowo_client/models/repeat_rule.dart';
import 'package:flowo_client/models/repeat_rule_instance.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/screens/onboarding/name_input_screen.dart';
import 'package:flowo_client/services/ambient_service.dart';
import 'package:flowo_client/services/analytics_service.dart';
import 'package:flowo_client/services/onboarding_service.dart';
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
import 'models/notification_type.dart';
import 'models/pomodoro_session.dart';
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

  // Initialize security service to protect against reverse engineering
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

  // Check if it's the first app launch by checking if the UserSettings box is empty
  var isFirstLaunch = profiles.isEmpty;
  appLogger.info('Is first app launch: $isFirstLaunch', 'App');

  // Create and save default UserSettings if it's the first launch
  var selectedProfile =
      profiles.values.isNotEmpty
          ? profiles.values.first
          : UserSettings(
            name: 'Default',
            minSession: 15 * 60 * 1000, // Convert to milliseconds
            breakTime: 15 * 60 * 1000, // Default break time (15 minutes)
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
            activeDays: {
              'Monday': true,
              'Tuesday': true,
              'Wednesday': true,
              'Thursday': true,
              'Friday': true,
              'Saturday': true,
              'Sunday': true,
            },
            defaultNotificationType: NotificationType.push,
          );

  // Save the default settings to the Hive box if it's the first launch
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

  final taskManager = TaskManager(
    daysDB: daysDB,
    tasksDB: tasksDB,
    userSettings: selectedProfile,
    huggingFaceApiKey:
        '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', // Default API key
  );

  appLogger.info('Hive initialized and task boxes opened', 'App');

  final analyticsService = AnalyticsService();
  final ambientService = AmbientService(ambientScenesDB);

  appLogger.info('Hive initialized and task boxes opened', 'App');

  // Create web theme bridge for system theme detection
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

    // Initialize web-specific features
    if (kIsWeb) {
      try {
        final webThemeBridge = Provider.of<WebThemeBridge>(
          context,
          listen: false,
        );
        // Register web theme with JavaScript
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
            // Use the theme from ThemeNotifier to ensure custom colors, noise, and gradient are applied
            theme: themeNotifier.currentTheme,
            // Add these two lines to support localization:
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
