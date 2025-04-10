import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme_notifier.dart';

/// A widget that applies a gradient to the app's background by modifying the theme
class GradientTheme extends StatelessWidget {
  final Widget child;

  const GradientTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, _) {
        // If gradient is not enabled, just return the child
        if (!themeNotifier.useGradient) {
          return child;
        }

        // Create a custom theme with gradient background
        return Stack(
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeNotifier.customColor,
                    themeNotifier.secondaryColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Child with transparent background
            child,
          ],
        );
      },
    );
  }
}

/// Extension to make it easy to wrap any widget with a gradient theme
extension GradientThemeExtension on Widget {
  Widget withGradientTheme() {
    return GradientTheme(child: this);
  }
}
