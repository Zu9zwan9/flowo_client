import 'package:flowo_client/models/adapters/time_of_day_adapter.dart';
import 'package:flowo_client/models/ambient_scene.dart';
import 'package:flowo_client/models/category.dart';
import 'package:flowo_client/models/coordinates.dart';
import 'package:flowo_client/models/day.dart';
import 'package:flowo_client/models/notification_type.dart';
import 'package:flowo_client/models/pomodoro_session.dart';
import 'package:flowo_client/models/repeat_rule.dart';
import 'package:flowo_client/models/repeat_rule_instance.dart';
import 'package:flowo_client/models/scheduled_task.dart';
import 'package:flowo_client/models/scheduled_task_type.dart';
import 'package:flowo_client/models/task.dart';
import 'package:flowo_client/models/time_frame.dart';
import 'package:flowo_client/models/user_profile.dart';
import 'package:flowo_client/models/user_settings.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Database service responsible for initializing and managing Hive databases
class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Database boxes
  late Box<Task> tasksDB;
  late Box<Day> daysDB;
  late Box<UserSettings> profiles;
  late Box<UserProfile> userProfiles;
  late Box<PomodoroSession> pomodoroSessionsDB;
  late Box<AmbientScene> ambientScenesDB;
  late UserSettings selectedProfile;

  /// Initialize the database service
  Future<void> initialize() async {
    try {
      appLogger.info('Initializing database service', 'DatabaseService');

      // Register Hive adapters
      _registerAdapters();
      await Hive.initFlutter();

      // Open boxes based on platform
      await _openBoxes();

      // Initialize user profile
      await _initializeUserProfile();

      appLogger.info(
        'Database service initialized successfully',
        'DatabaseService',
      );
    } catch (e) {
      appLogger.error(
        'Failed to initialize database service: $e',
        'DatabaseService',
      );
      rethrow; // Propagate error for proper handling
    }
  }

  /// Register all Hive adapters
  void _registerAdapters() {
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
  }

  /// Open all required Hive boxes
  Future<void> _openBoxes() async {
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
  }

  /// Initialize user profile and settings
  Future<void> _initializeUserProfile() async {
    // Get or create user settings
    selectedProfile =
        profiles.values.isNotEmpty
            ? profiles.values.first
            : _createDefaultUserSettings();

    // Create default user profile if none exists
    if (userProfiles.isEmpty) {
      final defaultProfile = UserProfile(
        name: selectedProfile.name,
        email: 'user@example.com',
        goal: null,
        onboardingCompleted: false,
      );

      await userProfiles.put('current', defaultProfile);

      // Verify the profile was saved
      final savedProfile = userProfiles.get('current');
      if (savedProfile == null) {
        appLogger.error(
          'Failed to save default user profile',
          'DatabaseService',
        );
        throw Exception('Failed to save default user profile');
      } else {
        appLogger.info(
          'Created default user profile: name=${savedProfile.name}, goal=${savedProfile.goal}, onboardingCompleted=${savedProfile.onboardingCompleted}',
          'DatabaseService',
        );
      }
    } else {
      final userProfile = userProfiles.get('current');
      appLogger.info(
        'Using existing user profile: name=${userProfile?.name}, goal=${userProfile?.goal}, onboardingCompleted=${userProfile?.onboardingCompleted}',
        'DatabaseService',
      );
    }
  }

  /// Create default user settings
  UserSettings _createDefaultUserSettings() {
    return UserSettings(
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
  }
}
