import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Brightness;

import 'web/web_utilities_interface.dart' as webUtils;

/// A service that bridges the web's system theme detection with Flutter's theme system.
/// This follows the Single Responsibility Principle by focusing only on theme bridging.
class WebThemeBridge {
  /// Returns the current system theme as a Brightness value.
  /// On web, this uses the browser's prefers-color-scheme media query.
  /// On non-web platforms, this returns null (to use the platform's default).
  Brightness? getSystemBrightness() {
    if (!kIsWeb) return null;

    final theme = webUtils.getSystemTheme();
    return theme == 'dark' ? Brightness.dark : Brightness.light;
  }

  /// Registers a callback to be called when the system theme changes.
  /// On web, this uses the browser's prefers-color-scheme media query.
  /// On non-web platforms, this does nothing.
  void listenForThemeChanges(void Function(Brightness) callback) {
    if (!kIsWeb) return;

    webUtils.registerThemeChangeListener((theme) {
      final brightness = theme == 'dark' ? Brightness.dark : Brightness.light;
      callback(brightness);
    });
  }

  /// Calls a JavaScript function defined in index.html.
  /// This is useful for interacting with the web page directly.
  /// On non-web platforms, this returns null.
  dynamic callJavaScriptFunction(String functionName, [List<dynamic>? args]) {
    if (!kIsWeb) return null;

    return webUtils.callJsFunction(functionName, args);
  }

  /// Returns true if the app is running on the web platform.
  bool get isWeb => kIsWeb;

  /// Returns true if the app is running on a desktop browser.
  bool get isWebDesktop => kIsWeb ? webUtils.isWebDesktop() : false;

  /// Returns true if the app is running on a mobile browser.
  bool get isWebMobile => kIsWeb ? !webUtils.isWebDesktop() : false;
}
