import 'package:flutter/cupertino.dart';

/// A utility class to resolve Hero tag conflicts in Cupertino navigation bars
///
/// The default implementation of CupertinoNavigationBar creates Hero widgets with
/// the same tag for different navigation bars within the same navigator, which
/// causes conflicts. This class provides a way to create unique Hero tags for
/// each navigation bar.
class CupertinoHeroTagResolver {
  /// Creates a CupertinoNavigationBar with a unique Hero tag
  ///
  /// This method wraps the standard CupertinoNavigationBar constructor and adds
  /// a unique heroTag parameter to prevent conflicts when multiple navigation bars
  /// are present in the same navigator.
  ///
  /// Parameters:
  /// - [key]: An optional key to identify this widget
  /// - [leading]: A widget to display before the navigation bar's title
  /// - [automaticallyImplyLeading]: Whether to automatically add a back button when appropriate
  /// - [automaticallyImplyMiddle]: Whether to automatically add a middle widget when none is provided
  /// - [previousPageTitle]: The title of the previous page, used for the back button label
  /// - [middle]: The primary content of the navigation bar
  /// - [trailing]: A widget to display after the navigation bar's title
  /// - [border]: The border to draw at the bottom of the navigation bar
  /// - [backgroundColor]: The color to use for the navigation bar's background
  /// - [brightness]: The brightness of the navigation bar
  /// - [padding]: The padding to apply to the navigation bar's contents
  /// - [transitionBetweenRoutes]: Whether to transition between routes
  /// - [uniqueIdentifier]: A unique identifier to use for the Hero tag (defaults to a unique string)
  ///
  /// Returns a CupertinoNavigationBar with a unique Hero tag
  static CupertinoNavigationBar create({
    Key? key,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    bool automaticallyImplyMiddle = true,
    String? previousPageTitle,
    Widget? middle,
    Widget? trailing,
    Border? border,
    Color? backgroundColor,
    Brightness? brightness,
    EdgeInsetsDirectional? padding,
    bool transitionBetweenRoutes = true,
    String? uniqueIdentifier,
  }) {
    // Generate a unique tag for this navigation bar
    final String heroTag =
        uniqueIdentifier ?? 'cupertino-navbar-${UniqueKey()}';

    return CupertinoNavigationBar(
      key: key,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      automaticallyImplyMiddle: automaticallyImplyMiddle,
      previousPageTitle: previousPageTitle,
      middle: middle,
      trailing: trailing,
      border: border,
      backgroundColor: backgroundColor,
      brightness: brightness,
      padding: padding,
      transitionBetweenRoutes: transitionBetweenRoutes,
      heroTag: heroTag, // Use the unique hero tag
    );
  }
}
