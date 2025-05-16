import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../models/ambient_scene.dart';
import '../../services/ambient/ambient_service.dart';

/// A screen that displays ambient videos and plays ambient sounds
/// to create a focused and relaxing environment for work or study.
class AmbientScreen extends StatefulWidget {
  const AmbientScreen({super.key});

  @override
  State<AmbientScreen> createState() => _AmbientScreenState();
}

class _AmbientScreenState extends State<AmbientScreen>
    with WidgetsBindingObserver {
  String _selectedCategory = '';
  bool _isFullScreen = false;
  bool _showControls = true;
  bool _isPortrait = true;
  late AmbientService _ambientService;
  Timer? _controlsTimer;
  // Get a color based on the category
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'urban':
        return CupertinoColors.systemIndigo;
      case 'nature':
        return CupertinoColors.systemGreen;
      case 'weather':
        return CupertinoColors.systemBlue;
      case 'ocean':
        return CupertinoColors.systemTeal;
      case 'space':
        return CupertinoColors.systemPurple;
      case 'fire':
        return CupertinoColors.systemRed;
      case 'rain':
        return CupertinoColors.systemGrey;
      case 'snow':
        return CupertinoColors.systemGrey2;
      case 'forest':
        return CupertinoColors.systemGreen.withOpacity(0.7);
      default:
        return CupertinoColors.systemGrey;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Set preferred orientation to portrait by default
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Initialize controls auto-hide timer
    _setupControlsTimer();
  }

  void _setupControlsTimer() {
    // Cancel existing timer if any
    _controlsTimer?.cancel();

    // Set up a new timer to hide controls after 3 seconds of inactivity
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _setupControlsTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Create AmbientService instance
    final ambientScenesBox = Provider.of<Box<AmbientScene>>(context);
    _ambientService = AmbientService(ambientScenesBox);

    // Initialize with first category
    final categories = _ambientService.getAllCategories();
    if (categories.isNotEmpty && _selectedCategory.isEmpty) {
      setState(() {
        _selectedCategory = categories.first;
      });
    }
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _ambientService.dispose();
    // Make sure player controllers are properly disposed
    if (_ambientService.videoController != null) {
      _ambientService.videoController!.pause();
    }
    WidgetsBinding.instance.removeObserver(this);
    // Reset orientation when leaving the screen
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes to ensure proper orientation restoration
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setPreferredOrientations(
        _isPortrait
            ? [DeviceOrientation.portraitUp]
            : [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showControlsTemporarily,
      child: CupertinoPageScaffold(
        navigationBar:
            (_isFullScreen || !_showControls)
                ? null
                : CupertinoNavigationBar(
                  transitionBetweenRoutes: false,
                  middle: const Text('Ambient Focus'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Icon(
                          _isPortrait
                              ? CupertinoIcons.arrow_left_right
                              : CupertinoIcons.arrow_up_down,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPortrait = !_isPortrait;
                            SystemChrome.setPreferredOrientations(
                              _isPortrait
                                  ? [DeviceOrientation.portraitUp]
                                  : [
                                    DeviceOrientation.landscapeLeft,
                                    DeviceOrientation.landscapeRight,
                                  ],
                            );
                          });
                        },
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(CupertinoIcons.fullscreen),
                        onPressed: () {
                          setState(() {
                            _isFullScreen = true;
                            _showControlsTemporarily();
                          });
                        },
                      ),
                    ],
                  ),
                ),
        child: SafeArea(
          minimum:
              _isFullScreen
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Video player
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    // Video content
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          _isFullScreen ? 0 : 12,
                        ),
                        color: CupertinoColors.black,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child:
                          _ambientService.videoController != null
                              ? YoutubePlayer(
                                key: ValueKey(
                                  _ambientService.currentScene?.id ??
                                      'no-scene',
                                ),
                                controller: _ambientService.videoController!,
                                showVideoProgressIndicator: false,
                                progressIndicatorColor:
                                    CupertinoColors.activeBlue,
                                progressColors: const ProgressBarColors(
                                  playedColor: CupertinoColors.activeBlue,
                                  handleColor: CupertinoColors.activeBlue,
                                ),
                                aspectRatio: _isPortrait ? 9 / 16 : 16 / 9,
                                bufferIndicator:
                                    const CupertinoActivityIndicator(
                                      radius: 20,
                                    ),
                                onReady: () {
                                  // Don't automatically toggle fullscreen as this can cause issues
                                  // _ambientService.videoController?.toggleFullScreenMode();
                                },
                              )
                              : const Center(
                                child: Text(
                                  'Select a scene to begin',
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                  ),
                                ),
                              ),
                    ),

                    // Overlay controls
                    // Overlay controls
                    if (_isFullScreen && _showControls)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: CupertinoButton(
                          padding: const EdgeInsets.all(8),
                          color: CupertinoColors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          child: const Icon(
                            CupertinoIcons.fullscreen_exit,
                            color: CupertinoColors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _isFullScreen = false;
                              _showControlsTemporarily();
                            });
                          },
                        ),
                      ),

                    // Play/Pause button overlay
                    // Play/Pause button overlay
                    if (_showControls && _ambientService.currentScene != null)
                      Positioned.fill(
                        child: Center(
                          child: CupertinoButton(
                            padding: const EdgeInsets.all(16),
                            color: CupertinoColors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(30),
                            child: Icon(
                              _ambientService.isPlaying
                                  ? CupertinoIcons.pause
                                  : CupertinoIcons.play,
                              color: CupertinoColors.white,
                              size: 30,
                            ),
                            onPressed: () {
                              if (_ambientService.isPlaying) {
                                _ambientService.pause();
                              } else {
                                _ambientService.play();
                              }
                              _showControlsTemporarily();
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              if (!_isFullScreen && _showControls) ...[
                const SizedBox(height: 16),

                // Volume slider
                if (_ambientService.currentScene != null)
                  Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(CupertinoIcons.volume_down),
                        onPressed: () {
                          final newVolume = (_ambientService.volume - 0.1)
                              .clamp(0.0, 1.0);
                          _ambientService.setVolume(newVolume);
                          _showControlsTemporarily();
                        },
                      ),
                      Expanded(
                        child: CupertinoSlider(
                          value: _ambientService.volume,
                          onChanged: (value) {
                            _ambientService.setVolume(value);
                            _showControlsTemporarily();
                          },
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(CupertinoIcons.volume_up),
                        onPressed: () {
                          final newVolume = (_ambientService.volume + 0.1)
                              .clamp(0.0, 1.0);
                          _ambientService.setVolume(newVolume);
                          _showControlsTemporarily();
                        },
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Category selector
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children:
                        _ambientService
                            .getAllCategories()
                            .map(
                              (category) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  color:
                                      _selectedCategory == category
                                          ? CupertinoColors.activeBlue
                                          : CupertinoColors.systemGrey5,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color:
                                          _selectedCategory == category
                                              ? CupertinoColors.white
                                              : CupertinoColors.label,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  },
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Scene selector
                Expanded(
                  flex: 2,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount:
                        _selectedCategory.isEmpty
                            ? _ambientService.getAllScenes().length
                            : _ambientService
                                .getScenesByCategory(_selectedCategory)
                                .length,
                    itemBuilder: (context, index) {
                      final scenes =
                          _selectedCategory.isEmpty
                              ? _ambientService.getAllScenes()
                              : _ambientService.getScenesByCategory(
                                _selectedCategory,
                              );

                      if (index >= scenes.length) return const SizedBox();

                      final scene = scenes[index];
                      final isSelected =
                          _ambientService.currentScene?.id == scene.id;

                      return GestureDetector(
                        onTap: () async {
                          // Check if selecting the same scene, just toggle play/pause
                          if (isSelected) {
                            if (_ambientService.isPlaying) {
                              _ambientService.pause();
                            } else {
                              _ambientService.play();
                            }
                          } else {
                            // First pause any existing content
                            if (_ambientService.isPlaying) {
                              _ambientService.pause();
                            }

                            // Now select the new scene
                            await _ambientService.selectScene(scene);
                            await _ambientService.play();

                            // Ensure volume is set correctly (for sound to work)
                            _ambientService.videoController?.unMute();
                            _ambientService.setVolume(_ambientService.volume);
                          }

                          // Refresh UI to show the selected scene
                          setState(() {
                            _showControlsTemporarily();
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border:
                                isSelected
                                    ? Border.all(
                                      color: CupertinoColors.activeBlue,
                                      width: 3,
                                    )
                                    : null,
                            color: _getCategoryColor(scene.category),
                            image:
                                scene.thumbnailAssetPath.isNotEmpty
                                    ? DecorationImage(
                                      image:
                                          scene.thumbnailAssetPath.startsWith(
                                                'http',
                                              )
                                              ? NetworkImage(
                                                scene.thumbnailAssetPath,
                                              )
                                              : AssetImage(
                                                    scene.thumbnailAssetPath,
                                                  )
                                                  as ImageProvider,
                                      fit: BoxFit.cover,
                                      colorFilter:
                                          isSelected
                                              ? null
                                              : ColorFilter.mode(
                                                CupertinoColors.black
                                                    .withOpacity(0.3),
                                                BlendMode.darken,
                                              ),
                                    )
                                    : null,
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                bottom: 8,
                                left: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.black.withOpacity(
                                      0.7,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    scene.name,
                                    style: const TextStyle(
                                      color: CupertinoColors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
