import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../theme/dynamic_color_service.dart';
import '../../theme/theme_notifier.dart';
import 'tutorial_content.dart';

/// A screen that displays a tutorial guide for the app.
class TutorialScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const TutorialScreen({super.key, this.onComplete});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final dynamicColorService = DynamicColorService();

    // Get dynamic colors based on the current theme
    final primaryColor = CupertinoDynamicColor.resolve(
      CupertinoColors.systemBlue,
      context,
    );

    // Generate a color palette from the primary color
    final colorPalette = dynamicColorService.generatePalette(primaryColor);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('App Tutorial'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Done'),
          onPressed: () {
            if (widget.onComplete != null) {
              widget.onComplete!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: tutorialContent.length,
                itemBuilder: (context, index) {
                  final content = tutorialContent[index];
                  return _buildTutorialPage(content, colorPalette);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button (hidden on first page)
                  _currentPage > 0
                      ? CupertinoButton(
                        child: const Text('Back'),
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      )
                      : const SizedBox(width: 80),

                  // Page indicator
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      tutorialContent.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _currentPage == index
                                  ? primaryColor
                                  : CupertinoDynamicColor.resolve(
                                    CupertinoColors.systemGrey4,
                                    context,
                                  ),
                        ),
                      ),
                    ),
                  ),

                  // Next/Finish button
                  CupertinoButton(
                    child: Text(
                      _currentPage < tutorialContent.length - 1
                          ? 'Next'
                          : 'Finish',
                    ),
                    onPressed: () {
                      if (_currentPage < tutorialContent.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        if (widget.onComplete != null) {
                          widget.onComplete!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialPage(
    TutorialItem content,
    Map<String, Color> colorPalette,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            content.title,
            style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
          ),
          const SizedBox(height: 16),

          // Media (video or image)
          _buildMediaWidget(content),
          const SizedBox(height: 16),

          // Description
          Text(
            content.description,
            style: CupertinoTheme.of(
              context,
            ).textTheme.textStyle.copyWith(fontSize: 16, height: 1.4),
          ),

          // Tips (if any)
          if (content.tips.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Tips:',
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            ),
            const SizedBox(height: 8),
            ...content.tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      CupertinoIcons.lightbulb_fill,
                      color: colorPalette['analogous1'],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: CupertinoTheme.of(context).textTheme.textStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaWidget(TutorialItem content) {
    // Get feature-specific icon and color
    IconData icon;
    Color iconColor;

    switch (content.title) {
      case 'Welcome to Flowo':
        icon = CupertinoIcons.app_badge;
        iconColor = CupertinoColors.systemBlue;
        break;
      case 'Task Management':
        icon = CupertinoIcons.list_bullet;
        iconColor = CupertinoColors.systemGreen;
        break;
      case 'Habit Tracking':
        icon = CupertinoIcons.repeat;
        iconColor = CupertinoColors.systemIndigo;
        break;
      case 'Calendar & Events':
        icon = CupertinoIcons.calendar;
        iconColor = CupertinoColors.systemPink;
        break;
      case 'Pomodoro Timer':
        icon = CupertinoIcons.timer;
        iconColor = CupertinoColors.systemRed;
        break;
      case 'Analytics & Insights':
        icon = CupertinoIcons.chart_bar_alt_fill;
        iconColor = CupertinoColors.systemPurple;
        break;
      case 'Settings & Customization':
        icon = CupertinoIcons.settings;
        iconColor = CupertinoColors.systemGrey;
        break;
      case 'Ready to Get Started?':
        icon = CupertinoIcons.rocket;
        iconColor = CupertinoColors.systemOrange;
        break;
      default:
        icon = CupertinoIcons.info;
        iconColor = CupertinoColors.systemBlue;
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.systemGrey6,
          context,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: iconColor),
            const SizedBox(height: 16),
            Text(
              content.title,
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // This method is no longer used but kept for reference
  Widget _buildVideoPlayer(String videoPath) {
    return const SizedBox.shrink();
  }
}
