import 'package:flowo_client/models/ambient_scene.dart';
import 'package:flowo_client/models/pomodoro_session.dart';
import 'package:flowo_client/models/user_profile.dart';
import 'package:flowo_client/services/ambient_service.dart';
import 'package:flowo_client/services/analytics_service.dart';
import 'package:flowo_client/services/database_service.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:flowo_client/utils/task_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service locator for app-wide dependencies
class AppServices {
  // Singleton pattern
  static final AppServices _instance = AppServices._internal();
  factory AppServices() => _instance;
  AppServices._internal();

  // Services
  late DatabaseService _databaseService;
  late TaskManager _taskManager;
  late AnalyticsService _analyticsService;
  late AmbientService _ambientService;

  // Getters for services
  DatabaseService get databaseService => _databaseService;
  TaskManager get taskManager => _taskManager;
  AnalyticsService get analyticsService => _analyticsService;
  AmbientService get ambientService => _ambientService;

  // Getters for commonly used database boxes
  Box<UserProfile> get userProfiles => _databaseService.userProfiles;
  Box<PomodoroSession> get pomodoroSessionsDB =>
      _databaseService.pomodoroSessionsDB;
  Box<AmbientScene> get ambientScenesDB => _databaseService.ambientScenesDB;

  /// Initialize all services
  Future<void> initialize() async {
    try {
      appLogger.info('Initializing app services', 'AppServices');

      // Initialize database service first
      _databaseService = DatabaseService();
      await _databaseService.initialize();

      // Initialize task manager
      _taskManager = TaskManager(
        daysDB: _databaseService.daysDB,
        tasksDB: _databaseService.tasksDB,
        userSettings: _databaseService.selectedProfile,
        huggingFaceApiKey: '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',
      );

      // Initialize analytics service
      _analyticsService = AnalyticsService();

      // Initialize ambient service
      _ambientService = AmbientService(_databaseService.ambientScenesDB);

      appLogger.info('App services initialized successfully', 'AppServices');
    } catch (e) {
      appLogger.error('Failed to initialize app services: $e', 'AppServices');
      rethrow; // Propagate error for proper handling
    }
  }

  /// Dispose of services when app is closed
  void dispose() {
    appLogger.info('Disposing app services', 'AppServices');
    // Add any cleanup code here if needed
  }
}
