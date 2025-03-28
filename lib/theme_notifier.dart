import 'package:flowo_client/models/app_theme.dart'; // Import the shared AppTheme
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  // Use CupertinoThemeData for Cupertino styling
  late CupertinoThemeData _cupertinoTheme;
  // Keep Material ThemeData for backward compatibility
  late ThemeData _currentTheme;
  AppTheme _currentThemeMode = AppTheme.system;
  String _currentFont = 'SF Pro Display';

  // Custom theme properties
  Color _customColor = const Color(0xFF0A84FF); // Default to iOS blue
  double _colorIntensity = 1.0; // 0.0 to 1.0
  double _noiseLevel = 0.0; // 0.0 to 1.0

  // Save reference to override brightness for system or custom theme modes
  Brightness? _brightnessOverride;

  ThemeNotifier() {
    // Initialize with system theme by default
    setThemeMode(AppTheme.system);
  }

  CupertinoThemeData get currentTheme => _cupertinoTheme;
  ThemeData get materialTheme => _currentTheme; // For Material components
  AppTheme get themeMode => _currentThemeMode;
  String get currentFont => _currentFont;

  // Custom theme getters
  Color get customColor => _customColor;
  double get colorIntensity => _colorIntensity;
  double get noiseLevel => _noiseLevel;

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

  // Get current brightness considering system, overrides, and theme mode
  Brightness get brightness {
    if (_brightnessOverride != null) {
      // Use the override if present
      return _brightnessOverride!;
    } else if (_currentThemeMode == AppTheme.system) {
      // Get the platform brightness if in system mode with no override
      return WidgetsBinding.instance.platformDispatcher.platformBrightness;
    } else {
      // Otherwise use theme-specific brightness
      return _currentThemeMode == AppTheme.dark
          ? Brightness.dark
          : Brightness.light;
    }
  }

  /// Set the global brightness explicitly
  void setBrightness(Brightness brightness) {
    _brightnessOverride = brightness;

    // Apply the theme with the new brightness
    if (_currentThemeMode == AppTheme.system ||
        _currentThemeMode == AppTheme.custom) {
      _applyTheme(
        brightness,
        isADHD: _currentThemeMode == AppTheme.adhd,
        isCustom: _currentThemeMode == AppTheme.custom,
      );
    } else {
      // If we're in light, dark, or ADHD mode, switch to the corresponding theme
      setThemeMode(
        brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
      );
    }

    notifyListeners();
  }

  /// Set theme mode and apply appropriate theme
  void setThemeMode(AppTheme themeMode) {
    // Store the current brightness override to preserve it across theme changes
    final currentBrightness = _brightnessOverride ?? brightness;

    _currentThemeMode = themeMode;

    // Clear the platform brightness listener if we're not in system mode
    if (themeMode != AppTheme.system) {
      WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
          null;
    }

    switch (themeMode) {
      case AppTheme.light:
        _brightnessOverride = null; // Clear override for fixed themes
        _applyTheme(Brightness.light, isADHD: false, isCustom: false);
        break;
      case AppTheme.dark:
        _brightnessOverride = null; // Clear override for fixed themes
        _applyTheme(Brightness.dark, isADHD: false, isCustom: false);
        break;
      case AppTheme.adhd:
        _brightnessOverride = null; // Clear override for fixed themes
        _applyTheme(Brightness.light, isADHD: true, isCustom: false);
        break;
      case AppTheme.custom:
        // Use the current brightness override if available, otherwise fall back to platform brightness
        final brightnessToUse = currentBrightness;
        _applyTheme(brightnessToUse, isADHD: false, isCustom: true);
        break;
      case AppTheme.system:
        // Use the current brightness override if available, otherwise use platform brightness
        final brightnessToUse = currentBrightness;
        _applyTheme(brightnessToUse, isADHD: false, isCustom: false);

        // Listen for platform brightness changes
        WidgetsBinding
            .instance
            .platformDispatcher
            .onPlatformBrightnessChanged = () {
          if (_currentThemeMode == AppTheme.system &&
              _brightnessOverride == null) {
            _applyTheme(
              WidgetsBinding.instance.platformDispatcher.platformBrightness,
              isADHD: false,
              isCustom: false,
            );
            notifyListeners();
          }
        };
        break;
    }

    notifyListeners();
  }

  /// Toggle between light and dark mode
  void toggleDarkMode() {
    setBrightness(_isDarkMode ? Brightness.light : Brightness.dark);
  }

  /// Core method to apply a theme with the given brightness
  void _applyTheme(
    Brightness brightness, {
    required bool isADHD,
    bool isCustom = false,
  }) {
    final isDark = brightness == Brightness.dark;

    // Configure colors based on theme type with Apple-style colors
    Color primaryColor;

    if (isCustom) {
      // Apply intensity to custom color
      final hslColor = HSLColor.fromColor(_customColor);
      final adjustedColor =
          hslColor
              .withSaturation(
                (hslColor.saturation * _colorIntensity).clamp(0.0, 1.0),
              )
              .withLightness(
                isDark
                    ? (hslColor.lightness * 1.2).clamp(0.0, 1.0)
                    : (hslColor.lightness * _colorIntensity).clamp(0.0, 1.0),
              )
              .toColor();
      primaryColor = adjustedColor;
    } else {
      // Default theme colors
      primaryColor =
          isADHD ? CupertinoColors.systemOrange : const Color(0xFF0A84FF);
    }

    // Text color: black for light mode, white for dark mode
    final textColor =
        isADHD
            ? CupertinoColors.black
            : isDark
            ? CupertinoColors.white
            : CupertinoColors.black;

    // Background color: Apple-style white (#F2F2F7) for light mode, dark mode black (#1C1C1E) for dark mode
    Color backgroundColor;

    if (isCustom && _noiseLevel > 0) {
      // Apply subtle noise effect to background by slightly adjusting the color
      final baseColor =
          isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
      final noiseAmount = (_noiseLevel * 8).toInt(); // Convert to 0-8 range

      // Create a subtle variation of the base color
      backgroundColor = Color.fromARGB(
        baseColor.alpha,
        (baseColor.red + (noiseAmount - 4)).clamp(0, 255),
        (baseColor.green + (noiseAmount - 2)).clamp(0, 255),
        (baseColor.blue + noiseAmount).clamp(0, 255),
      );
    } else {
      backgroundColor =
          isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    }

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
  }

  void setFont(String font) {
    _currentFont = font;

    // Re-apply current theme with the new font
    _applyTheme(
      brightness,
      isADHD: _currentThemeMode == AppTheme.adhd,
      isCustom: _currentThemeMode == AppTheme.custom,
    );

    notifyListeners();
  }

  /// Set custom color for the theme
  void setCustomColor(Color color) {
    _customColor = color;

    if (_currentThemeMode == AppTheme.custom) {
      // Re-apply theme if already in custom mode
      _applyTheme(brightness, isADHD: false, isCustom: true);
      notifyListeners();
    }
  }

  /// Set color intensity (0.0 to 1.0)
  void setColorIntensity(double intensity) {
    _colorIntensity = intensity.clamp(0.0, 1.0);

    if (_currentThemeMode == AppTheme.custom) {
      // Re-apply theme if already in custom mode
      _applyTheme(brightness, isADHD: false, isCustom: true);
      notifyListeners();
    }
  }

  /// Set noise level (0.0 to 1.0)
  void setNoiseLevel(double noise) {
    _noiseLevel = noise.clamp(0.0, 1.0);

    if (_currentThemeMode == AppTheme.custom) {
      // Re-apply theme if already in custom mode
      _applyTheme(brightness, isADHD: false, isCustom: true);
      notifyListeners();
    }
  }

  /// Apply custom theme with current settings
  void applyCustomTheme(Brightness brightness) {
    _currentThemeMode = AppTheme.custom;
    _brightnessOverride = brightness;

    _applyTheme(brightness, isADHD: false, isCustom: true);

    notifyListeners();
  }
}
