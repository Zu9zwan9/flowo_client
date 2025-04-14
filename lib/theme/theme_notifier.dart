import 'package:flowo_client/models/app_theme.dart'; // Import the shared AppTheme
import 'package:flowo_client/models/user_settings.dart'; // Import UserSettings
import 'package:flowo_client/services/web_theme_bridge.dart';
import 'package:flowo_client/theme/app_colors.dart';
import 'package:flowo_client/theme/dynamic_color_service.dart';
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

  // Dynamic color properties
  bool _useDynamicColors = false;
  Map<String, Color>? _dynamicColorPalette;

  // Service for dynamic colors
  final DynamicColorService _dynamicColorService = DynamicColorService();

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
      _useDynamicColors = userSettings.useDynamicColors;
      _secondaryColor =
          userSettings.secondaryColorValue != null
              ? Color(userSettings.secondaryColorValue!)
              : const Color(0xFF34C759);

      // Generate dynamic color palette if dynamic colors are enabled
      if (_useDynamicColors) {
        _dynamicColorPalette = _dynamicColorService.generatePalette(
          _customColor,
        );
      }
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

  // Dynamic color getters
  bool get useDynamicColors => _useDynamicColors;
  Map<String, Color>? get dynamicColorPalette => _dynamicColorPalette;

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
      if (_useDynamicColors && _dynamicColorPalette != null) {
        // Use dynamic color palette if enabled
        primaryColor = _dynamicColorPalette!['primary']!;
      } else {
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
      }

      // Apply noise effect if enabled
      if (_noiseLevel > 0) {
        primaryColor = applyNoiseToColor(primaryColor);
      }
    } else {
      // Default theme colors using AppColors
      primaryColor = isADHD ? AppColors.accent : AppColors.primary;
    }

    // Text color: dynamically determine based on background darkness for custom theme
    Color textColor;

    // Background color: Use AppColors for consistent system colors
    Color backgroundColor;

    if (isCustom) {
      // For custom theme, use the custom color as the base for background
      Color baseColor;

      if (_useDynamicColors && _dynamicColorPalette != null) {
        // Use dynamic color palette for background if enabled
        baseColor =
            isDark
                ? _dynamicColorPalette!['dark']!
                : _dynamicColorPalette!['light']!;
      } else {
        // Lighten or darken the custom color based on the brightness mode
        final backgroundHsl = HSLColor.fromColor(_customColor);
        baseColor =
            isDark
                ? backgroundHsl
                    .withLightness(0.1)
                    .toColor() // Dark background
                : backgroundHsl
                    .withLightness(0.95)
                    .toColor(); // Light background
      }

      // Apply noise effect if enabled
      if (_noiseLevel > 0) {
        backgroundColor = _dynamicColorService.applyNoiseEffect(
          baseColor,
          _noiseLevel,
        );
      } else {
        backgroundColor = baseColor;
      }

      // Dynamically determine text color based on background darkness
      textColor = _dynamicColorService.suggestAccessibleTextColor(
        backgroundColor,
      );
    } else {
      // For non-custom themes, use standard text colors from AppColors
      textColor =
          isADHD
              ? AppColors.label
              : isDark
              ? CupertinoColors.white
              : CupertinoColors.black;

      // Standard background colors from AppColors
      backgroundColor = isDark ? AppColors.background : AppColors.background;
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

  /// Enable or disable dynamic colors
  void setUseDynamicColors(bool useDynamicColors) {
    _useDynamicColors = useDynamicColors;

    if (_useDynamicColors && _dynamicColorPalette == null) {
      // Generate a dynamic color palette if none exists
      generateDynamicColorPalette();
    }

    if (_currentThemeMode == AppTheme.custom) {
      // Re-apply theme if already in custom mode
      _applyTheme(brightness, isADHD: false, isCustom: true);

      // Save settings to UserSettings if available
      _saveThemeSettings();

      notifyListeners();
    }
  }

  /// Generate a dynamic color palette from the custom color
  void generateDynamicColorPalette() {
    _dynamicColorPalette = _dynamicColorService.generatePalette(_customColor);

    if (_currentThemeMode == AppTheme.custom && _useDynamicColors) {
      // Re-apply theme if using dynamic colors in custom mode
      _applyTheme(brightness, isADHD: false, isCustom: true);

      notifyListeners();
    }
  }

  /// Get a color from the dynamic color palette
  /// Returns the custom color if the palette is not available or the key is not found
  Color getDynamicColor(String key) {
    if (_dynamicColorPalette == null ||
        !_dynamicColorPalette!.containsKey(key)) {
      return _customColor;
    }
    return _dynamicColorPalette![key]!;
  }

  /// Apply noise effect to a color
  Color applyNoiseToColor(Color color) {
    if (_noiseLevel <= 0.0) return color;
    return _dynamicColorService.applyNoiseEffect(color, _noiseLevel);
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
      _userSettings!.useDynamicColors = _useDynamicColors;
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
