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
  Map<String, Color> getSystemColors(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Base system colors from Cupertino
    final baseColors = {
      'blue': CupertinoColors.systemBlue,
      'green': CupertinoColors.systemGreen,
      'indigo': CupertinoColors.systemIndigo,
      'orange': CupertinoColors.systemOrange,
      'pink': CupertinoColors.systemPink,
      'purple': CupertinoColors.systemPurple,
      'red': CupertinoColors.systemRed,
      'teal': CupertinoColors.systemTeal,
      'yellow': CupertinoColors.systemYellow,
      'gray': CupertinoColors.systemGrey,
    };

    // Resolve colors based on brightness
    final resolvedColors = <String, Color>{};
    baseColors.forEach((key, value) {
      if (value is CupertinoDynamicColor) {
        resolvedColors[key] = isDark ? value.darkColor : value.color;
      } else {
        resolvedColors[key] = value;
      }
    });

    return resolvedColors;
  }

  /// Apply a noise effect to a color
  /// The noise level determines the intensity of the effect (0.0 to 1.0)
  Color applyNoiseEffect(Color color, double noiseLevel) {
    if (noiseLevel <= 0.0) return color;

    final random = Random();
    final noiseIntensity = noiseLevel * 0.1; // 0-10% variation

    // Create a subtle noise pattern by varying RGB values
    return Color.fromARGB(
      color.alpha,
      (color.red * (1 + (random.nextDouble() * 2 - 1) * noiseIntensity))
          .round()
          .clamp(0, 255),
      (color.green * (1 + (random.nextDouble() * 2 - 1) * noiseIntensity))
          .round()
          .clamp(0, 255),
      (color.blue * (1 + (random.nextDouble() * 2 - 1) * noiseIntensity))
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
