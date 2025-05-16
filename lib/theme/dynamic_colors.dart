import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'theme_notifier.dart';
import 'app_colors.dart';

/// A utility class that provides dynamic colors that adapt to light and dark modes.
/// This class works with the existing ThemeNotifier to provide a consistent color scheme.
class DynamicColors {
  /// Private constructor to prevent instantiation
  DynamicColors._();

  /// Get the ThemeNotifier from the BuildContext
  static ThemeNotifier getThemeNotifier(BuildContext context) {
    return Provider.of<ThemeNotifier>(context, listen: false);
  }

  static Color resolveColor(BuildContext context, Color color) {
    // Check if we should use dark mode or light mode
    final isDark = isDarkMode(context);

    // If the color is already defined in our system, return it as is
    // Otherwise for custom colors, we can adjust brightness/opacity as needed
    if (isDark) {
      // For dark mode, you might want to lighten some colors
      return color.withOpacity(0.9);
    }

    // For light mode, return the original color
    return color;
  }

  /// Get the current brightness from the ThemeNotifier
  static Brightness getBrightness(BuildContext context) {
    return getThemeNotifier(context).brightness;
  }

  /// Check if the current theme is dark
  static bool isDarkMode(BuildContext context) {
    return getBrightness(context) == Brightness.dark;
  }

  /// Get the primary color from the ThemeNotifier
  static Color getPrimaryColor(BuildContext context) {
    return getThemeNotifier(context).primaryColor;
  }

  /// Get the text color from the ThemeNotifier
  static Color getTextColor(BuildContext context) {
    return getThemeNotifier(context).textColor;
  }

  /// Get the background color from the ThemeNotifier
  static Color getBackgroundColor(BuildContext context) {
    return getThemeNotifier(context).backgroundColor;
  }

  /// Get the appropriate color for a divider
  static Color getDividerColor(BuildContext context) {
    return resolveColor(context, AppColors.separator);
  }

  /// Get the appropriate color for a shadow
  static Color getShadowColor(BuildContext context) {
    return isDarkMode(context)
        ? CupertinoColors.black.withOpacity(0.3)
        : CupertinoColors.systemGrey.withOpacity(0.2);
  }

  /// Get the appropriate color for a card background
  static Color getCardBackgroundColor(BuildContext context) {
    return resolveColor(context, AppColors.secondaryBackground);
  }

  /// Get the appropriate color for a form field background
  static Color getFormFieldBackgroundColor(BuildContext context) {
    return resolveColor(context, AppColors.tertiaryFill);
  }

  /// Get the appropriate color for a button background
  static Color getButtonBackgroundColor(BuildContext context) {
    return resolveColor(context, AppColors.fill);
  }

  /// Get the appropriate color for a disabled button
  static Color getDisabledButtonColor(BuildContext context) {
    return resolveColor(context, AppColors.lightGray);
  }

  /// Get the appropriate color for a success message
  static Color getSuccessColor(BuildContext context) {
    return resolveColor(context, AppColors.secondary);
  }

  /// Get the appropriate color for an error message
  static Color getErrorColor(BuildContext context) {
    return resolveColor(context, AppColors.destructive);
  }

  /// Get the appropriate color for a warning message
  static Color getWarningColor(BuildContext context) {
    return resolveColor(context, AppColors.accent);
  }

  /// Get the appropriate color for an info message
  static Color getInfoColor(BuildContext context) {
    return resolveColor(context, AppColors.primary);
  }

  /// Get the appropriate color for a low priority task
  static Color getLowPriorityColor(BuildContext context) {
    return resolveColor(context, AppColors.lowPriority);
  }

  /// Get the appropriate color for a medium priority task
  static Color getMediumPriorityColor(BuildContext context) {
    return resolveColor(context, AppColors.mediumPriority);
  }

  /// Get the appropriate color for a high priority task
  static Color getHighPriorityColor(BuildContext context) {
    return resolveColor(context, AppColors.highPriority);
  }

  /// Get the appropriate color for a notification badge
  static Color getNotificationBadgeColor(BuildContext context) {
    return resolveColor(context, AppColors.notificationBadge);
  }

  /// Get the appropriate text color for a given background color
  static Color getTextColorForBackground(Color backgroundColor) {
    return AppColors.appropriateTextColor(backgroundColor);
  }

  /// Get a color with the specified opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Get a lighter version of the specified color
  static Color lighten(Color color, [double amount = 0.1]) {
    return AppColors.lighten(color, amount);
  }

  /// Get a darker version of the specified color
  static Color darken(Color color, [double amount = 0.1]) {
    return AppColors.darken(color, amount);
  }

  /// Get the priority color based on the priority level
  static Color getPriorityColor(BuildContext context, int priority) {
    if (priority <= 3) {
      return getLowPriorityColor(context);
    } else if (priority <= 7) {
      return getMediumPriorityColor(context);
    } else {
      return getHighPriorityColor(context);
    }
  }

  /// Get the priority label based on the priority level
  static String getPriorityLabel(int priority) {
    if (priority <= 3) return 'Low';
    if (priority <= 7) return 'Medium';
    return 'High';
  }
}
