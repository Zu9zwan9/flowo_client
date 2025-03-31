import 'dart:io';

import 'package:flowo_client/utils/ai_model/model_info.dart';
import 'package:flowo_client/utils/logger.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A class that manages downloading and caching of AI models for on-device inference.
class ModelDownloadManager {
  static final ModelDownloadManager _instance =
      ModelDownloadManager._internal();

  /// Private constructor
  ModelDownloadManager._internal();

  /// Get the singleton instance of ModelDownloadManager
  static ModelDownloadManager get instance => _instance;

  /// Base directory for storing downloaded models
  Directory? _modelsDirectory;

  /// Maximum cache size in bytes (default: 2GB)
  int _maxCacheSize = 2 * 1024 * 1024 * 1024;

  /// Current cache size in bytes
  int _currentCacheSize = 0;

  /// Cache strategy (LRU or LFU)
  String _cacheStrategy = 'LRU'; // 'LRU' or 'LFU'

  /// Initialize the model download manager
  Future<void> initialize() async {
    if (_modelsDirectory != null) {
      return;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      _modelsDirectory = Directory(p.join(appDir.path, 'ai_models'));

      if (!await _modelsDirectory!.exists()) {
        await _modelsDirectory!.create(recursive: true);
      }

      // Calculate current cache size
      await _calculateCurrentCacheSize();

      logInfo(
        'Model download manager initialized at ${_modelsDirectory!.path}',
      );
      logInfo(
        'Current cache size: ${(_currentCacheSize / 1024 / 1024).toStringAsFixed(2)} MB',
      );
    } catch (e) {
      logError('Error initializing model download manager: $e');
      rethrow;
    }
  }

  /// Set the maximum cache size in bytes
  void setMaxCacheSize(int maxSizeBytes) {
    _maxCacheSize = maxSizeBytes;
    logInfo(
      'Maximum cache size set to ${(maxSizeBytes / 1024 / 1024).toStringAsFixed(2)} MB',
    );
  }

  /// Get the maximum cache size in bytes
  int getMaxCacheSize() {
    return _maxCacheSize;
  }

  /// Get the current cache size in bytes
  int getCurrentCacheSize() {
    return _currentCacheSize;
  }

  /// Set the cache strategy ('LRU' or 'LFU')
  void setCacheStrategy(String strategy) {
    if (strategy != 'LRU' && strategy != 'LFU') {
      throw ArgumentError('Cache strategy must be either "LRU" or "LFU"');
    }
    _cacheStrategy = strategy;
    logInfo('Cache strategy set to $_cacheStrategy');
  }

  /// Calculate the current cache size by summing the sizes of all downloaded models
  Future<void> _calculateCurrentCacheSize() async {
    _currentCacheSize = 0;

    final modelIds = await listDownloadedModels();
    for (final modelId in modelIds) {
      final modelInfo = await getModelInfo(modelId);
      if (modelInfo != null) {
        _currentCacheSize += modelInfo.size;
      }
    }
  }

  /// Check if a model is already downloaded
  Future<bool> isModelDownloaded(String modelId, {String? version}) async {
    await _ensureInitialized();

    final modelDir = Directory(p.join(_modelsDirectory!.path, modelId));
    if (!await modelDir.exists()) {
      return false;
    }

    if (version != null) {
      final versionFile = File(p.join(modelDir.path, 'version.txt'));
      if (await versionFile.exists()) {
        final currentVersion = await versionFile.readAsString();
        return currentVersion.trim() == version.trim();
      }
      return false;
    }

    // If no version specified, just check if the model directory exists and has files
    final modelFiles = await modelDir.list().toList();
    return modelFiles.isNotEmpty;
  }

  /// Get the local path to a downloaded model
  Future<String?> getModelPath(String modelId) async {
    await _ensureInitialized();

    if (!await isModelDownloaded(modelId)) {
      return null;
    }

    final modelDir = Directory(p.join(_modelsDirectory!.path, modelId));
    final modelFiles =
        await modelDir
            .list()
            .where(
              (entity) =>
                  entity is File &&
                  !p.basename(entity.path).startsWith('.') &&
                  p.basename(entity.path) != 'version.txt' &&
                  p.basename(entity.path) != 'info.json',
            )
            .toList();

    if (modelFiles.isEmpty) {
      return null;
    }

    // Return the path to the first model file found
    return modelFiles.first.path;
  }

  /// Download a model from a remote URL
  Future<bool> downloadModel({
    required String modelId,
    required String url,
    String? version,
    String? modelName,
    Function(double)? onProgress,
    bool forceDownload = false,
  }) async {
    await _ensureInitialized();

    try {
      // Check if the model is already downloaded
      if (!forceDownload &&
          await isModelDownloaded(modelId, version: version)) {
        logInfo('Model $modelId is already downloaded');

        // Update usage statistics
        await markModelAsUsed(modelId);

        onProgress?.call(1.0);
        return true;
      }

      // Get the size of the model to be downloaded
      final modelSize = await _getModelSizeFromUrl(url);

      // Check if we have enough space in the cache
      if (_currentCacheSize + modelSize > _maxCacheSize) {
        logInfo(
          'Not enough space in cache for model $modelId (${(modelSize / 1024 / 1024).toStringAsFixed(2)} MB)',
        );

        // Try to free up space
        await ensureCacheSize();

        // Check if we have enough space now
        if (_currentCacheSize + modelSize > _maxCacheSize) {
          logWarning(
            'Still not enough space in cache after cleanup. Consider increasing cache size or removing models manually.',
          );

          // We'll still try to download, but it might fail if the device doesn't have enough storage
        }
      }

      // Create model directory if it doesn't exist
      final modelDir = Directory(p.join(_modelsDirectory!.path, modelId));
      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }

      // Start the download
      logInfo('Starting download of model $modelId from $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw HttpException(
          'Failed to download model: HTTP ${response.statusCode}',
          uri: Uri.parse(url),
        );
      }

      // Create the output file
      final fileName = _getFileNameFromUrl(url);
      final file = File(p.join(modelDir.path, fileName));
      await file.writeAsBytes(response.bodyBytes);

      // Save version information if provided
      if (version != null) {
        final versionFile = File(p.join(modelDir.path, 'version.txt'));
        await versionFile.writeAsString(version);
      }

      // Get the actual file size
      final fileSize = await file.length();

      // Save model info
      final modelInfo = ModelInfo(
        id: modelId,
        name: modelName ?? modelId,
        version: version,
        size: fileSize,
        downloadDate: DateTime.now(),
        filePath: file.path,
      );

      // Mark the model as used
      modelInfo.markAsUsed();

      await _saveModelInfo(modelId, modelInfo);

      // Update the cache size
      _currentCacheSize += fileSize;

      logInfo(
        'Model $modelId downloaded successfully (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)',
      );
      onProgress?.call(1.0);
      return true;
    } catch (e) {
      logError('Error downloading model $modelId: $e');
      return false;
    }
  }

  /// Get the size of a model from its URL
  Future<int> _getModelSizeFromUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url));

      if (response.statusCode != 200) {
        throw HttpException(
          'Failed to get model size: HTTP ${response.statusCode}',
          uri: Uri.parse(url),
        );
      }

      final contentLength = response.headers['content-length'];
      if (contentLength != null) {
        return int.parse(contentLength);
      }

      // If content-length is not available, use a default size estimate (100MB)
      return 100 * 1024 * 1024;
    } catch (e) {
      logWarning(
        'Error getting model size from URL: $e. Using default size estimate.',
      );
      // Use a default size estimate (100MB)
      return 100 * 1024 * 1024;
    }
  }

  /// Delete a downloaded model
  Future<bool> deleteModel(String modelId) async {
    await _ensureInitialized();

    try {
      final modelDir = Directory(p.join(_modelsDirectory!.path, modelId));
      if (await modelDir.exists()) {
        await modelDir.delete(recursive: true);
        logInfo('Model $modelId deleted successfully');
        return true;
      }
      return false;
    } catch (e) {
      logError('Error deleting model $modelId: $e');
      return false;
    }
  }

  /// List all downloaded models
  Future<List<String>> listDownloadedModels() async {
    await _ensureInitialized();

    final modelIds = <String>[];

    try {
      final modelDirs =
          await _modelsDirectory!
              .list()
              .where((entity) => entity is Directory)
              .toList();

      for (final dir in modelDirs) {
        final modelId = p.basename(dir.path);
        modelIds.add(modelId);
      }
    } catch (e) {
      logError('Error listing downloaded models: $e');
    }

    return modelIds;
  }

  /// Ensure the manager is initialized
  Future<void> _ensureInitialized() async {
    if (_modelsDirectory == null) {
      await initialize();
    }
  }

  /// Extract a filename from a URL
  String _getFileNameFromUrl(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      final lastSegment = pathSegments.last;
      if (lastSegment.isNotEmpty) {
        return lastSegment;
      }
    }

    // If we can't extract a filename, generate one based on the URL hash
    return 'model_${url.hashCode.abs()}.bin';
  }

  /// Save model information to a file
  Future<void> _saveModelInfo(String modelId, ModelInfo info) async {
    final modelDir = Directory(p.join(_modelsDirectory!.path, modelId));
    final infoFile = File(p.join(modelDir.path, 'info.json'));
    await infoFile.writeAsString(info.toJson());
  }
}
