import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import 'web/web_utilities_interface.dart' as webUtils;

/// A service that provides platform-specific information and utilities.
/// This follows the Single Responsibility Principle by focusing only on platform detection.
class PlatformService {
  /// Returns true if the app is running on the web platform.
  bool get isWeb => kIsWeb;

  /// Returns true if the app is running on a desktop platform (Windows, macOS, Linux).
  bool get isDesktop => kIsWeb ? webUtils.isWebDesktop() : !isIOS && !isAndroid;

  /// Returns true if the app is running on a mobile platform (iOS, Android).
  bool get isMobile => !kIsWeb && (isIOS || isAndroid);

  /// Returns true if the app is running on iOS.
  bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Returns true if the app is running on Android.
  bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Returns true if the app is running on macOS.
  bool get isMacOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  /// Returns true if the app is running on Windows.
  bool get isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// Returns true if the app is running on Linux.
  bool get isLinux => !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  /// Gets the current system theme from the browser (web only)
  String getCurrentSystemTheme() {
    if (!kIsWeb) return 'light';
    return webUtils.getSystemTheme();
  }

  /// Registers a callback to be called when the system theme changes (web only)
  void listenForThemeChanges(void Function(String) callback) {
    if (!kIsWeb) return;
    webUtils.registerThemeChangeListener(callback);
  }

  /// Calls a JavaScript function defined in index.html (web only)
  dynamic callJavaScriptFunction(String functionName, [List<dynamic>? args]) {
    if (!kIsWeb) return null;
    return webUtils.callJsFunction(functionName, args);
  }
}
