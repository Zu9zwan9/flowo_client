import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../design/glassmorphic_container.dart';
import '../../theme_notifier.dart';

/// A Cupertino-style divider with glassmorphic effect
class CupertinoDivider extends StatelessWidget {
  /// The height of the divider
  final double height;

  /// The color of the divider (if null, uses theme-based color)
  final Color? color;

  /// Whether to use a gradient effect
  final bool useGradient;

  /// Whether to add a subtle shimmer effect
  final bool showShimmer;

  /// The padding around the divider
  final EdgeInsetsGeometry? padding;

  /// Creates a Cupertino-style divider with glassmorphic effect
  const CupertinoDivider({
    super.key,
    this.height = 1.0,
    this.color,
    this.useGradient = false,
    this.showShimmer = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final glassmorphicTheme = themeNotifier.glassmorphicTheme;
    final isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    // Determine the effective color based on theme
    final effectiveColor =
        color ??
        (isDarkMode
            ? glassmorphicTheme.accentColor.withOpacity(0.3)
            : glassmorphicTheme.accentColor.withOpacity(0.2));

    // Use gradient colors from theme if useGradient is true
    final effectiveGradientColors = glassmorphicTheme.gradientColors;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: GlassmorphicContainer(
        height: height,
        blur:
            glassmorphicTheme.defaultBlur *
            0.5, // Use a lighter blur for dividers
        opacity: glassmorphicTheme.defaultOpacity * 0.7,
        borderRadius: BorderRadius.circular(height / 2), // Rounded edges
        backgroundColor: effectiveColor,
        useGradient: useGradient,
        gradientColors: effectiveGradientColors,
        borderWidth: 0, // No border for dividers
        showShimmer: showShimmer,
        child: const SizedBox(), // Empty child as it's just a divider
      ),
    );
  }
}
