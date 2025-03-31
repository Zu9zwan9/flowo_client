import 'dart:async';
import 'dart:io';

import 'package:flowo_client/utils/logger.dart';
import 'package:flutter/services.dart';

import 'model_download_manager.dart';

/// A class that provides on-device inference using native modules
class OnDeviceInference {
  static const MethodChannel _channel = MethodChannel(
    'com.example.flowo_client/llama_inference',
  );
  static final OnDeviceInference _instance = OnDeviceInference._internal();

  bool _isInitialized = false;
  bool _isAndroid = false;
  bool _isIOS = false;

  /// Private constructor
  OnDeviceInference._internal() {
    _isAndroid = Platform.isAndroid;
    _isIOS = Platform.isIOS;
  }

  /// Get the singleton instance of OnDeviceInference
  static OnDeviceInference get instance => _instance;

  /// Check if the device supports on-device inference
  bool get isSupported => _isAndroid || _isIOS;

  /// Check if the model is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the on-device inference model with a local model file
  ///
  /// [modelPath] is the path to the model file on the device
  /// [contextSize] is the size of the context window for inference
  /// [quantizationLevel] controls the model quantization level (0-4):
  ///   0: No quantization (F32)
  ///   1: Q4_0 quantization (4-bit, small)
  ///   2: Q4_1 quantization (4-bit, medium)
  ///   3: Q5_0 quantization (5-bit, medium)
  ///   4: Q8_0 quantization (8-bit, high accuracy)
  /// [useGPU] determines whether to use GPU acceleration if available
  /// [modelId] is an optional identifier for the model, used for caching
  Future<bool> initialize({
    required String modelPath,
    int contextSize = 2048,
    int quantizationLevel = 2,
    bool useGPU = false,
    String? modelId,
  }) async {
    if (!isSupported) {
      logWarning('On-device inference is not supported on this platform');
      return false;
    }

    if (_isInitialized) {
      logInfo('Model already initialized');
      return true;
    }

    try {
      final result = await _channel.invokeMethod<bool>('initializeModel', {
        'modelPath': modelPath,
        'contextSize': contextSize,
        'quantizationLevel': quantizationLevel,
        'useGPU': useGPU,
      });

      _isInitialized = result ?? false;

      // If initialization was successful and we have a model ID, mark it as in use
      if (_isInitialized && modelId != null) {
        try {
          final downloadManager = ModelDownloadManager.instance;
          await downloadManager.initialize();
          await downloadManager.markModelAsUsed(modelId);
          logInfo('Model $modelId marked as in use');
        } catch (e) {
          logWarning('Error marking model as in use: $e');
          // Continue even if marking as in use fails
        }
      }

      logInfo(
        'Model initialization ${_isInitialized ? "successful" : "failed"}',
      );
      return _isInitialized;
    } catch (e) {
      logError('Error initializing model: $e');
      return false;
    }
  }

  /// Initialize the on-device inference model with automatic download
  ///
  /// [modelId] is a unique identifier for the model
  /// [modelUrl] is the URL to download the model from if not already downloaded
  /// [modelVersion] is an optional version string for the model
  /// [contextSize] is the size of the context window for inference
  /// [quantizationLevel] controls the model quantization level (0-4):
  ///   0: No quantization (F32)
  ///   1: Q4_0 quantization (4-bit, small)
  ///   2: Q4_1 quantization (4-bit, medium)
  ///   3: Q5_0 quantization (5-bit, medium)
  ///   4: Q8_0 quantization (8-bit, high accuracy)
  /// [useGPU] determines whether to use GPU acceleration if available
  /// [onDownloadProgress] is an optional callback for download progress (0.0 to 1.0)
  /// [forceDownload] if true, will download even if the model is already downloaded
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
    if (!isSupported) {
      logWarning('On-device inference is not supported on this platform');
      return false;
    }

    if (_isInitialized) {
      logInfo('Model already initialized');
      return true;
    }

    try {
      // Initialize the model download manager
      final downloadManager = ModelDownloadManager.instance;
      await downloadManager.initialize();

      // Check if the model is already downloaded
      String? modelPath;
      if (!forceDownload &&
          await downloadManager.isModelDownloaded(
            modelId,
            version: modelVersion,
          )) {
        logInfo('Model $modelId is already downloaded');
        modelPath = await downloadManager.getModelPath(modelId);
      } else {
        // Download the model
        logInfo('Downloading model $modelId from $modelUrl');
        final success = await downloadManager.downloadModel(
          modelId: modelId,
          url: modelUrl,
          version: modelVersion,
          modelName: modelName,
          onProgress: onDownloadProgress,
          forceDownload: forceDownload,
        );

        if (!success) {
          logError('Failed to download model $modelId');
          return false;
        }

        modelPath = await downloadManager.getModelPath(modelId);
      }

      if (modelPath == null) {
        logError('Model path is null after download');
        return false;
      }

      // Initialize the model with the downloaded model path
      return initialize(
        modelPath: modelPath,
        contextSize: contextSize,
        quantizationLevel: quantizationLevel,
        useGPU: useGPU,
      );
    } catch (e) {
      logError('Error initializing model with download: $e');
      return false;
    }
  }

  /// Generate text using the on-device model
  ///
  /// [prompt] is the input prompt for text generation
  /// [maxTokens] is the maximum number of tokens to generate
  /// [temperature] is the temperature parameter for controlling randomness (0.0-1.0)
  Future<String> generateText({
    required String prompt,
    int maxTokens = 256,
    double temperature = 0.7,
  }) async {
    if (!isSupported) {
      return 'Error: On-device inference is not supported on this platform';
    }

    if (!_isInitialized) {
      return 'Error: Model not initialized. Call initialize() first.';
    }

    try {
      final result = await _channel.invokeMethod<String>('generateText', {
        'prompt': prompt,
        'maxTokens': maxTokens,
        'temperature': temperature,
      });

      return result ?? 'Error: Failed to generate text';
    } catch (e) {
      logError('Error generating text: $e');
      return 'Error: $e';
    }
  }

  /// Release the model resources
  Future<void> release() async {
    if (!isSupported || !_isInitialized) {
      return;
    }

    try {
      await _channel.invokeMethod('releaseModel');
      _isInitialized = false;
      logInfo('Model resources released');
    } catch (e) {
      logError('Error releasing model resources: $e');
    }
  }

  /// Estimate task time using the on-device model
  ///
  /// This is a wrapper around generateText that formats the prompt specifically
  /// for task time estimation.
  ///
  /// [task] is the task description
  /// [notes] is optional additional notes about the task
  Future<String> estimateTaskTime(String task, {String? notes}) async {
    if (!isSupported) {
      return 'Error: On-device inference is not supported on this platform';
    }

    if (!_isInitialized) {
      return 'Error: Model not initialized. Call initialize() first.';
    }

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
    );
  }

  /// Break down a task into subtasks using the on-device model
  ///
  /// This is a wrapper around generateText that formats the prompt specifically
  /// for task breakdown.
  ///
  /// [task] is the task description
  /// [totalTimeMinutes] is the total estimated time for the task in minutes
  Future<String> breakdownTask(String task, int totalTimeMinutes) async {
    if (!isSupported) {
      return 'Error: On-device inference is not supported on this platform';
    }

    if (!_isInitialized) {
      return 'Error: Model not initialized. Call initialize() first.';
    }

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
    );
  }
}
