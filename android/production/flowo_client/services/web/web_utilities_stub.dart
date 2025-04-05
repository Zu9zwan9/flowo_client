// This file contains stub implementations for non-web platforms

/// Stub implementation for non-web platforms
bool isWebDesktop() {
  return false;
}

/// Stub implementation for non-web platforms
String getSystemTheme() {
  return 'light'; // Default to light theme on non-web platforms
}

/// Stub implementation for non-web platforms
void registerThemeChangeListener(void Function(String) callback) {
  // No-op on non-web platforms
}

/// Stub implementation for non-web platforms
dynamic callJsFunction(String functionName, [List<dynamic>? args]) {
  return null;
}

/// Stub extension for non-web platforms
extension ObjectPropertyExtension on Object {
  bool hasProperty(String name) {
    return false;
  }
}
