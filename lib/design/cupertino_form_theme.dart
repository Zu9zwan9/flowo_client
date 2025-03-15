import 'package:flutter/cupertino.dart';

/// A design system class for Cupertino forms following Apple's HIG.
class CupertinoFormTheme {
  // Typography
  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: CupertinoColors.label,
  );

  static const TextStyle inputTextStyle = TextStyle(
    fontSize: 17,
    color: CupertinoColors.label,
  );

  static const TextStyle placeholderStyle = TextStyle(
    fontSize: 17,
    color: CupertinoColors.systemGrey,
  );

  static const TextStyle labelTextStyle = TextStyle(
    fontSize: 15,
    color: CupertinoColors.systemBlue,
  );

  static const TextStyle valueTextStyle = TextStyle(
    fontSize: 17,
    color: CupertinoColors.label,
  );

  static const TextStyle helperTextStyle = TextStyle(
    fontSize: 13,
    color: CupertinoColors.systemGrey,
  );

  // Spacing
  static const double horizontalSpacing = 16.0;
  static const double sectionSpacing = 24.0;
  static const double elementSpacing = 12.0;
  static const double smallSpacing = 8.0;
  static const double largeSpacing = 32.0;

  // Colors
  static const Color primaryColor = CupertinoColors.systemBlue;
  static const Color secondaryColor = CupertinoColors.systemGreen;
  static const Color accentColor = CupertinoColors.systemOrange;
  static const Color warningColor = CupertinoColors.systemRed;

  // Decorations
  static BoxDecoration inputDecoration = BoxDecoration(
    color: CupertinoColors.systemBackground,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: CupertinoColors.systemGrey4),
  );

  static BoxDecoration buttonDecoration(Color color) => BoxDecoration(
    color: color.withOpacity(0.1),
    borderRadius: BorderRadius.circular(10),
  );

  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    vertical: 12,
    horizontal: 16,
  );

  // Border Radius
  static const double borderRadius = 10.0;

  // Icon Sizes
  static const double smallIconSize = 16.0;
  static const double standardIconSize = 22.0;

  // Helper Methods
  static String formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  static String formatTime(DateTime? time) =>
      time != null
          ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
          : 'Not set';

  static Color getPriorityColor(int priority) {
    if (priority <= 3) return CupertinoColors.systemGreen;
    if (priority <= 7) return CupertinoColors.systemOrange;
    return CupertinoColors.systemRed;
  }
}
