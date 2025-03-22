import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

enum AppTheme { system, light, dark, adhd }

/// Vibrant color palette for the app
class VibrantColors {
  // Primary colors
  static const Color coral = Color(0xFFFF6B6B);
  static const Color turquoise = Color(0xFF4ECDC4);
  static const Color purple = Color(0xFF6A0DAD);
  static const Color amber = Color(0xFFFFBE0B);
  static const Color teal = Color(0xFF38A3A5);

  // Pastel colors
  static const Color pastelPink = Color(0xFFFFC8DD);
  static const Color pastelBlue = Color(0xFFBDE0FE);
  static const Color pastelGreen = Color(0xFFD8F3DC);
  static const Color pastelYellow = Color(0xFFFDFDB7);
  static const Color pastelPurple = Color(0xFFCDB4DB);

  // Neon colors
  static const Color neonPink = Color(0xFFFF00FF);
  static const Color neonBlue = Color(0xFF00FFFF);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color neonYellow = Color(0xFFFFFF00);
  static const Color neonPurple = Color(0xFFBF00FF);

  // Gradient pairs
  static List<Color> sunsetGradient = [coral, amber];
  static List<Color> oceanGradient = [turquoise, pastelBlue];
  static List<Color> purpleHazeGradient = [purple, pastelPurple];
  static List<Color> tropicalGradient = [teal, pastelGreen];
  static List<Color> neonDreamGradient = [neonPink, neonBlue];

  // Get a random vibrant color
  static Color random() {
    final List<Color> allColors = [
      coral,
      turquoise,
      purple,
      amber,
      teal,
      pastelPink,
      pastelBlue,
      pastelGreen,
      pastelYellow,
      pastelPurple,
      neonPink,
      neonBlue,
      neonGreen,
      neonYellow,
      neonPurple,
    ];
    return allColors[math.Random().nextInt(allColors.length)];
  }

  // Get a random gradient
  static List<Color> randomGradient() {
    final List<List<Color>> allGradients = [
      sunsetGradient,
      oceanGradient,
      purpleHazeGradient,
      tropicalGradient,
      neonDreamGradient,
    ];
    return allGradients[math.Random().nextInt(allGradients.length)];
  }
}

/// Glassmorphic theme configuration for consistent styling across the app
class GlassmorphicTheme {
  /// The default blur intensity for glassmorphic effects
  final double defaultBlur;

  /// The default opacity for glassmorphic backgrounds
  final double defaultOpacity;

  /// The default border width for glassmorphic containers
  final double defaultBorderWidth;

  /// The default border radius for glassmorphic containers
  final BorderRadius defaultBorderRadius;

  /// The border color for glassmorphic containers
  final Color borderColor;

  /// The background color for glassmorphic containers
  final Color backgroundColor;

  /// The accent color for highlights and special elements
  final Color accentColor;

  /// Secondary accent color for additional highlights
  final Color secondaryAccentColor;

  /// Gradient colors for backgrounds and special effects
  final List<Color> gradientColors;

  /// The shadow color for glassmorphic containers
  final Color shadowColor;

  /// The shadow opacity for glassmorphic containers
  final double shadowOpacity;

  /// The shadow blur radius for glassmorphic containers
  final double shadowBlurRadius;

  /// The shadow spread radius for glassmorphic containers
  final double shadowSpreadRadius;

  /// Whether to use animated particles in the background
  final bool useAnimatedParticles;

  const GlassmorphicTheme({
    required this.defaultBlur,
    required this.defaultOpacity,
    required this.defaultBorderWidth,
    required this.defaultBorderRadius,
    required this.borderColor,
    required this.backgroundColor,
    required this.accentColor,
    required this.secondaryAccentColor,
    required this.gradientColors,
    required this.shadowColor,
    required this.shadowOpacity,
    required this.shadowBlurRadius,
    required this.shadowSpreadRadius,
    this.useAnimatedParticles = true,
  });

  /// Creates a light theme variant of GlassmorphicTheme with vibrant accents
  factory GlassmorphicTheme.light() {
    return GlassmorphicTheme(
      defaultBlur: 15.0,
      defaultOpacity: 0.25,
      defaultBorderWidth: 1.5,
      defaultBorderRadius: BorderRadius.circular(16.0),
      borderColor: VibrantColors.pastelBlue.withOpacity(0.6),
      backgroundColor: CupertinoColors.white.withOpacity(0.3),
      accentColor: VibrantColors.turquoise,
      secondaryAccentColor: VibrantColors.coral,
      gradientColors: VibrantColors.oceanGradient,
      shadowColor: CupertinoColors.white,
      shadowOpacity: 0.1,
      shadowBlurRadius: 15.0,
      shadowSpreadRadius: 1.5,
    );
  }

  /// Creates a dark theme variant of GlassmorphicTheme with vibrant accents
  factory GlassmorphicTheme.dark() {
    return GlassmorphicTheme(
      defaultBlur: 15.0,
      defaultOpacity: 0.25,
      defaultBorderWidth: 1.5,
      defaultBorderRadius: BorderRadius.circular(16.0),
      borderColor: VibrantColors.neonBlue.withOpacity(0.4),
      backgroundColor: CupertinoColors.black.withOpacity(0.3),
      accentColor: VibrantColors.neonBlue,
      secondaryAccentColor: VibrantColors.neonPink,
      gradientColors: VibrantColors.neonDreamGradient,
      shadowColor: CupertinoColors.black,
      shadowOpacity: 0.15,
      shadowBlurRadius: 15.0,
      shadowSpreadRadius: 1.5,
    );
  }

  /// Creates a copy of this GlassmorphicTheme with the given fields replaced with new values
  GlassmorphicTheme copyWith({
    double? defaultBlur,
    double? defaultOpacity,
    double? defaultBorderWidth,
    BorderRadius? defaultBorderRadius,
    Color? borderColor,
    Color? backgroundColor,
    Color? accentColor,
    Color? secondaryAccentColor,
    List<Color>? gradientColors,
    Color? shadowColor,
    double? shadowOpacity,
    double? shadowBlurRadius,
    double? shadowSpreadRadius,
    bool? useAnimatedParticles,
  }) {
    return GlassmorphicTheme(
      defaultBlur: defaultBlur ?? this.defaultBlur,
      defaultOpacity: defaultOpacity ?? this.defaultOpacity,
      defaultBorderWidth: defaultBorderWidth ?? this.defaultBorderWidth,
      defaultBorderRadius: defaultBorderRadius ?? this.defaultBorderRadius,
      borderColor: borderColor ?? this.borderColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      accentColor: accentColor ?? this.accentColor,
      secondaryAccentColor: secondaryAccentColor ?? this.secondaryAccentColor,
      gradientColors: gradientColors ?? this.gradientColors,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shadowSpreadRadius: shadowSpreadRadius ?? this.shadowSpreadRadius,
      useAnimatedParticles: useAnimatedParticles ?? this.useAnimatedParticles,
    );
  }
}

class ThemeNotifier extends ChangeNotifier {
  // Use CupertinoThemeData for Cupertino styling
  late CupertinoThemeData _cupertinoTheme;
  // Keep Material ThemeData for backward compatibility
  late ThemeData _currentTheme;
  AppTheme _currentThemeMode = AppTheme.system;
  String _currentFont = 'SF Pro Display';

  // Glassmorphic theme
  late GlassmorphicTheme _glassmorphicTheme;

  // Save reference to override brightness for system theme mode
  Brightness? _brightnessOverride;

  ThemeNotifier() {
    // Initialize with system theme by default
    setThemeMode(AppTheme.system);
  }

  CupertinoThemeData get currentTheme => _cupertinoTheme;
  ThemeData get materialTheme => _currentTheme; // For Material components
  AppTheme get themeMode => _currentThemeMode;
  String get currentFont => _currentFont;
  GlassmorphicTheme get glassmorphicTheme => _glassmorphicTheme;

  // Theme color getters - all adaptive based on brightness
  Color get primaryColor => _cupertinoTheme.primaryColor;
  Color get textColor =>
      _cupertinoTheme.textTheme.textStyle.color ??
      (_isDarkMode ? CupertinoColors.white : CupertinoColors.black);
  Color get backgroundColor => _cupertinoTheme.scaffoldBackgroundColor;
  Color get iconColor => primaryColor;
  Color get menuBackgroundColor => backgroundColor;

  // Helper to determine if we're using dark mode
  bool get _isDarkMode => _cupertinoTheme.brightness == Brightness.dark;

  // Get current brightness considering system and overrides
  Brightness get brightness {
    if (_currentThemeMode == AppTheme.system && _brightnessOverride == null) {
      // Get the platform brightness if in system mode with no override
      return WidgetsBinding.instance.window.platformBrightness;
    } else if (_brightnessOverride != null) {
      // Use the override if present
      return _brightnessOverride!;
    } else {
      // Otherwise use theme-specific brightness
      return _currentThemeMode == AppTheme.dark
          ? Brightness.dark
          : Brightness.light;
    }
  }

  /// Set theme mode and apply appropriate theme
  void setThemeMode(AppTheme themeMode) {
    _currentThemeMode = themeMode;
    _brightnessOverride = null;

    switch (themeMode) {
      case AppTheme.light:
        _applyTheme(Brightness.light, isADHD: false);
        break;
      case AppTheme.dark:
        _applyTheme(Brightness.dark, isADHD: false);
        break;
      case AppTheme.adhd:
        _applyTheme(Brightness.light, isADHD: true);
        break;
      case AppTheme.system:
        // Use platform brightness
        final platformBrightness =
            WidgetsBinding.instance.window.platformBrightness;
        _applyTheme(platformBrightness, isADHD: false);

        // Listen for platform brightness changes
        WidgetsBinding.instance.window.onPlatformBrightnessChanged = () {
          if (_currentThemeMode == AppTheme.system) {
            _applyTheme(
              WidgetsBinding.instance.window.platformBrightness,
              isADHD: false,
            );
          }
        };
        break;
    }

    notifyListeners();
  }

  /// Toggle between light and dark mode
  void toggleDarkMode() {
    if (_currentThemeMode == AppTheme.system) {
      // If we're in system mode, just override the brightness
      _brightnessOverride = _isDarkMode ? Brightness.light : Brightness.dark;
      _applyTheme(_brightnessOverride!, isADHD: false);
    } else {
      // Otherwise toggle between light and dark modes
      setThemeMode(_isDarkMode ? AppTheme.light : AppTheme.dark);
    }
  }

  /// Core method to apply a theme with the given brightness
  void _applyTheme(Brightness brightness, {required bool isADHD}) {
    final isDark = brightness == Brightness.dark;

    // Configure colors based on theme type with Apple-style colors
    // Deep blue (#0A84FF) for primary color
    final primaryColor =
        isADHD ? CupertinoColors.systemOrange : const Color(0xFF0A84FF);

    // Text color: black for light mode, white for dark mode
    final textColor =
        isADHD
            ? CupertinoColors.black
            : isDark
            ? CupertinoColors.white
            : CupertinoColors.black;

    // Background color: Apple-style white (#F2F2F7) for light mode, dark mode black (#1C1C1E) for dark mode
    final backgroundColor =
        isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);

    // Configure text style with appropriate weight for ADHD mode
    final textStyle = TextStyle(
      fontFamily: _currentFont,
      color: textColor,
      fontSize: 16,
      fontWeight: isADHD ? FontWeight.w500 : FontWeight.normal,
    );

    // Configure Cupertino theme
    _cupertinoTheme = CupertinoThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      barBackgroundColor:
          isDark
              ? CupertinoColors.systemGrey6.darkColor
              : CupertinoColors.systemGrey6.color,
      textTheme: CupertinoTextThemeData(
        textStyle: textStyle,
        navTitleTextStyle: TextStyle(
          fontFamily: _currentFont,
          fontWeight: FontWeight.w600,
          color: textColor,
          fontSize: 17,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontFamily: _currentFont,
          fontWeight: FontWeight.bold,
          color: textColor,
          fontSize: 34,
          letterSpacing: -0.5,
        ),
      ),
    );

    // Configure Material theme for backward compatibility
    _currentTheme = (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: (isDark
              ? Typography.material2018().white
              : Typography.material2018().black)
          .apply(fontFamily: _currentFont, decoration: TextDecoration.none),
    );

    // Configure Glassmorphic theme
    _glassmorphicTheme =
        isDark ? GlassmorphicTheme.dark() : GlassmorphicTheme.light();

    // Customize glassmorphic theme for ADHD mode if needed
    if (isADHD) {
      _glassmorphicTheme = _glassmorphicTheme.copyWith(
        defaultBlur: 8.0, // Less blur for better readability
        defaultOpacity: 0.25, // Slightly more opaque
        defaultBorderWidth: 2.0, // Thicker borders for better visibility
        borderColor: primaryColor.withOpacity(
          0.4,
        ), // Use primary color for borders
        backgroundColor: backgroundColor.withOpacity(
          0.25,
        ), // More opaque background
      );
    }

    // Ensure glassmorphic theme uses the primary color for accents
    _glassmorphicTheme = _glassmorphicTheme.copyWith(
      borderColor: _glassmorphicTheme.borderColor.withOpacity(
        isDark ? 0.3 : 0.5,
      ),
      backgroundColor: (isDark ? CupertinoColors.black : CupertinoColors.white)
          .withOpacity(0.2),
      shadowColor: primaryColor,
    );
  }

  void setFont(String font) {
    _currentFont = font;

    // Re-apply current theme with the new font
    _applyTheme(
      _cupertinoTheme.brightness ?? Brightness.light, // Provide default if null
      isADHD: _currentThemeMode == AppTheme.adhd,
    );

    notifyListeners();
  }
}
