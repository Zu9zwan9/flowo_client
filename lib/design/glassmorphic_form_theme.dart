import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../theme_notifier.dart';
import 'cupertino_form_theme.dart';

/// A design system for glassmorphic forms adhering to Apple's HIG with dynamic theming.
/// This extends the CupertinoFormTheme with glassmorphic styling.
class GlassmorphicFormTheme extends CupertinoFormTheme {
  /// The glassmorphic theme from the ThemeNotifier
  final GlassmorphicTheme _glassmorphicTheme;

  /// Creates a glassmorphic form theme.
  GlassmorphicFormTheme(super.context)
    : _glassmorphicTheme =
          Provider.of<ThemeNotifier>(context).glassmorphicTheme;

  // Spacing (const for performance) - copied from CupertinoFormTheme
  static const double horizontalSpacing = CupertinoFormTheme.horizontalSpacing;
  static const double sectionSpacing = CupertinoFormTheme.sectionSpacing;
  static const double elementSpacing = CupertinoFormTheme.elementSpacing;
  static const double smallSpacing = CupertinoFormTheme.smallSpacing;
  static const double largeSpacing = CupertinoFormTheme.largeSpacing;

  // Border Radius - copied from CupertinoFormTheme
  static const double borderRadius = CupertinoFormTheme.borderRadius;

  // Icon Sizes - copied from CupertinoFormTheme
  static const double smallIconSize = CupertinoFormTheme.smallIconSize;
  static const double standardIconSize = CupertinoFormTheme.standardIconSize;

  // Padding - copied from CupertinoFormTheme
  static const EdgeInsets inputPadding = CupertinoFormTheme.inputPadding;

  /// The default blur intensity for glassmorphic effects
  double get defaultBlur => _glassmorphicTheme.defaultBlur;

  /// The default opacity for glassmorphic backgrounds
  double get defaultOpacity => _glassmorphicTheme.defaultOpacity;

  /// The default border width for glassmorphic containers
  double get defaultBorderWidth => _glassmorphicTheme.defaultBorderWidth;

  /// The default border radius for glassmorphic containers
  BorderRadius get defaultBorderRadius =>
      _glassmorphicTheme.defaultBorderRadius;

  /// The border color for glassmorphic containers
  Color get borderColor => _glassmorphicTheme.borderColor;

  /// The background color for glassmorphic containers
  Color get backgroundColorWithOpacity => _glassmorphicTheme.backgroundColor;

  /// The shadow color for glassmorphic containers
  Color get shadowColor => _glassmorphicTheme.shadowColor;

  /// The shadow opacity for glassmorphic containers
  double get shadowOpacity => _glassmorphicTheme.shadowOpacity;

  /// The shadow blur radius for glassmorphic containers
  double get shadowBlurRadius => _glassmorphicTheme.shadowBlurRadius;

  /// The shadow spread radius for glassmorphic containers
  double get shadowSpreadRadius => _glassmorphicTheme.shadowSpreadRadius;

  /// Returns a color with a glassmorphic effect based on the primary color
  Color get primaryGlassColor => primaryColor.withOpacity(0.3);

  /// Returns a color with a glassmorphic effect based on the secondary color
  Color get secondaryGlassColor => secondaryColor.withOpacity(0.3);

  /// Returns a color with a glassmorphic effect based on the accent color
  Color get accentGlassColor => accentColor.withOpacity(0.3);

  /// Returns a color with a glassmorphic effect based on the warning color
  Color get warningGlassColor => warningColor.withOpacity(0.3);

  /// Returns a color with a glassmorphic effect based on the background color
  Color get backgroundGlassColor => backgroundColor.withOpacity(defaultOpacity);

  /// Returns a glassmorphic decoration for input fields
  BoxDecoration get glassmorphicInputDecoration => BoxDecoration(
    color: backgroundGlassColor,
    borderRadius: BorderRadius.circular(GlassmorphicFormTheme.borderRadius),
    border: Border.all(color: borderColor, width: defaultBorderWidth),
    boxShadow: [
      BoxShadow(
        color: shadowColor.withOpacity(shadowOpacity),
        blurRadius: shadowBlurRadius,
        spreadRadius: shadowSpreadRadius,
      ),
    ],
  );

  /// Returns a glassmorphic decoration for buttons
  BoxDecoration glassmorphicButtonDecoration(Color color) => BoxDecoration(
    color: color.withOpacity(0.2),
    borderRadius: BorderRadius.circular(GlassmorphicFormTheme.borderRadius),
    border: Border.all(
      color: color.withOpacity(0.3),
      width: defaultBorderWidth,
    ),
    boxShadow: [
      BoxShadow(
        color: shadowColor.withOpacity(shadowOpacity),
        blurRadius: shadowBlurRadius,
        spreadRadius: shadowSpreadRadius,
      ),
    ],
  );

  /// Returns a glassmorphic decoration for form groups
  BoxDecoration get glassmorphicFormGroupDecoration => BoxDecoration(
    color: backgroundGlassColor,
    borderRadius: BorderRadius.circular(GlassmorphicFormTheme.borderRadius),
    border: Border.all(color: borderColor, width: defaultBorderWidth),
    boxShadow: [
      BoxShadow(
        color: shadowColor.withOpacity(shadowOpacity),
        blurRadius: shadowBlurRadius,
        spreadRadius: shadowSpreadRadius,
      ),
    ],
  );

  /// Returns a glassmorphic decoration for cards
  BoxDecoration get glassmorphicCardDecoration => BoxDecoration(
    color: backgroundGlassColor,
    borderRadius: BorderRadius.circular(GlassmorphicFormTheme.borderRadius),
    border: Border.all(color: borderColor, width: defaultBorderWidth),
    boxShadow: [
      BoxShadow(
        color: shadowColor.withOpacity(shadowOpacity),
        blurRadius: shadowBlurRadius,
        spreadRadius: shadowSpreadRadius,
      ),
    ],
  );

  /// Returns a glassmorphic decoration for color options
  BoxDecoration glassmorphicColorOptionDecoration(
    Color color,
    bool isSelected,
  ) => BoxDecoration(
    shape: BoxShape.circle,
    color: color.withOpacity(0.7),
    border: Border.all(
      color: isSelected ? primaryColor : borderColor,
      width: isSelected ? defaultBorderWidth * 1.5 : defaultBorderWidth,
    ),
    boxShadow: [
      BoxShadow(
        color: shadowColor.withOpacity(shadowOpacity),
        blurRadius: shadowBlurRadius,
        spreadRadius: shadowSpreadRadius,
      ),
    ],
  );

  /// Returns a glassmorphic decoration for the navigation bar
  BoxDecoration get glassmorphicNavBarDecoration => BoxDecoration(
    color: CupertinoTheme.of(context).barBackgroundColor.withOpacity(0.8),
    border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
    boxShadow: [
      BoxShadow(
        color: shadowColor.withOpacity(shadowOpacity / 2),
        blurRadius: shadowBlurRadius / 2,
        spreadRadius: 0,
      ),
    ],
  );
}
