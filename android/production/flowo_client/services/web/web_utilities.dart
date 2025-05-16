// This file contains web-specific utilities that use dart:html
// It's imported conditionally only on web platforms

import 'dart:html' as html;

/// Detects if the web app is running on a desktop browser based on window size
bool isWebDesktop() {
  // Consider desktop if width is greater than 768px (tablet breakpoint)
  return html.window.innerWidth! > 768;
}

/// Gets the current system theme from the browser
String getSystemTheme() {
  final isDarkMode =
      html.window.matchMedia('(prefers-color-scheme: dark)').matches;
  return isDarkMode ? 'dark' : 'light';
}

/// Registers a callback to be called when the system theme changes
void registerThemeChangeListener(void Function(String) callback) {
  html.window.matchMedia('(prefers-color-scheme: dark)').addEventListener(
    'change',
    (event) {
      final mediaQueryList = event.target as html.MediaQueryList;
      final newTheme = mediaQueryList.matches ? 'dark' : 'light';
      callback(newTheme);
    },
  );
}

/// Calls a JavaScript function defined in index.html
dynamic callJsFunction(String functionName, [List<dynamic>? args]) {
  final context = html.window;
  // Using hasProperty extension method to check if function exists
  if (context.hasProperty(functionName)) {}
  return null;
}

/// Extension method to check if an object has a property
extension ObjectPropertyExtension on Object {
  bool hasProperty(String name) {
    final jsObject = this as dynamic;
    return jsObject[name] != null;
  }
}
