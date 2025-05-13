import 'package:flutter/cupertino.dart';

class CupertinoFormTheme {
  final CupertinoThemeData _themeData;
  final BuildContext context; // Store context as a field

  CupertinoFormTheme(this.context) : _themeData = CupertinoTheme.of(context);

  // Typography
  TextStyle get sectionTitleStyle => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: _themeData.textTheme.textStyle.color,
  );

  TextStyle get inputTextStyle =>
      TextStyle(fontSize: 17, color: _themeData.textTheme.textStyle.color);

  TextStyle get placeholderStyle => TextStyle(
    fontSize: 17,
    color: CupertinoDynamicColor.resolve(CupertinoColors.systemGrey, context),
  );

  TextStyle get labelTextStyle =>
      TextStyle(fontSize: 15, color: _themeData.primaryColor);

  TextStyle get valueTextStyle =>
      TextStyle(fontSize: 17, color: _themeData.textTheme.textStyle.color);

  TextStyle get helperTextStyle => TextStyle(
    fontSize: 13,
    color: CupertinoDynamicColor.resolve(CupertinoColors.systemGrey, context),
  );

  // Spacing (const for performance)
  static const double horizontalSpacing = 16.0;
  static const double sectionSpacing = 24.0;
  static const double elementSpacing = 12.0;
  static const double smallSpacing = 8.0;
  static const double largeSpacing = 32.0;

  // Colors (dynamic based on theme)
  Color get primaryColor => _themeData.primaryColor;
  Color get secondaryColor =>
      CupertinoDynamicColor.resolve(CupertinoColors.systemGreen, context);
  Color get accentColor =>
      CupertinoDynamicColor.resolve(CupertinoColors.systemOrange, context);
  Color get warningColor =>
      CupertinoDynamicColor.resolve(CupertinoColors.systemRed, context);
  Color get backgroundColor => _themeData.scaffoldBackgroundColor;

  // Decorations
  BoxDecoration get inputDecoration => BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: CupertinoDynamicColor.resolve(
        CupertinoColors.systemGrey4,
        context,
      ),
    ),
  );

  BoxDecoration buttonDecoration(Color color) => BoxDecoration(
    color: color.withOpacity(0.1),
    borderRadius: BorderRadius.circular(borderRadius),
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
  String formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String formatTime(DateTime? time) =>
      time != null
          ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
          : 'Not set';

  Color getPriorityColor(int priority) {
    if (priority <= 3) return secondaryColor;
    if (priority <= 7) return accentColor;
    return warningColor;
  }
}
