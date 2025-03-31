import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flowo_client/utils/logger.dart';

/// A class that monitors battery usage and provides optimization strategies for AI inference
class BatteryMonitor {
  static final BatteryMonitor _instance = BatteryMonitor._internal();

  /// Private constructor
  BatteryMonitor._internal();

  /// Get the singleton instance of BatteryMonitor
  static BatteryMonitor get instance => _instance;

  /// The battery instance
  final Battery _battery = Battery();

  /// The current battery level (0-100)
  int _batteryLevel = 100;

  /// The current battery state
  BatteryState _batteryState = BatteryState.full;

  /// Whether the device is in low power mode
  bool _isLowPowerMode = false;

  /// Stream subscription for battery level changes
  StreamSubscription<int>? _batteryLevelSubscription;

  /// Stream subscription for battery state changes
  StreamSubscription<BatteryState>? _batteryStateSubscription;

  /// Whether battery monitoring is initialized
  bool _isInitialized = false;

  /// Get the current battery level (0-100)
  int get batteryLevel => _batteryLevel;

  /// Get the current battery state
  BatteryState get batteryState => _batteryState;

  /// Check if the device is in low power mode
  bool get isLowPowerMode => _isLowPowerMode;

  /// Check if battery monitoring is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize battery monitoring
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      // Get initial battery level
      _batteryLevel = await _battery.batteryLevel;
      
      // Get initial battery state
      _batteryState = await _battery.batteryState;
      
      // Get initial low power mode state
      _isLowPowerMode = await _battery.isInBatterySaveMode;

      // Subscribe to battery level changes
      _batteryLevelSubscription = _battery.onBatteryStateChanged.listen((state) {
        _batteryState = state;
        logInfo('Battery state changed: $_batteryState');
      });

      // Subscribe to battery level changes
      _batteryLevelSubscription = _battery.onBatteryLevelChanged.listen((level) {
        _batteryLevel = level;
        logInfo('Battery level changed: $_batteryLevel%');
      });

      _isInitialized = true;
      logInfo('Battery monitoring initialized. Level: $_batteryLevel%, State: $_batteryState, Low Power Mode: $_isLowPowerMode');
    } catch (e) {
      logError('Error initializing battery monitoring: $e');
    }
  }

  /// Dispose battery monitoring
  Future<void> dispose() async {
    await _batteryLevelSubscription?.cancel();
    await _batteryStateSubscription?.cancel();
    _isInitialized = false;
    logInfo('Battery monitoring disposed');
  }

  /// Check if the device is in a low battery state
  bool isLowBattery() {
    return _batteryLevel <= 20 || _batteryState == BatteryState.discharging && _batteryLevel <= 30 || _isLowPowerMode;
  }

  /// Get the recommended quantization level based on battery state
  /// 
  /// Returns a value between 0 and 4:
  ///   0: No quantization (F32) - highest quality, highest battery usage
  ///   1: Q4_0 quantization (4-bit, small) - lower quality, lower battery usage
  ///   2: Q4_1 quantization (4-bit, medium) - medium quality, medium battery usage
  ///   3: Q5_0 quantization (5-bit, medium) - medium quality, medium battery usage
  ///   4: Q8_0 quantization (8-bit, high accuracy) - high quality, high battery usage
  int getRecommendedQuantizationLevel() {
    if (_batteryState == BatteryState.charging || _batteryState == BatteryState.full) {
      // If charging or full, use higher quality
      return 2;
    } else if (_isLowPowerMode) {
      // If in low power mode, use lowest quality
      return 1;
    } else if (_batteryLevel <= 20) {
      // If battery is very low, use lowest quality
      return 1;
    } else if (_batteryLevel <= 50) {
      // If battery is low, use medium quality
      return 2;
    } else {
      // If battery is good, use higher quality
      return 3;
    }
  }

  /// Get the recommended context size based on battery state
  int getRecommendedContextSize() {
    if (_batteryState == BatteryState.charging || _batteryState == BatteryState.full) {
      // If charging or full, use larger context
      return 2048;
    } else if (_isLowPowerMode) {
      // If in low power mode, use smallest context
      return 512;
    } else if (_batteryLevel <= 20) {
      // If battery is very low, use smallest context
      return 512;
    } else if (_batteryLevel <= 50) {
      // If battery is low, use medium context
      return 1024;
    } else {
      // If battery is good, use larger context
      return 2048;
    }
  }

  /// Get the recommended max tokens based on battery state
  int getRecommendedMaxTokens() {
    if (_batteryState == BatteryState.charging || _batteryState == BatteryState.full) {
      // If charging or full, allow more tokens
      return 512;
    } else if (_isLowPowerMode) {
      // If in low power mode, use fewest tokens
      return 128;
    } else if (_batteryLevel <= 20) {
      // If battery is very low, use fewest tokens
      return 128;
    } else if (_batteryLevel <= 50) {
      // If battery is low, use medium tokens
      return 256;
    } else {
      // If battery is good, allow more tokens
      return 384;
    }
  }

  /// Check if GPU acceleration should be used based on battery state
  bool shouldUseGPU() {
    // Only use GPU if charging, full, or battery level is high
    return _batteryState == BatteryState.charging || 
           _batteryState == BatteryState.full || 
           (_batteryLevel > 70 && !_isLowPowerMode);
  }

  /// Check if cloud API should be used instead of on-device inference based on battery state
  bool shouldUseCloudAPI() {
    // Use cloud API if battery is very low or in low power mode
    return _batteryLevel <= 15 || (_isLowPowerMode && _batteryLevel <= 30);
  }

  /// Get optimization recommendations for AI inference based on battery state
  Map<String, dynamic> getOptimizationRecommendations() {
    return {
      'quantizationLevel': getRecommendedQuantizationLevel(),
      'contextSize': getRecommendedContextSize(),
      'maxTokens': getRecommendedMaxTokens(),
      'useGPU': shouldUseGPU(),
      'useCloudAPI': shouldUseCloudAPI(),
      'batteryLevel': _batteryLevel,
      'batteryState': _batteryState.toString(),
      'isLowPowerMode': _isLowPowerMode,
    };
  }
}