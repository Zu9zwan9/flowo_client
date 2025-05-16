import 'package:flutter/cupertino.dart';

/// A comprehensive color scheme for the app following Apple's Human Interface Guidelines.
/// These colors adapt automatically to light and dark modes.
class AppColors {
  /// Private constructor to prevent instantiation
  AppColors._();

  // MARK: - System Colors (from CupertinoColors)

  /// Primary blue color that adapts to light/dark mode
  static const Color primary = CupertinoColors.systemBlue;

  /// Secondary color (green) that adapts to light/dark mode
  static const Color secondary = CupertinoColors.systemGreen;

  /// Accent color (orange) that adapts to light/dark mode
  static const Color accent = CupertinoColors.systemOrange;

  /// Destructive color (red) for deletion actions
  static const Color destructive = CupertinoColors.systemRed;

  /// Gray color that adapts to light/dark mode
  static Color gray = CupertinoColors.systemGrey;

  /// Light gray color that adapts to light/dark mode
  static Color lightGray = CupertinoColors.systemGrey4;

  /// Extra light gray color that adapts to light/dark mode
  static Color extraLightGray = CupertinoColors.systemGrey6;

  // MARK: - Semantic Colors (from CupertinoColors)

  /// Primary text color that adapts to light/dark mode
  static const Color label = CupertinoColors.label;

  /// Secondary text color that adapts to light/dark mode
  static const Color secondaryLabel = CupertinoColors.secondaryLabel;

  /// Tertiary text color that adapts to light/dark mode
  static const Color tertiaryLabel = CupertinoColors.tertiaryLabel;

  /// Quaternary text color that adapts to light/dark mode
  static const Color quaternaryLabel = CupertinoColors.quaternaryLabel;

  /// Primary fill color that adapts to light/dark mode
  static const Color fill = CupertinoColors.systemFill;

  /// Secondary fill color that adapts to light/dark mode
  static const Color secondaryFill = CupertinoColors.secondarySystemFill;

  /// Tertiary fill color that adapts to light/dark mode
  static const Color tertiaryFill = CupertinoColors.tertiarySystemFill;

  /// Quaternary fill color that adapts to light/dark mode
  static const Color quaternaryFill = CupertinoColors.quaternarySystemFill;

  /// Background color that adapts to light/dark mode
  static const Color background = CupertinoColors.systemBackground;

  /// Secondary background color that adapts to light/dark mode
  static const Color secondaryBackground =
      CupertinoColors.secondarySystemBackground;

  /// Grouped background color that adapts to light/dark mode
  static const Color groupedBackground =
      CupertinoColors.systemGroupedBackground;

  /// Secondary grouped background color that adapts to light/dark mode
  static const Color secondaryGroupedBackground =
      CupertinoColors.secondarySystemGroupedBackground;

  /// Separator color that adapts to light/dark mode
  static const Color separator = CupertinoColors.separator;

  /// Opaque separator color that adapts to light/dark mode
  static const Color opaqueSeparator = CupertinoColors.opaqueSeparator;

  // MARK: - Task Priority Colors

  /// Color for low priority tasks
  static const Color lowPriority = CupertinoColors.systemBlue;

  /// Color for medium priority tasks
  static const Color mediumPriority = CupertinoColors.systemOrange;

  /// Color for high priority tasks
  static const Color highPriority = CupertinoColors.systemRed;

  // MARK: - Notification Colors

  /// Color for notification badges
  static const Color notificationBadge = CupertinoColors.systemRed;

  // MARK: - Helper Methods

  /// Returns a color that adapts to the given brightness
  static Color adaptiveColor(
    Color lightColor,
    Color darkColor,
    BuildContext context,
  ) {
    final brightness = CupertinoTheme.of(context).brightness;
    return brightness == Brightness.dark ? darkColor : lightColor;
  }

  /// Returns a color with the specified opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Returns a color that is slightly lighter than the given color
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Returns a color that is slightly darker than the given color
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Returns a color with increased saturation
  static Color saturate(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final saturation = (hsl.saturation + amount).clamp(0.0, 1.0);
    return hsl.withSaturation(saturation).toColor();
  }

  /// Returns a color with decreased saturation
  static Color desaturate(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final saturation = (hsl.saturation - amount).clamp(0.0, 1.0);
    return hsl.withSaturation(saturation).toColor();
  }

  /// Determines if a color is dark (to choose appropriate text color)
  static bool isColorDark(Color color) {
    // Calculate the perceived brightness using the formula
    // (0.299*R + 0.587*G + 0.114*B)
    final double brightness =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    // If the brightness is less than 0.5, the color is considered dark
    return brightness < 0.5;
  }

  /// Returns an appropriate text color (white or black) based on the background color
  static Color appropriateTextColor(Color backgroundColor) {
    return isColorDark(backgroundColor)
        ? CupertinoColors.white
        : CupertinoColors.black;
  }
}
