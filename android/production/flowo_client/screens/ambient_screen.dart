import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../models/ambient_scene.dart';
import '../services/ambient_service.dart';

/// A screen that displays ambient videos and plays ambient sounds
/// to create a focused and relaxing environment for work or study.
class AmbientScreen extends StatefulWidget {
  const AmbientScreen({super.key});

  @override
  State<AmbientScreen> createState() => _AmbientScreenState();
}

class _AmbientScreenState extends State<AmbientScreen> {
  String _selectedCategory = '';
  bool _isFullScreen = false;
  late AmbientService _ambientService;

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
    // Set preferred orientation to landscape for a more immersive experience
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
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
    _ambientService.dispose();
    // Reset orientation when leaving the screen
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar:
          _isFullScreen
              ? null
              : CupertinoNavigationBar(
                middle: const Text('Ambient Focus'),
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.fullscreen),
                  onPressed: () {
                    setState(() {
                      _isFullScreen = true;
                    });
                  },
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
                              controller: _ambientService.videoController!,
                              showVideoProgressIndicator: false,
                              progressIndicatorColor:
                                  CupertinoColors.activeBlue,
                              progressColors: const ProgressBarColors(
                                playedColor: CupertinoColors.activeBlue,
                                handleColor: CupertinoColors.activeBlue,
                              ),
                              aspectRatio: 16 / 9,
                            )
                            : const Center(
                              child: Text(
                                'Select a scene to begin',
                                style: TextStyle(color: CupertinoColors.white),
                              ),
                            ),
                  ),

                  // Overlay controls
                  if (_isFullScreen)
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
                          });
                        },
                      ),
                    ),

                  // Play/Pause button overlay
                  Positioned.fill(
                    child: Center(
                      child: AnimatedOpacity(
                        opacity:
                            _ambientService.currentScene != null ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
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
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (!_isFullScreen) ...[
              const SizedBox(height: 16),

              // Volume slider
              if (_ambientService.currentScene != null)
                Row(
                  children: [
                    const Icon(CupertinoIcons.volume_down),
                    Expanded(
                      child: CupertinoSlider(
                        value: _ambientService.volume,
                        onChanged: (value) {
                          _ambientService.setVolume(value);
                        },
                      ),
                    ),
                    const Icon(CupertinoIcons.volume_up),
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                        await _ambientService.selectScene(scene);
                        await _ambientService.play();

                        // Refresh UI to show the selected scene
                        setState(() {});
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
                                              CupertinoColors.black.withOpacity(
                                                0.3,
                                              ),
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
                                  color: CupertinoColors.black.withOpacity(0.7),
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
    );
  }
}
