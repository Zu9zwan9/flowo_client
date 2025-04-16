import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A service that provides dynamic colors derived from system or user preferences.
/// This service follows the SOLID principles, particularly the Single Responsibility Principle,
/// by focusing solely on generating and managing dynamic colors.
class DynamicColorService {
  /// Private constructor to enforce singleton pattern
  DynamicColorService._();

  /// Singleton instance
  static final DynamicColorService _instance = DynamicColorService._();

  /// Factory constructor to return the singleton instance
  factory DynamicColorService() => _instance;

  /// Generate a color palette from a base color
  /// This creates a harmonious set of colors that work well together
  Map<String, Color> generatePalette(Color baseColor) {
    final hslColor = HSLColor.fromColor(baseColor);

    // Create complementary color (opposite on the color wheel)
    final complementaryHue = (hslColor.hue + 180) % 360;
    final complementaryColor =
        HSLColor.fromAHSL(
          1.0,
          complementaryHue,
          hslColor.saturation,
          hslColor.lightness,
        ).toColor();

    // Create analogous colors (adjacent on the color wheel)
    final analogous1Hue = (hslColor.hue + 30) % 360;
    final analogous2Hue = (hslColor.hue - 30) % 360;
    final analogous1Color =
        HSLColor.fromAHSL(
          1.0,
          analogous1Hue,
          hslColor.saturation,
          hslColor.lightness,
        ).toColor();
    final analogous2Color =
        HSLColor.fromAHSL(
          1.0,
          analogous2Hue,
          hslColor.saturation,
          hslColor.lightness,
        ).toColor();

    // Create triadic colors (evenly spaced on the color wheel)
    final triadic1Hue = (hslColor.hue + 120) % 360;
    final triadic2Hue = (hslColor.hue + 240) % 360;
    final triadic1Color =
        HSLColor.fromAHSL(
          1.0,
          triadic1Hue,
          hslColor.saturation,
          hslColor.lightness,
        ).toColor();
    final triadic2Color =
        HSLColor.fromAHSL(
          1.0,
          triadic2Hue,
          hslColor.saturation,
          hslColor.lightness,
        ).toColor();

    // Create shades (variations in lightness)
    final lightShade =
        HSLColor.fromAHSL(
          1.0,
          hslColor.hue,
          hslColor.saturation,
          (hslColor.lightness + 0.2).clamp(0.0, 1.0),
        ).toColor();
    final darkShade =
        HSLColor.fromAHSL(
          1.0,
          hslColor.hue,
          hslColor.saturation,
          (hslColor.lightness - 0.2).clamp(0.0, 1.0),
        ).toColor();

    return {
      'primary': baseColor,
      'complementary': complementaryColor,
      'analogous1': analogous1Color,
      'analogous2': analogous2Color,
      'triadic1': triadic1Color,
      'triadic2': triadic2Color,
      'light': lightShade,
      'dark': darkShade,
    };
  }

  /// Extract dominant colors from an image
  /// Note: In a real implementation, this would use image processing libraries
  /// For this example, we'll simulate it with a random color
  Color extractDominantColor() {
    // In a real implementation, this would analyze an image
    // For now, we'll return a random color
    final random = Random();
    return Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      1.0,
    );
  }

  /// Get system colors based on the current platform and brightness
  /// Enhanced to better utilize platform color schemes following Apple's Human Interface Guidelines
  Map<String, Color> getSystemColors(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Base system colors from Cupertino
    final baseColors = {
      // Primary colors
      'blue': CupertinoColors.systemBlue,
      'green': CupertinoColors.systemGreen,
      'indigo': CupertinoColors.systemIndigo,
      'orange': CupertinoColors.systemOrange,
      'pink': CupertinoColors.systemPink,
      'purple': CupertinoColors.systemPurple,
      'red': CupertinoColors.systemRed,
      'teal': CupertinoColors.systemTeal,
      'yellow': CupertinoColors.systemYellow,

      // Grayscale colors
      'gray': CupertinoColors.systemGrey,
      'gray2': CupertinoColors.systemGrey2,
      'gray3': CupertinoColors.systemGrey3,
      'gray4': CupertinoColors.systemGrey4,
      'gray5': CupertinoColors.systemGrey5,
      'gray6': CupertinoColors.systemGrey6,

      // Semantic colors
      'label': CupertinoColors.label,
      'secondaryLabel': CupertinoColors.secondaryLabel,
      'tertiaryLabel': CupertinoColors.tertiaryLabel,
      'quaternaryLabel': CupertinoColors.quaternaryLabel,
      'systemBackground': CupertinoColors.systemBackground,
      'secondarySystemBackground': CupertinoColors.secondarySystemBackground,
      'tertiarySystemBackground': CupertinoColors.tertiarySystemBackground,
      'systemGroupedBackground': CupertinoColors.systemGroupedBackground,
      'secondarySystemGroupedBackground':
          CupertinoColors.secondarySystemGroupedBackground,
      'tertiarySystemGroupedBackground':
          CupertinoColors.tertiarySystemGroupedBackground,
      'separator': CupertinoColors.separator,
      'opaqueSeparator': CupertinoColors.opaqueSeparator,
      'link': CupertinoColors.activeBlue,
      'placeholder': CupertinoColors.placeholderText,
    };

    // Resolve colors based on brightness
    final resolvedColors = <String, Color>{};
    baseColors.forEach((key, value) {
      if (value is CupertinoDynamicColor) {
        resolvedColors[key] = CupertinoDynamicColor.resolve(value, context);
      } else {
        resolvedColors[key] = value;
      }
    });

    return resolvedColors;
  }

  /// Generate a dynamic color palette based on system colors
  /// This creates a harmonious set of colors that adapt to the system theme
  Map<String, Color> generateSystemBasedPalette(BuildContext context) {
    final systemColors = getSystemColors(context);
    final brightness = CupertinoTheme.of(context).brightness;

    // Create a palette that follows iOS design principles
    return {
      'primary': systemColors['blue']!,
      'secondary': systemColors['green']!,
      'accent': systemColors['orange']!,
      'destructive': systemColors['red']!,
      'warning': systemColors['yellow']!,
      'success': systemColors['green']!,
      'info': systemColors['teal']!,

      // Background colors
      'background': systemColors['systemBackground']!,
      'secondaryBackground': systemColors['secondarySystemBackground']!,
      'groupedBackground': systemColors['systemGroupedBackground']!,

      // Text colors
      'text': systemColors['label']!,
      'secondaryText': systemColors['secondaryLabel']!,
      'tertiaryText': systemColors['tertiaryLabel']!,
      'placeholderText': systemColors['placeholder']!,

      // UI element colors
      'separator': systemColors['separator']!,
      'opaqueSeparator': systemColors['opaqueSeparator']!,
      'link': systemColors['link']!,

      // Grayscale
      'gray': systemColors['gray']!,
      'lightGray': systemColors['gray4']!,
      'ultraLightGray': systemColors['gray6']!,

      // Light/dark variants for custom theming
      'light':
          brightness == Brightness.dark
              ? systemColors['gray6']!
              : systemColors['systemBackground']!,
      'dark':
          brightness == Brightness.dark
              ? systemColors['systemBackground']!
              : systemColors['gray6']!,
    };
  }

  /// Apply a noise effect to a color
  /// The noise level determines the intensity of the effect (0.0 to 1.0)
  /// This implementation creates a grain-like effect by adding random noise to each RGB channel
  Color applyNoiseEffect(Color color, double noiseLevel) {
    if (noiseLevel <= 0.0) return color;

    final random = Random();

    // Scale the noise level to create a more noticeable grain effect
    // Higher noise level means more grain
    final grainIntensity = noiseLevel * 30.0; // Up to 30 points of variation

    // Create a grain effect by adding random noise to each RGB channel
    // This simulates film grain or texture overlay
    return Color.fromARGB(
      color.alpha,
      (color.red + (random.nextDouble() * 2 - 1) * grainIntensity)
          .round()
          .clamp(0, 255),
      (color.green + (random.nextDouble() * 2 - 1) * grainIntensity)
          .round()
          .clamp(0, 255),
      (color.blue + (random.nextDouble() * 2 - 1) * grainIntensity)
          .round()
          .clamp(0, 255),
    );
  }

  /// Check if a color meets accessibility standards for contrast
  bool isAccessible(Color backgroundColor, Color textColor) {
    // Calculate relative luminance
    double getLuminance(Color color) {
      final double r = color.red / 255;
      final double g = color.green / 255;
      final double b = color.blue / 255;

      final double r1 =
          r <= 0.03928 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4).toDouble();
      final double g1 =
          g <= 0.03928 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4).toDouble();
      final double b1 =
          b <= 0.03928 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4).toDouble();

      return 0.2126 * r1 + 0.7152 * g1 + 0.0722 * b1;
    }

    // Calculate contrast ratio
    final double bgLuminance = getLuminance(backgroundColor);
    final double textLuminance = getLuminance(textColor);

    final double contrastRatio =
        (max(bgLuminance, textLuminance) + 0.05) /
        (min(bgLuminance, textLuminance) + 0.05);

    // WCAG 2.0 level AA requires a contrast ratio of at least 4.5:1 for normal text
    // and 3:1 for large text
    return contrastRatio >= 4.5;
  }

  /// Suggest an accessible text color for a given background color
  Color suggestAccessibleTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();

    // Start with black or white based on background luminance
    Color textColor = luminance > 0.5 ? Colors.black : Colors.white;

    // If the contrast is not sufficient, adjust the text color
    if (!isAccessible(backgroundColor, textColor)) {
      // Try to adjust the text color to improve contrast
      if (textColor == Colors.black) {
        // Make it darker
        textColor = const Color(0xFF000000);
      } else {
        // Make it lighter
        textColor = const Color(0xFFFFFFFF);
      }
    }

    return textColor;
  }

  /// Generate a color that adapts to the current theme brightness
  Color adaptiveColor(Color lightColor, Color darkColor, BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    return brightness == Brightness.dark ? darkColor : lightColor;
  }
}
