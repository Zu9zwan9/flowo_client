import 'dart:async';

import 'package:flowo_client/utils/ai_model/ai_inference.dart';
import 'package:flowo_client/utils/ai_model/battery_monitor.dart';
import 'package:flowo_client/utils/logger.dart';

/// A class that extends AI inference with battery awareness and optimization
class BatteryAwareAIInference {
  static final BatteryAwareAIInference _instance = BatteryAwareAIInference._internal();

  /// Private constructor
  BatteryAwareAIInference._internal();

  /// Get the singleton instance of BatteryAwareAIInference
  static BatteryAwareAIInference get instance => _instance;

  /// The AI inference instance
  final AIInference _aiInference = AIInference.instance;

  /// The battery monitor instance
  final BatteryMonitor _batteryMonitor = BatteryMonitor.instance;

  /// Whether battery optimization is enabled
  bool _batteryOptimizationEnabled = true;

  /// Set whether battery optimization is enabled
  void setBatteryOptimizationEnabled(bool enabled) {
    _batteryOptimizationEnabled = enabled;
    logInfo('Battery optimization enabled: $_batteryOptimizationEnabled');
  }

  /// Initialize the battery monitor and AI inference
  Future<void> initialize() async {
    // Initialize battery monitor
    await _batteryMonitor.initialize();
    
    logInfo('Battery-aware AI inference initialized');
  }

  /// Initialize the AI inference with a local model file, optimized for battery
  ///
  /// This method initializes the on-device inference if available, with parameters
  /// optimized based on the current battery state.
  Future<bool> initializeModel({
    required String modelPath,
    int? contextSize,
    int? quantizationLevel,
    bool? useGPU,
    String? modelId,
  }) async {
    if (_batteryOptimizationEnabled) {
      // Get battery-optimized parameters
      final optimizedContextSize = contextSize ?? _batteryMonitor.getRecommendedContextSize();
      final optimizedQuantizationLevel = quantizationLevel ?? _batteryMonitor.getRecommendedQuantizationLevel();
      final optimizedUseGPU = useGPU ?? _batteryMonitor.shouldUseGPU();
      
      logInfo('Using battery-optimized parameters: contextSize=$optimizedContextSize, '
          'quantizationLevel=$optimizedQuantizationLevel, useGPU=$optimizedUseGPU');
      
      return _aiInference.initialize(
        modelPath: modelPath,
        contextSize: optimizedContextSize,
        quantizationLevel: optimizedQuantizationLevel,
        useGPU: optimizedUseGPU,
        modelId: modelId,
      );
    } else {
      // Use default parameters
      return _aiInference.initialize(
        modelPath: modelPath,
        contextSize: contextSize ?? 2048,
        quantizationLevel: quantizationLevel ?? 2,
        useGPU: useGPU ?? false,
        modelId: modelId,
      );
    }
  }

  /// Initialize the AI inference with automatic download, optimized for battery
  ///
  /// This method initializes the on-device inference with automatic download if available,
  /// with parameters optimized based on the current battery state.
  Future<bool> initializeWithDownload({
    required String modelId,
    required String modelUrl,
    String? modelVersion,
    String? modelName,
    int? contextSize,
    int? quantizationLevel,
    bool? useGPU,
    Function(double)? onDownloadProgress,
    bool forceDownload = false,
  }) async {
    if (_batteryOptimizationEnabled) {
      // Get battery-optimized parameters
      final optimizedContextSize = contextSize ?? _batteryMonitor.getRecommendedContextSize();
      final optimizedQuantizationLevel = quantizationLevel ?? _batteryMonitor.getRecommendedQuantizationLevel();
      final optimizedUseGPU = useGPU ?? _batteryMonitor.shouldUseGPU();
      
      logInfo('Using battery-optimized parameters: contextSize=$optimizedContextSize, '
          'quantizationLevel=$optimizedQuantizationLevel, useGPU=$optimizedUseGPU');
      
      return _aiInference.initializeWithDownload(
        modelId: modelId,
        modelUrl: modelUrl,
        modelVersion: modelVersion,
        modelName: modelName,
        contextSize: optimizedContextSize,
        quantizationLevel: optimizedQuantizationLevel,
        useGPU: optimizedUseGPU,
        onDownloadProgress: onDownloadProgress,
        forceDownload: forceDownload,
      );
    } else {
      // Use default parameters
      return _aiInference.initializeWithDownload(
        modelId: modelId,
        modelUrl: modelUrl,
        modelVersion: modelVersion,
        modelName: modelName,
        contextSize: contextSize ?? 2048,
        quantizationLevel: quantizationLevel ?? 2,
        useGPU: useGPU ?? false,
        onDownloadProgress: onDownloadProgress,
        forceDownload: forceDownload,
      );
    }
  }

  /// Generate text using AI inference, optimized for battery
  ///
  /// This method tries to use on-device inference if available and preferred,
  /// with parameters optimized based on the current battery state.
  /// If on-device inference is not available or fails, it falls back to cloud API if enabled.
  Future<String> generateText({
    required String prompt,
    int? maxTokens,
    double? temperature,
    String? cloudModel,
  }) async {
    if (_batteryOptimizationEnabled) {
      // Check if we should use cloud API based on battery state
      if (_batteryMonitor.shouldUseCloudAPI()) {
        logInfo('Battery level is low, preferring cloud API for inference');
        _aiInference.setPreferOnDevice(false);
      } else {
        _aiInference.setPreferOnDevice(true);
      }
      
      // Get battery-optimized parameters
      final optimizedMaxTokens = maxTokens ?? _batteryMonitor.getRecommendedMaxTokens();
      
      logInfo('Using battery-optimized parameters: maxTokens=$optimizedMaxTokens');
      
      return _aiInference.generateText(
        prompt: prompt,
        maxTokens: optimizedMaxTokens,
        temperature: temperature ?? 0.7,
        cloudModel: cloudModel,
      );
    } else {
      // Use default parameters
      return _aiInference.generateText(
        prompt: prompt,
        maxTokens: maxTokens ?? 256,
        temperature: temperature ?? 0.7,
        cloudModel: cloudModel,
      );
    }
  }

  /// Estimate task time using AI inference, optimized for battery
  ///
  /// This is a wrapper around generateText that formats the prompt specifically
  /// for task time estimation, with parameters optimized based on the current battery state.
  Future<String> estimateTaskTime(String task, {String? notes, String? cloudModel}) async {
    return generateText(
      prompt: "You are a helpful assistant that estimates how long tasks will take. "
          "Based on the task description, provide a time estimate in hours and minutes. "
          "Only respond with the time estimate, nothing else. "
          "For example: '2 hours 30 minutes' or '45 minutes'. "
          "Task: ${notes != null && notes.isNotEmpty ? "$task\nNotes: $notes" : task}",
      maxTokens: _batteryOptimizationEnabled ? _batteryMonitor.getRecommendedMaxTokens().clamp(32, 64) : 32,
      temperature: 0.3,
      cloudModel: cloudModel,
    );
  }

  /// Break down a task into subtasks using AI inference, optimized for battery
  ///
  /// This is a wrapper around generateText that formats the prompt specifically
  /// for task breakdown, with parameters optimized based on the current battery state.
  Future<String> breakdownTask(String task, int totalTimeMinutes, {String? cloudModel}) async {
    return generateText(
      prompt: "You are a helpful assistant that breaks down tasks into clear, actionable subtasks "
          "and distributes the total estimated time among them. "
          "The total estimated time for the task is $totalTimeMinutes minutes. "
          "Format your response as a numbered list, where each subtask is followed by its estimated time "
          "in minutes in parentheses, like this: '1. Subtask (X minutes)'. "
          "Break down the task into specific subtasks and ensure the sum of the subtask times "
          "equals $totalTimeMinutes minutes: $task",
      maxTokens: _batteryOptimizationEnabled ? _batteryMonitor.getRecommendedMaxTokens().clamp(256, 512) : 512,
      temperature: 0.5,
      cloudModel: cloudModel,
    );
  }

  /// Release the AI inference and battery monitor resources
  Future<void> release() async {
    await _aiInference.release();
    await _batteryMonitor.dispose();
    logInfo('Battery-aware AI inference resources released');
  }

  /// Get the current battery optimization recommendations
  Map<String, dynamic> getBatteryOptimizationRecommendations() {
    return _batteryMonitor.getOptimizationRecommendations();
  }
}