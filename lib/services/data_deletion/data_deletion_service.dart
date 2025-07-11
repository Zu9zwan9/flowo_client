import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/ambient_scene.dart';
import '../../models/day.dart';
import '../../models/pomodoro_session.dart';
import '../../models/task.dart';
import '../../models/user_profile.dart';
import '../../models/user_settings.dart';

/// Service for deleting all user data on device (iOS and Android).
class DataDeletionService {
  /// Deletes all local user data including Hive boxes, shared preferences, and files.
  static Future<void> deleteAllUserData() async {
    // Close and delete all Hive boxes (maintained list)
    const boxNames = [
      'tasks',
      'scheduled_tasks',
      'user_settings',
      'user_profiles',
      'pomodoro_sessions',
      'categories_box',
      'ambient_scenes',
      // add any other box names here
    ];
    await Hive.close();
    for (final name in boxNames) {
      try {
        await Hive.deleteBoxFromDisk(name);
        debugPrint('[DataDeletion] Deleted Hive box: $name');
      } catch (e) {
        debugPrint('[DataDeletion] Error deleting box $name: $e');
      }
    }

    // Clear SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('[DataDeletion] Cleared SharedPreferences');
    } catch (e) {
      debugPrint('[DataDeletion] Error clearing SharedPreferences: $e');
    }

    // Delete application directories
    await _deleteDir(await getApplicationSupportDirectory());
    await _deleteDir(await getApplicationDocumentsDirectory());
    await _deleteDir(await getTemporaryDirectory());
    // iOS: clear Library directory
    if (Platform.isIOS) {
      try {
        final libDir = await getLibraryDirectory();
        await _deleteDir(libDir);
        debugPrint('[DataDeletion] Cleared iOS Library directory');
      } catch (e) {
        debugPrint('[DataDeletion] Error clearing Library directory: $e');
      }
    }

    // Android: also clear external storage directory (app-specific)
    if (Platform.isAndroid) {
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) await _deleteDir(extDir);
        debugPrint('[DataDeletion] Cleared external storage directory');
      } catch (e) {
        debugPrint('[DataDeletion] Error clearing external storage: $e');
      }
    }

    debugPrint('[DataDeletion] Completed all user data deletion.');

    // Reinitialize Hive and reopen boxes for continued app use
    await Hive.initFlutter();
    // Reopen app boxes
    await Hive.openBox<Task>('tasks');
    await Hive.openBox<Day>('scheduled_tasks');
    await Hive.openBox<UserSettings>('user_settings');
    await Hive.openBox<UserProfile>('user_profiles');
    await Hive.openBox<PomodoroSession>('pomodoro_sessions');
    await Hive.openBox<List<dynamic>>('categories_box');
    await Hive.openBox<AmbientScene>('ambient_scenes');
  }

  static Future<void> _deleteDir(Directory dir) async {
    if (await dir.exists()) {
      try {
        await dir.delete(recursive: true);
        debugPrint('[DataDeletion] Deleted directory: ${dir.path}');
      } catch (e) {
        debugPrint('[DataDeletion] Error deleting directory ${dir.path}: $e');
      }
    }
  }
}
