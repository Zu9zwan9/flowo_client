import 'dart:convert';

import 'package:flowo_client/models/ambient_scene.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Service for managing ambient scenes, videos, and audio
class AmbientService extends ChangeNotifier {
  final Box<AmbientScene> _scenesBox;

  AmbientScene? _currentScene;
  YoutubePlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  double _volume = 0.7;

  // Getters
  AmbientScene? get currentScene => _currentScene;
  YoutubePlayerController? get videoController => _videoController;
  double get volume => _volume;
  bool get isPlaying => _isPlaying;

  AmbientService(this._scenesBox) {
    _initializeDefaultScenes();
  }

  Future<void> _initializeDefaultScenes() async {
    if (_scenesBox.isEmpty) {
      final defaultScenes = [
        AmbientScene(
          id: const Uuid().v4(),
          name: 'Cozy Cafe',
          description: 'A warm cafe atmosphere with gentle background noise',
          videoAssetPath: 'cafe ambience', // Search query for YouTube
          audioAssetPaths: [''], // Will be populated with audio from YouTube
          thumbnailAssetPath: '', // Will be populated from YouTube
          category: 'Urban',
        ),
        AmbientScene(
          id: const Uuid().v4(),
          name: 'Forest Retreat',
          description: 'Peaceful forest scenery with birds and rustling leaves',
          videoAssetPath: 'forest nature ambience', // Search query for YouTube
          audioAssetPaths: [''],
          thumbnailAssetPath: '',
          category: 'Nature',
        ),
        AmbientScene(
          id: const Uuid().v4(),
          name: 'Beach Sunset',
          description: 'Calming ocean waves at sunset',
          videoAssetPath: 'beach waves sunset', // Search query for YouTube
          audioAssetPaths: [''],
          thumbnailAssetPath: '',
          category: 'Nature',
        ),
        AmbientScene(
          id: const Uuid().v4(),
          name: 'Rainy Window',
          description: 'Rain falling on a window with a cozy interior view',
          videoAssetPath: 'rain on window ambience', // Search query for YouTube
          audioAssetPaths: [''],
          thumbnailAssetPath: '',
          category: 'Weather',
        ),
      ];

      for (final scene in defaultScenes) {
        await _scenesBox.put(scene.id, scene);
      }
    }
  }

  /// Get all available scenes
  List<AmbientScene> getAllScenes() {
    return _scenesBox.values.toList();
  }

  /// Get scenes by category
  List<AmbientScene> getScenesByCategory(String category) {
    return _scenesBox.values
        .where((scene) => scene.category == category)
        .toList();
  }

  /// Get all unique categories
  List<String> getAllCategories() {
    return _scenesBox.values.map((scene) => scene.category).toSet().toList();
  }

  /// Search for YouTube video based on query and theme
  /// Returns a Map with video ID and thumbnail URL that matches the theme of the ambient scene
  Future<Map<String, String>> _searchYoutubeVideo(
    String query,
    String category,
  ) async {
    try {
      // Enhanced query with more specific terms based on category
      final enhancedQuery = _enhanceQueryByCategory(query, category);

      // In a production app, you would use YouTube Data API with a valid API key
      // For now, we'll use a more sophisticated fallback mechanism

      // Try to make the API call if you have a valid API key
      // Replace 'YOUR_YOUTUBE_API_KEY' with a valid key to enable this functionality
      final apiKey = 'AIzaSyCE8Z234w3E2rOyqK_k3qBHhuybsx3SMXo';

      if (apiKey != 'YOUR_YOUTUBE_API_KEY') {
        final response = await http.get(
          Uri.parse(
            'https://www.googleapis.com/youtube/v3/search?'
            'part=snippet&maxResults=1&q=$enhancedQuery&type=video&videoDuration=long&'
            'key=$apiKey',
          ),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['items'] != null && data['items'].isNotEmpty) {
            final videoId = data['items'][0]['id']['videoId'];
            final thumbnailUrl =
                data['items'][0]['snippet']['thumbnails']['high']['url'];
            return {'videoId': videoId, 'thumbnailUrl': thumbnailUrl};
          }
        }
      }

      // If API call fails or no API key, use our curated fallback videos by category
      final videoId = _getFallbackVideoByCategory(category, query);
      // Generate thumbnail URL for fallback videos
      final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
      return {'videoId': videoId, 'thumbnailUrl': thumbnailUrl};
    } catch (e) {
      debugPrint('YouTube search error: $e');
      final videoId = _getFallbackVideoByCategory(category, query);
      // Generate thumbnail URL for fallback videos
      final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
      return {'videoId': videoId, 'thumbnailUrl': thumbnailUrl};
    }
  }

  /// Enhance the search query based on the category to get more relevant results
  String _enhanceQueryByCategory(String baseQuery, String category) {
    switch (category.toLowerCase()) {
      case 'urban':
        return '$baseQuery ambient scene relaxing 4k';
      case 'nature':
        return '$baseQuery ambient scene relaxing nature sounds 4k';
      case 'weather':
        return '$baseQuery ambient scene relaxing sounds 4k';
      default:
        return '$baseQuery ambient scene relaxing 4k';
    }
  }

  /// Get a fallback video ID based on the category and query
  /// These are curated videos that match common ambient themes
  String _getFallbackVideoByCategory(String category, String query) {
    // Lowercase for case-insensitive matching
    final lowerQuery = query.toLowerCase();
    final lowerCategory = category.toLowerCase();

    // Check for specific themes in the query first
    if (lowerQuery.contains('cafe') || lowerQuery.contains('coffee')) {
      return 'VMAPnbLuUXQ'; // Cafe Ambient
    } else if (lowerQuery.contains('rain') || lowerQuery.contains('storm')) {
      return 'mPZkdNFkNps'; // Rain on window
    } else if (lowerQuery.contains('forest') || lowerQuery.contains('nature')) {
      return 'xNN7iTA57jM'; // Forest sounds
    } else if (lowerQuery.contains('beach') ||
        lowerQuery.contains('ocean') ||
        lowerQuery.contains('waves')) {
      return 'Nep1qytq9JM'; // Ocean waves
    } else if (lowerQuery.contains('fireplace') ||
        lowerQuery.contains('fire')) {
      return 'L_LUpnjgPso'; // Fireplace
    } else if (lowerQuery.contains('city') || lowerQuery.contains('urban')) {
      return 'gVKEM4K8J8A'; // City ambience
    }

    // If no specific theme found in query, fall back to category
    switch (lowerCategory) {
      case 'urban':
        return 'VMAPnbLuUXQ'; // Cafe Ambient
      case 'nature':
        return 'xNN7iTA57jM'; // Forest sounds
      case 'weather':
        return 'mPZkdNFkNps'; // Rain on window
      default:
        return 'jfKfPfyJRdk'; // Lofi girl (general fallback)
    }
  }

  /// Select and play a scene
  Future<void> selectScene(AmbientScene scene) async {
    // Clean up previous controllers
    await _disposeControllers();

    _currentScene = scene;

    try {
      // Search for a YouTube video based on the scene name and category
      final videoData = await _searchYoutubeVideo(
        scene.videoAssetPath,
        scene.category,
      );

      final videoId = videoData['videoId'];
      final thumbnailUrl = videoData['thumbnailUrl'];

      if (videoId != null) {
        // Initialize YouTube player controller
        _videoController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: YoutubePlayerFlags(
            autoPlay: false,
            mute: true,
            loop: true,
            disableDragSeek: true,
            enableCaption: false,
            hideControls: true,
          ),
        );

        // Use the audio from the YouTube video
        _audioPlayer = AudioPlayer();
        // We'll just rely on YouTube audio for simplicity

        // Update the scene with the thumbnail URL
        if (thumbnailUrl != null) {
          // Create a copy of the scene with the updated thumbnailAssetPath
          final updatedScene = scene.copyWith(thumbnailAssetPath: thumbnailUrl);

          // Update the scene in the box
          await _scenesBox.put(scene.id, updatedScene);

          // Update the current scene reference
          _currentScene = updatedScene;
        }
      }
    } catch (e) {
      debugPrint('Error setting up YouTube video: $e');
    }

    notifyListeners();
  }

  /// Play the current scene
  Future<void> play() async {
    if (_currentScene == null) return;
    if (_videoController != null) {
      _videoController!.play();
    }

    // Audio is handled by YouTube player
    _isPlaying = true;
    notifyListeners();
  }

  /// Pause the current scene
  Future<void> pause() async {
    if (_videoController != null) {
      _videoController!.pause();
    }

    // Audio is handled by YouTube player
    _isPlaying = false;
    notifyListeners();
  }

  /// Set the volume for audio
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);

    if (_audioPlayer != null) {
      await _audioPlayer!.setVolume(_volume);
    }

    notifyListeners();
  }

  /// Change the audio track for the current scene
  Future<void> changeAudioTrack(String audioAssetPath) async {
    if (_audioPlayer == null || _currentScene == null) return;

    final wasPlaying = _isPlaying;

    // Pause current audio
    await _audioPlayer!.pause();

    // Set new audio source
    await _audioPlayer!.setAsset(audioAssetPath);
    await _audioPlayer!.setLoopMode(LoopMode.one);
    await _audioPlayer!.setVolume(_volume);

    // Resume if it was playing
    if (wasPlaying) {
      await _audioPlayer!.play();
    }

    notifyListeners();
  }

  /// Dispose controllers when no longer needed
  Future<void> _disposeControllers() async {
    if (_videoController != null) {
      _videoController!.pause();
      _videoController!.dispose();
      _videoController = null;
    }

    if (_audioPlayer != null) {
      await _audioPlayer!.pause();
      await _audioPlayer!.dispose();
      _audioPlayer = null;
    }

    _isPlaying = false;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }
}
