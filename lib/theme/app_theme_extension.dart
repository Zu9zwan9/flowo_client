import 'package:flutter/cupertino.dart';

import 'app_colors.dart';

/// Extension on BuildContext to easily access theme colors
extension AppThemeExtension on BuildContext {
  /// Get the CupertinoThemeData
  CupertinoThemeData get theme => CupertinoTheme.of(this);

  /// Get the brightness (light or dark)
  Brightness? get brightness => theme.brightness;

  /// Check if the current theme is dark
  bool get isDarkMode => brightness == Brightness.dark;

  /// Get the primary color from the theme
  Color get primaryColor => theme.primaryColor;

  /// Get the appropriate text color based on the current theme
  Color get textColor =>
      theme.textTheme.textStyle.color ??
      (isDarkMode ? CupertinoColors.white : CupertinoColors.black);

  /// Get the background color from the theme
  Color get backgroundColor => theme.scaffoldBackgroundColor;

  /// Get the bar background color from the theme
  Color get barBackgroundColor => theme.barBackgroundColor;

  /// Get the appropriate color for a divider
  Color get dividerColor => _resolveColorFrom(AppColors.separator, this);

  /// Get the appropriate color for a shadow
  Color get shadowColor =>
      isDarkMode
          ? CupertinoColors.black.withOpacity(0.3)
          : CupertinoColors.systemGrey.withOpacity(0.2);

  /// Get the appropriate color for a card background
  Color get cardBackgroundColor =>
      _resolveColorFrom(AppColors.secondaryBackground, this);

  /// Get the appropriate color for a form field background
  Color get formFieldBackgroundColor =>
      CupertinoColors.tertiarySystemFill.resolveFrom(this);

  /// Get the appropriate color for a button background
  Color get buttonBackgroundColor =>
      CupertinoColors.systemFill.resolveFrom(this);

  /// Get the appropriate color for a disabled button
  Color get disabledButtonColor =>
      CupertinoColors.systemGrey4.resolveFrom(this);

  /// Get the appropriate color for a success message
  Color get successColor => _resolveColorFrom(AppColors.secondary, this);

  /// Get the appropriate color for an error message
  Color get errorColor => _resolveColorFrom(AppColors.destructive, this);

  /// Get the appropriate color for a warning message
  Color get warningColor => _resolveColorFrom(AppColors.accent, this);

  /// Get the appropriate color for an info message
  Color get infoColor => _resolveColorFrom(AppColors.primary, this);

  /// Get the appropriate color for a low priority task
  /// Get the appropriate color for a low priority task
  Color get lowPriorityColor => _resolveColorFrom(AppColors.lowPriority, this);

  /// Get the appropriate color for a medium priority task
  Color get mediumPriorityColor =>
      _resolveColorFrom(AppColors.mediumPriority, this);

  /// Get the appropriate color for a high priority task
  Color get highPriorityColor =>
      _resolveColorFrom(AppColors.highPriority, this);

  /// Get the appropriate color for a notification badge
  /// Get the appropriate color for a notification badge
  Color get notificationBadgeColor =>
      _resolveColorFrom(AppColors.notificationBadge, this);

  /// Get the appropriate text color for a given background color
  Color textColorFor(Color backgroundColor) =>
      AppColors.appropriateTextColor(backgroundColor);

  /// Get a color with the specified opacity
  Color withOpacity(Color color, double opacity) => color.withOpacity(opacity);

  /// Helper method to resolve color from context
  Color _resolveColorFrom(Color color, BuildContext context) {
    if (color is CupertinoDynamicColor) {
      return color.resolveFrom(context);
    }
    return color;
  }
}

/// Get a lighter version of the specified color
Color lighten(Color color, [double amount = 0.1]) =>
    AppColors.lighten(color, amount);

/// Get a darker version of the specified color
Color darken(Color color, [double amount = 0.1]) =>
    AppColors.darken(color, amount);

/// Extension on CupertinoThemeData to add custom theme properties
extension CupertinoThemeDataExtension on CupertinoThemeData {
  /// Get the appropriate text color based on the current theme
  Color get textColor =>
      textTheme.textStyle.color ??
      (brightness == Brightness.dark
          ? CupertinoColors.white
          : CupertinoColors.black);

  Color resolveColor(Color color, BuildContext context) {
    if (color is CupertinoDynamicColor) {
      return color.resolveFrom(context);
    }
    return color;
  }
}
