import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A class that manages environment variables for the application.

class EnvConfig {
  /// Private constructor to prevent instantiation
  EnvConfig._();

  /// Singleton instance
  static final EnvConfig _instance = EnvConfig._();

  /// Factory constructor to return the singleton instance
  factory EnvConfig() => _instance;

  /// Flag to track if the environment has been initialized
  static bool _initialized = false;

  /// Flag to track if initialization was attempted but failed
  static bool _initializationFailed = false;

  /// Default values for environment variables
  static const Map<String, String> _defaults = {
    'AZURE_API_KEY': '',
    'AZURE_API_URL': 'https://models.inference.ai.azure.com/chat/completions',
    'AI_MODEL': 'gpt-4o',
  };

  /// Initialize the environment configuration

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // For web, we need to load the .env file from the assets directory
      if (kIsWeb) {
        await dotenv.load(fileName: 'assets/.env');
      } else {
        // For non-web platforms, load from the root directory
        await dotenv.load(fileName: '.env');
      }

      _initialized = true;
      debugPrint('Environment variables loaded successfully');
    } catch (e) {
      _initializationFailed = true;
      debugPrint('Failed to load environment variables: $e');

      // Initialize with default values
      _setDefaultValues();

      // Mark as initialized so the app can continue
      _initialized = true;
      debugPrint('Using default environment values');
    }
  }

  /// Set default values for environment variables when loading fails
  static void _setDefaultValues() {
    dotenv.env['AZURE_API_KEY'] = _defaults['AZURE_API_KEY']!;
    dotenv.env['AZURE_API_URL'] = _defaults['AZURE_API_URL']!;
    dotenv.env['AI_MODEL'] = _defaults['AI_MODEL']!;
  }

  /// Get the Azure API key
  static String get azureApiKey {
    _ensureInitialized();
    return dotenv.env['AZURE_API_KEY'] ?? _defaults['AZURE_API_KEY']!;
  }

  /// Get the Azure API URL
  static String get azureApiUrl {
    _ensureInitialized();
    return dotenv.env['AZURE_API_URL'] ?? _defaults['AZURE_API_URL']!;
  }

  /// Get the AI model name
  static String get aiModel {
    _ensureInitialized();
    return dotenv.env['AI_MODEL'] ?? _defaults['AI_MODEL']!;
  }

  /// Ensure the environment has been initialized before accessing variables
  static void _ensureInitialized() {
    if (!_initialized) {
      if (_initializationFailed) {
        debugPrint('Warning: Using default environment values');
      } else {
        throw NotInitializedError(
          'Environment variables accessed before initialization',
        );
      }
    }
  }

  /// Check if the environment has valid configuration
  static bool get isConfigValid {
    try {
      return azureApiKey.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

/// Custom error for when environment variables are accessed before initialization
class NotInitializedError extends Error {
  final String message;

  NotInitializedError(this.message);

  @override
  String toString() => message;
}
