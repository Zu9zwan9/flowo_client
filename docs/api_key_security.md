# API Key Security Implementation

## Overview

This document describes the implementation of secure API key storage in the Flowo Client application. The goal is to remove hardcoded API keys from the codebase and use secure storage instead.

## Implementation Details

### 1. EnvService Class

We've created an `EnvService` class in `lib/core/utils/env.dart` that handles secure storage of API keys using the `flutter_secure_storage` package:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A class that handles secure storage of API keys and environment variables.
class EnvService {
  static const String _huggingFaceApiKeyKey = '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';
  static const String _defaultHuggingFaceApiKey = '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';
  
  final FlutterSecureStorage _secureStorage;
  
  EnvService(this._secureStorage);
  
  /// Gets the Hugging Face API key from secure storage.
  /// If the key doesn't exist, it will be initialized with the default value.
  Future<String> getHuggingFaceApiKey() async {
    String? apiKey = await _secureStorage.read(key: _huggingFaceApiKeyKey);
    
    if (apiKey == null) {
      // Initialize with default value if not set
      await _secureStorage.write(
        key: _huggingFaceApiKeyKey, 
        value: _defaultHuggingFaceApiKey
      );
      return _defaultHuggingFaceApiKey;
    }
    
    return apiKey;
  }
  
  /// Sets the Hugging Face API key in secure storage.
  Future<void> setHuggingFaceApiKey(String apiKey) async {
    await _secureStorage.write(key: _huggingFaceApiKeyKey, value: apiKey);
  }
}

// For backward compatibility during transition
final api = (apiKey: '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');
```

### 2. Service Locator Registration

The `EnvService` and `FlutterSecureStorage` should be registered in the service locator (`lib/core/services/service_locator.dart`):

```dart
// Register FlutterSecureStorage
locator.registerLazySingleton<FlutterSecureStorage>(
  () => const FlutterSecureStorage(),
);

// Register EnvService
locator.registerLazySingleton<EnvService>(
  () => EnvService(locator<FlutterSecureStorage>()),
);
```

### 3. Usage in TaskManager

The `TaskManager` class should be updated to use the `EnvService` instead of hardcoded API keys:

```dart
TaskManager({
  required this.daysDB,
  required this.tasksDB,
  required this.userSettings,
  String? huggingFaceApiKey,
}) : scheduler = Scheduler(daysDB, tasksDB, userSettings),
     taskUrgencyCalculator = TaskUrgencyCalculator(daysDB),
     taskBreakdownAPI = TaskBreakdownAPI(
       apiKey: huggingFaceApiKey ?? locator<EnvService>().getHuggingFaceApiKey(),
     ),
     taskEstimatorAPI = TaskEstimatorAPI(
       apiKey: huggingFaceApiKey ?? locator<EnvService>().getHuggingFaceApiKey(),
     );
```

## Transition Plan

Due to the ongoing refactoring of the project structure, with models being moved from `/lib/models/` to `/lib/features/task/domain/models/`, there are type conflicts that prevent a direct implementation of the solution. The following steps should be taken to complete the implementation:

1. Complete the refactoring of the project structure to resolve the type conflicts
2. Update the service locator to register `FlutterSecureStorage` and `EnvService`
3. Update the `TaskManager` class to use the `EnvService` instead of hardcoded API keys
4. Remove the backward compatibility code from `env.dart` once all usages have been updated

## Security Considerations

- The API key is stored securely using `flutter_secure_storage`, which uses platform-specific secure storage mechanisms
- The default API key is still included in the code for initialization purposes, but it's only used if no key is found in secure storage
- In a production environment, the default API key should be removed and users should be prompted to enter their own API key
