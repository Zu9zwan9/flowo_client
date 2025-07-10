import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/logger.dart';

/// Сервис для управления очисткой данных приложения
class DataCleanupService {
  static final DataCleanupService _instance = DataCleanupService._internal();
  factory DataCleanupService() => _instance;
  DataCleanupService._internal();

  /// Список всех боксов Hive, используемых в приложении
  static const List<String> _allBoxNames = [
    'tasks',
    'scheduled_tasks',
    'user_settings',
    'user_profiles',
    'pomodoro_sessions',
    'categories_box',
    'ambient_scenes',
  ];

  /// Очистить все данные приложения
  Future<bool> clearAllAppData({
    bool deleteAvatarFiles = true,
    bool closeBoxes = true,
  }) async {
    try {
      appLogger.info('Начинаем полную очистку данных приложения', 'DataCleanup');

      // Удаляем файлы аватаров если необходимо
      if (deleteAvatarFiles) {
        await _deleteAvatarFiles();
      }

      // Закрываем все боксы если необходимо
      if (closeBoxes) {
        await _closeAllBoxes();
      }

      // Очищаем все боксы
      await _clearAllBoxes();

      // Очищаем кэш файлов
      await _clearFileCache();

      appLogger.info('Полная очистка данных завершена успешно', 'DataCleanup');
      return true;
    } catch (e) {
      appLogger.error('Ошибка при очистке данных: $e', 'DataCleanup');
      return false;
    }
  }

  /// Очистить конкретные боксы
  Future<bool> clearSpecificBoxes(List<String> boxNames) async {
    try {
      appLogger.info('Очищаем указанные боксы: ${boxNames.join(", ")}', 'DataCleanup');

      for (final boxName in boxNames) {
        await _clearSingleBox(boxName);
      }

      appLogger.info('Очистка указанных боксов завершена', 'DataCleanup');
      return true;
    } catch (e) {
      appLogger.error('Ошибка при очистке указанных боксов: $e', 'DataCleanup');
      return false;
    }
  }

  /// Получить список всех боксов
  List<String> getAllBoxNames() => List.unmodifiable(_allBoxNames);

  /// Получить статистику по боксам
  Future<Map<String, Map<String, dynamic>>> getBoxStatistics() async {
    final statistics = <String, Map<String, dynamic>>{};

    for (final boxName in _allBoxNames) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          statistics[boxName] = {
            'isOpen': true,
            'length': box.length,
            'keys': box.keys.toList(),
            'isEmpty': box.isEmpty,
          };
        } else {
          statistics[boxName] = {
            'isOpen': false,
            'length': 0,
            'keys': [],
            'isEmpty': true,
          };
        }
      } catch (e) {
        statistics[boxName] = {
          'isOpen': false,
          'length': 0,
          'keys': [],
          'isEmpty': true,
          'error': e.toString(),
        };
      }
    }

    return statistics;
  }

  /// Безопасно закрыть все боксы
  Future<void> _closeAllBoxes() async {
    for (final boxName in _allBoxNames) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          await Hive.box(boxName).close();
          appLogger.info('Бокс $boxName закрыт', 'DataCleanup');
        }
      } catch (e) {
        appLogger.warning('Не удалось закрыть бокс $boxName: $e', 'DataCleanup');
      }
    }
  }

  /// Очистить все боксы
  Future<void> _clearAllBoxes() async {
    for (final boxName in _allBoxNames) {
      await _clearSingleBox(boxName);
    }
  }

  /// Очистить один бокс
  Future<void> _clearSingleBox(String boxName) async {
    try {
      Box box;

      // Открываем бокс если он не открыт
      if (Hive.isBoxOpen(boxName)) {
        box = Hive.box(boxName);
      } else {
        box = await Hive.openBox(boxName);
      }

      // Очищаем бокс
      await box.clear();
      appLogger.info('Бокс $boxName очищен (было элементов: ${box.length})', 'DataCleanup');

    } catch (e) {
      appLogger.warning('Не удалось очистить бокс $boxName: $e', 'DataCleanup');

      // Пытаемся удалить файл бокса напрямую
      try {
        await _deleteBoxFile(boxName);
      } catch (deleteError) {
        appLogger.error('Не удалось удалить файл бокса $boxName: $deleteError', 'DataCleanup');
      }
    }
  }

  /// Удалить файлы аватаров
  Future<void> _deleteAvatarFiles() async {
    try {
      // Получаем профили перед очисткой
      if (Hive.isBoxOpen('user_profiles')) {
        final userProfilesBox = Hive.box('user_profiles');

        for (final profile in userProfilesBox.values) {
          if (profile != null && profile.avatarPath != null) {
            final avatarFile = File(profile.avatarPath!);
            if (await avatarFile.exists()) {
              await avatarFile.delete();
              appLogger.info('Удален файл аватара: ${profile.avatarPath}', 'DataCleanup');
            }
          }
        }
      }
    } catch (e) {
      appLogger.warning('Ошибка при удалении файлов аватаров: $e', 'DataCleanup');
    }
  }

  /// Очистить кэш файлов
  Future<void> _clearFileCache() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        appLogger.info('Кэш файлов очищен', 'DataCleanup');
      }
    } catch (e) {
      appLogger.warning('Не удалось очистить кэш файлов: $e', 'DataCleanup');
    }
  }

  /// Удалить файл бокса напрямую
  Future<void> _deleteBoxFile(String boxName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final boxFile = File('${dir.path}/$boxName.hive');
      final lockFile = File('${dir.path}/$boxName.lock');

      if (await boxFile.exists()) {
        await boxFile.delete();
        appLogger.info('Удален файл бокса: $boxName.hive', 'DataCleanup');
      }

      if (await lockFile.exists()) {
        await lockFile.delete();
        appLogger.info('Удален lock файл: $boxName.lock', 'DataCleanup');
      }
    } catch (e) {
      appLogger.error('Ошибка при удалении файлов бокса $boxName: $e', 'DataCleanup');
    }
  }

  /// Проверить целостность данных
  Future<Map<String, bool>> checkDataIntegrity() async {
    final integrity = <String, bool>{};

    for (final boxName in _allBoxNames) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          // Простая проверка - можем ли мы получить доступ к данным
          box.length;
          integrity[boxName] = true;
        } else {
          // Пытаемся открыть бокс
          final box = await Hive.openBox(boxName);
          box.length;
          integrity[boxName] = true;
        }
      } catch (e) {
        integrity[boxName] = false;
        appLogger.warning('Проблема с целостностью бокса $boxName: $e', 'DataCleanup');
      }
    }

    return integrity;
  }
}
