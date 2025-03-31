import 'dart:async';

import 'package:flowo_client/utils/ai_model/chat_pipeline.dart';
import 'package:flowo_client/utils/ai_model/on_device_inference.dart';
import 'package:flowo_client/utils/ai_model/battery_monitor.dart';
import 'package:flowo_client/utils/env.dart';
import 'package:flowo_client/utils/logger.dart';

/// A class that provides AI inference with fallback between on-device and cloud API
class AIInference {
  static final AIInference _instance = AIInference._internal();

  /// Private constructor
  AIInference._internal();

  /// Get the singleton instance of AIInference
  static AIInference get instance => _instance;

  /// The on-device inference instance
  final OnDeviceInference _onDeviceInference = OnDeviceInference.instance;

  /// The cloud API key
  final String _apiKey = api.apiKey;

  /// The default model to use for cloud API fallback
  final String _defaultCloudModel = 'HuggingFaceH4/zephyr-7b-beta';

  /// Whether to prefer on-device inference over cloud API
  bool _preferOnDevice = true;

  /// Whether to use cloud API as fallback when on-device inference fails
  bool _useCloudFallback = true;

  /// Set whether to prefer on-device inference over cloud API
  void setPreferOnDevice(bool preferOnDevice) {
    _preferOnDevice = preferOnDevice;
    logInfo('Prefer on-device inference: $_preferOnDevice');
  }

  /// Set whether to use cloud API as fallback when on-device inference fails
  void setUseCloudFallback(bool useCloudFallback) {
    _useCloudFallback = useCloudFallback;
    logInfo('Use cloud API fallback: $_useCloudFallback');
  }

  /// Initialize the AI inference with a local model file
  ///
  /// This method initializes the on-device inference if available.
  /// Returns true if initialization was successful, false otherwise.
  Future<bool> initialize({
    required String modelPath,
    int contextSize = 2048,
    int quantizationLevel = 2,
    bool useGPU = false,
    String? modelId,
  }) async {
    if (!_onDeviceInference.isSupported) {
      logWarning('On-device inference is not supported on this platform');
      return false;
    }

    try {
      final result = await _onDeviceInference.initialize(
        modelPath: modelPath,
        contextSize: contextSize,
        quantizationLevel: quantizationLevel,
        useGPU: useGPU,
      );

      if (result) {
        logInfo('On-device inference initialized successfully');
      } else {
        logWarning('Failed to initialize on-device inference');
      }

      return result;
    } catch (e) {
      logError('Error initializing on-device inference: $e');
      return false;
    }
  }

  /// Initialize the AI inference with automatic download
  ///
  /// This method initializes the on-device inference with automatic download if available.
  /// Returns true if initialization was successful, false otherwise.
  Future<bool> initializeWithDownload({
    required String modelId,
    required String modelUrl,
    String? modelVersion,
    String? modelName,
    int contextSize = 2048,
    int quantizationLevel = 2,
    bool useGPU = false,
    Function(double)? onDownloadProgress,
    bool forceDownload = false,
  }) async {
    if (!_onDeviceInference.isSupported) {
      logWarning('On-device inference is not supported on this platform');
      return false;
    }

    try {
      final result = await _onDeviceInference.initializeWithDownload(
        modelId: modelId,
        modelUrl: modelUrl,
        modelVersion: modelVersion,
        modelName: modelName,
        contextSize: contextSize,
        quantizationLevel: quantizationLevel,
        useGPU: useGPU,
        onDownloadProgress: onDownloadProgress,
        forceDownload: forceDownload,
      );

      if (result) {
        logInfo('On-device inference initialized successfully with download');
      } else {
        logWarning('Failed to initialize on-device inference with download');
      }

      return result;
    } catch (e) {
      logError('Error initializing on-device inference with download: $e');
      return false;
    }
  }

  /// Generate text using AI inference
  ///
  /// This method tries to use on-device inference if available and preferred.
  /// If on-device inference is not available or fails, it falls back to cloud API if enabled.
  Future<String> generateText({
    required String prompt,
    int maxTokens = 256,
    double temperature = 0.7,
    String? cloudModel,
  }) async {
    // Try on-device inference if available and preferred
    if (_preferOnDevice &&
        _onDeviceInference.isSupported &&
        _onDeviceInference.isInitialized) {
      try {
        logInfo('Generating text using on-device inference');
        final result = await _onDeviceInference.generateText(
          prompt: prompt,
          maxTokens: maxTokens,
          temperature: temperature,
        );

        // Check if the result is an error message
        if (!result.startsWith('Error:')) {
          logInfo('Successfully generated text using on-device inference');
          return result;
        }

        logWarning('On-device inference failed: $result');
      } catch (e) {
        logError('Error generating text with on-device inference: $e');
      }
    }

    // Fall back to cloud API if enabled
    if (_useCloudFallback) {
      try {
        logInfo('Falling back to cloud API for text generation');
        final model = cloudModel ?? _defaultCloudModel;
        final pipeline = ChatPipeline(
          model: model,
          apiKey: _apiKey,
          maxTokens: maxTokens,
        );

        final messages = [
          {'role': 'user', 'content': prompt},
        ];

        final response = await pipeline.call(messages);
        if (response != null &&
            response['choices'] != null &&
            response['choices'].isNotEmpty) {
          final content = response['choices'][0]['message']['content'];
          logInfo('Successfully generated text using cloud API');
          return content;
        }

        logWarning('Cloud API returned invalid response: $response');
        return 'Error: Cloud API returned invalid response';
      } catch (e) {
        logError('Error generating text with cloud API: $e');
        return 'Error: Failed to generate text with cloud API: $e';
      }
    }

    // If we get here, both on-device and cloud API failed or were disabled
    logError(
      'Failed to generate text: on-device inference and cloud API both failed or were disabled',
    );
    return 'Error: Failed to generate text. Please try again later.';
  }

  /// Estimate task time using AI inference
  ///
  /// This is a wrapper around generateText that formats the prompt specifically
  /// for task time estimation.
  Future<String> estimateTaskTime(
    String task, {
    String? notes,
    String? cloudModel,
  }) async {
    // Create context from task and notes
    final context =
        notes != null && notes.isNotEmpty ? "$task\nNotes: $notes" : task;

    // Create a prompt for task time estimation
    final prompt =
        "You are a helpful assistant that estimates how long tasks will take. "
        "Based on the task description, provide a time estimate in hours and minutes. "
        "Only respond with the time estimate, nothing else. "
        "For example: '2 hours 30 minutes' or '45 minutes'. "
        "Task: $context";

    return generateText(
      prompt: prompt,
      maxTokens: 32, // Short response for time estimate
      temperature: 0.3, // Lower temperature for more consistent results
      cloudModel: cloudModel,
    );
  }

  /// Break down a task into subtasks using AI inference
  ///
  /// This is a wrapper around generateText that formats the prompt specifically
  /// for task breakdown.
  Future<String> breakdownTask(
    String task,
    int totalTimeMinutes, {
    String? cloudModel,
  }) async {
    // Create a prompt for task breakdown
    final prompt =
        "You are a helpful assistant that breaks down tasks into clear, actionable subtasks "
        "and distributes the total estimated time among them. "
        "The total estimated time for the task is $totalTimeMinutes minutes. "
        "Format your response as a numbered list, where each subtask is followed by its estimated time "
        "in minutes in parentheses, like this: '1. Subtask (X minutes)'. "
        "Break down the task into specific subtasks and ensure the sum of the subtask times "
        "equals $totalTimeMinutes minutes: $task";

    return generateText(
      prompt: prompt,
      maxTokens: 512, // Longer response for task breakdown
      temperature: 0.5, // Moderate temperature for creativity but consistency
      cloudModel: cloudModel,
    );
  }

  /// Release the AI inference resources
  Future<void> release() async {
    if (_onDeviceInference.isSupported && _onDeviceInference.isInitialized) {
      try {
        await _onDeviceInference.release();
        logInfo('On-device inference resources released');
      } catch (e) {
        logError('Error releasing on-device inference resources: $e');
      }
    }
  }
}
