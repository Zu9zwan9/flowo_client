import 'package:flowo_client/models/app_theme.dart'; // Import the shared AppTheme
import 'package:flowo_client/models/user_settings.dart'; // Import UserSettings
import 'package:flowo_client/services/web_theme_bridge.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

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
  bool _useGradient = false; // Whether to use gradient
  Color _secondaryColor = const Color(0xFF34C759); // Default to iOS green

  // Reference to user settings
  UserSettings? _userSettings;

  // Save reference to override brightness for system or custom theme modes
  Brightness? _brightnessOverride;

  // Web theme bridge for system theme detection on web
  final WebThemeBridge? webThemeBridge;

  ThemeNotifier({this.webThemeBridge, UserSettings? userSettings}) {
    // Store reference to user settings
    _userSettings = userSettings;

    // Initialize with settings from UserSettings if available
    if (userSettings != null) {
      _currentThemeMode = userSettings.themeMode;
      _customColor = Color(userSettings.customColorValue);
      _colorIntensity = userSettings.colorIntensity;
      _noiseLevel = userSettings.noiseLevel;
      _useGradient = userSettings.useGradient ?? false;
      _secondaryColor =
          userSettings.secondaryColorValue != null
              ? Color(userSettings.secondaryColorValue!)
              : const Color(0xFF34C759);
    } else {
      // Initialize with system theme by default
      _currentThemeMode = AppTheme.system;
    }

    // Apply the theme
    setThemeMode(_currentThemeMode);

    // Listen for system theme changes on web
    if (kIsWeb && webThemeBridge != null) {
      webThemeBridge!.listenForThemeChanges((brightness) {
        if (_currentThemeMode == AppTheme.system &&
            _brightnessOverride == null) {
          _applyTheme(brightness, isADHD: false, isCustom: false);
          notifyListeners();
        }
      });
    }
  }

  CupertinoThemeData get currentTheme => _cupertinoTheme;
  ThemeData get materialTheme => _currentTheme; // For Material components
  AppTheme get themeMode => _currentThemeMode;
  String get currentFont => _currentFont;

  // Custom theme getters
  Color get customColor => _customColor;
  double get colorIntensity => _colorIntensity;
  double get noiseLevel => _noiseLevel;
  bool get useGradient => _useGradient;
  Color get secondaryColor => _secondaryColor;

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

    // Save settings to UserSettings if available
    _saveThemeSettings();

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

        // For web, we already set up the listener in the constructor
        // For non-web platforms, use the standard platform brightness listener
        if (!kIsWeb || webThemeBridge == null) {
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
        }
        break;
    }

    // Save settings to UserSettings if available
    _saveThemeSettings();

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

    // Text color: dynamically determine based on background darkness for custom theme
    Color textColor;

    // Background color: Apple-style white (#F2F2F7) for light mode, dark mode black (#1C1C1E) for dark mode
    Color backgroundColor;

    if (isCustom) {
      // For custom theme, use the custom color as the base for background
      // Lighten or darken it based on the brightness mode
      final backgroundHsl = HSLColor.fromColor(_customColor);
      final baseBackgroundColor =
          isDark
              ? backgroundHsl
                  .withLightness(0.1)
                  .toColor() // Dark background
              : backgroundHsl.withLightness(0.95).toColor(); // Light background

      if (_noiseLevel > 0) {
        // Enhanced noise effect - create a more visible texture
        final random = DateTime.now().millisecondsSinceEpoch;
        final noiseIntensity = _noiseLevel * 0.05; // 0-5% variation

        // Create a subtle noise pattern by varying RGB values
        backgroundColor = Color.fromARGB(
          baseBackgroundColor.a.round(),
          (baseBackgroundColor.r *
                  (1 + (random % 10 - 5) * noiseIntensity / 100))
              .round()
              .clamp(0, 255),
          (baseBackgroundColor.g *
                  (1 + (random % 10 - 5) * noiseIntensity / 100))
              .round()
              .clamp(0, 255),
          (baseBackgroundColor.b *
                  (1 + (random % 10 - 5) * noiseIntensity / 100))
              .round()
              .clamp(0, 255),
        );
      } else {
        backgroundColor = baseBackgroundColor;
      }

      // Dynamically determine text color based on background darkness
      textColor =
          isColorDark(backgroundColor)
              ? CupertinoColors.white
              : CupertinoColors.black;
    } else {
      // For non-custom themes, use standard text colors
      textColor =
          isADHD
              ? CupertinoColors.black
              : isDark
              ? CupertinoColors.white
              : CupertinoColors.black;

      // Standard background colors
      backgroundColor =
          isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    }

    // Configure text style with appropriate weight for ADHD mode
    final textStyle = TextStyle(
      inherit: false,
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
          inherit: false,
          fontFamily: _currentFont,
          fontWeight: FontWeight.w600,
          color: textColor,
          fontSize: 17,
        ),
        navLargeTitleTextStyle: TextStyle(
          inherit: false,
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

      // Save settings to UserSettings if available
      _saveThemeSettings();

      notifyListeners();
    }
  }

  /// Set color intensity (0.0 to 1.0)
  void setColorIntensity(double intensity) {
    _colorIntensity = intensity.clamp(0.0, 1.0);

    if (_currentThemeMode == AppTheme.custom) {
      // Re-apply theme if already in custom mode
      _applyTheme(brightness, isADHD: false, isCustom: true);

      // Save settings to UserSettings if available
      _saveThemeSettings();

      notifyListeners();
    }
  }

  /// Set noise level (0.0 to 1.0)
  void setNoiseLevel(double noise) {
    _noiseLevel = noise.clamp(0.0, 1.0);

    if (_currentThemeMode == AppTheme.custom) {
      // Re-apply theme if already in custom mode
      _applyTheme(brightness, isADHD: false, isCustom: true);

      // Save settings to UserSettings if available
      _saveThemeSettings();

      notifyListeners();
    }
  }

  /// Set whether to use gradient
  void setUseGradient(bool useGradient) {
    _useGradient = useGradient;

    if (_currentThemeMode == AppTheme.custom) {
      // Re-apply theme if already in custom mode
      _applyTheme(brightness, isADHD: false, isCustom: true);

      // Save settings to UserSettings if available
      _saveThemeSettings();

      notifyListeners();
    }
  }

  /// Set secondary color for gradient
  void setSecondaryColor(Color color) {
    _secondaryColor = color;

    if (_currentThemeMode == AppTheme.custom) {
      // Re-apply theme if already in custom mode
      _applyTheme(brightness, isADHD: false, isCustom: true);

      // Save settings to UserSettings if available
      _saveThemeSettings();

      notifyListeners();
    }
  }

  /// Apply custom theme with current settings
  void applyCustomTheme(Brightness brightness) {
    _currentThemeMode = AppTheme.custom;
    _brightnessOverride = brightness;

    _applyTheme(brightness, isADHD: false, isCustom: true);

    // Save settings to UserSettings if available
    _saveThemeSettings();

    notifyListeners();
  }

  /// Determine if a color is dark (to choose appropriate text color)
  bool isColorDark(Color color) {
    // Calculate the perceived brightness using the formula
    // (0.299*R + 0.587*G + 0.114*B)
    final double brightness =
        (0.299 * color.r + 0.587 * color.g + 0.114 * color.b) / 255;

    // If the brightness is less than 0.5, the color is considered dark
    return brightness < 0.5;
  }

  /// Save current theme settings to UserSettings
  void _saveThemeSettings() {
    if (_userSettings != null) {
      _userSettings!.themeMode = _currentThemeMode;
      _userSettings!.customColorValue = _customColor.toARGB32();
      _userSettings!.colorIntensity = _colorIntensity;
      _userSettings!.noiseLevel = _noiseLevel;
      _userSettings!.useGradient = _useGradient;
      _userSettings!.secondaryColorValue = _secondaryColor.toARGB32();

      try {
        // Try to save the updated UserSettings
        _userSettings!.save();
      } catch (e) {
        // If the object is not in a box, we need to update it in the box
        if (e.toString().contains('not in a box')) {
          // Get the Hive box for UserSettings
          final box = Hive.box<UserSettings>('user_settings');
          // Update the UserSettings in the box
          box.put('current', _userSettings!);
        } else {
          // Rethrow other errors
          rethrow;
        }
      }
    }
  }
}
