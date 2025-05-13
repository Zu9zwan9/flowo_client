import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../theme/theme_notifier.dart';

/// A widget that applies a gradient background when enabled in the ThemeNotifier
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, _) {
        if (!themeNotifier.useGradient) {
          return child;
        }

        // Apply gradient background
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [themeNotifier.customColor, themeNotifier.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        );
      },
    );
  }
}

/// A widget that applies a gradient background to the entire app
class AppGradientBackground extends StatelessWidget {
  final Widget child;

  const AppGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, _) {
        if (!themeNotifier.useGradient) {
          return child;
        }
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [themeNotifier.customColor, themeNotifier.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        );
      },
    );
  }
}

/// Extension to make it easy to wrap any widget with a gradient background
extension GradientBackgroundExtension on Widget {
  Widget withGradientBackground() {
    return GradientBackground(child: this);
  }

  Widget withAppGradientBackground() {
    return AppGradientBackground(child: this);
  }
}
