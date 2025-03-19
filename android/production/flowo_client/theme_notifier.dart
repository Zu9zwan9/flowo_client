import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum AppTheme { system, light, dark, adhd }

class ThemeNotifier extends ChangeNotifier {
  // Use CupertinoThemeData for Cupertino styling
  late CupertinoThemeData _cupertinoTheme;
  // Keep Material ThemeData for backward compatibility
  late ThemeData _currentTheme;
  AppTheme _currentThemeMode = AppTheme.system;
  String _currentFont = 'SF Pro';

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

    // Configure colors based on theme type
    final primaryColor =
        isADHD ? CupertinoColors.systemOrange : CupertinoColors.systemBlue;

    final textColor =
        isADHD
            ? CupertinoColors.black
            : isDark
            ? CupertinoColors.white
            : CupertinoColors.black;

    final backgroundColor =
        isDark ? CupertinoColors.black : CupertinoColors.systemBackground;

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
      _cupertinoTheme.brightness ?? Brightness.light, // Provide default if null
      isADHD: _currentThemeMode == AppTheme.adhd,
    );

    notifyListeners();
  }
}
