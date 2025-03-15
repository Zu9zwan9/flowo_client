import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:logger/logger.dart' as log_package;
import 'package:path_provider/path_provider.dart';

/// A class representing a structured log entry
class LogEntry {
  final DateTime timestamp;
  final String level;
  final String message;
  final String module;
  final dynamic details;

  LogEntry({
    required this.level,
    required this.message,
    required this.module,
    this.details,
  }) : timestamp = DateTime.now().toUtc();

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level,
    'message': message,
    'module': module,
    'details': details,
  };

  @override
  String toString() {
    // Format for console output - simplified text format as required
    final detailsStr = details != null ? '(${_formatDetails(details)})' : '';
    return '[${timestamp.toIso8601String()}] [$level] [$module] $message $detailsStr';
  }

  String _formatDetails(dynamic details) {
    if (details is Map) {
      return details.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    } else {
      return details.toString();
    }
  }
}

/// A singleton class for logging with structured format and storage
class Logger {
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;

  // Private constructor
  Logger._internal() {
    // Initialize the logger package
    _packageLogger = log_package.Logger(
      printer: log_package.PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 80,
        colors: true,
        printEmojis: true,
        printTime: false,
      ),
    );
  }

  // In-memory storage for logs
  static final List<LogEntry> _logs = [];

  // Logger instance from the package
  late final log_package.Logger _packageLogger;

  /// Log an informational message
  void info(String message, String module, [dynamic details]) {
    final log = LogEntry(
      level: 'INFO',
      message: message,
      module: module,
      details: details,
    );
    _logs.add(log);
    if (kDebugMode) {
      _packageLogger.i(log.toString());
    }
  }

  /// Log a debug message
  void debug(String message, String module, [dynamic details]) {
    final log = LogEntry(
      level: 'DEBUG',
      message: message,
      module: module,
      details: details,
    );
    _logs.add(log);
    if (kDebugMode) {
      _packageLogger.d(log.toString());
    }
  }

  /// Log an error message
  void error(String message, String module, [dynamic details]) {
    final log = LogEntry(
      level: 'ERROR',
      message: message,
      module: module,
      details: details,
    );
    _logs.add(log);
    _packageLogger.e(log.toString());
  }

  /// Log a warning message
  void warning(String message, String module, [dynamic details]) {
    final log = LogEntry(
      level: 'WARNING',
      message: message,
      module: module,
      details: details,
    );
    _logs.add(log);
    if (kDebugMode) {
      _packageLogger.w(log.toString());
    }
  }

  /// Save logs to a file
  Future<String?> saveToFile(BuildContext context) async {
    try {
      final directory = await _getLogsDirectory();
      final fileName =
          'logs_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';
      final file = File('${directory.path}/$fileName');

      // Save logs as a JSON array
      await file.writeAsString(
        jsonEncode(_logs.map((log) => log.toJson()).toList()),
      );

      if (kDebugMode) {
        print('Logs saved to: ${file.path}');
      }

      return file.path;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving logs: $e');
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save logs: $e')));

      return null;
    }
  }

  /// Get the directory where logs will be saved
  Future<Directory> _getLogsDirectory() async {
    if (Platform.isAndroid) {
      // For Android, save to Documents directory
      final directory = await getExternalStorageDirectory();
      final docsDir = Directory('${directory?.path}/Documents/Logs');
      if (!await docsDir.exists()) {
        await docsDir.create(recursive: true);
      }
      return docsDir;
    } else {
      // For iOS, save to app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/Logs');
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }
      return logsDir;
    }
  }

  /// Clear all logs from memory
  void clearLogs() {
    _logs.clear();
  }

  /// Get all logs
  List<LogEntry> getLogs() {
    return List.unmodifiable(_logs);
  }
}

// Create a singleton instance
final appLogger = Logger();

// Legacy functions for backward compatibility
void logInfo(String message) {
  appLogger.info(message, 'App');
}

void logDebug(String message) {
  appLogger.debug(message, 'App');
}

void logError(String message) {
  appLogger.error(message, 'App');
}

void logWarning(String message) {
  appLogger.warning(message, 'App');
}
