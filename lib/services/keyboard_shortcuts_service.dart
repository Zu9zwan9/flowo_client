import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';

import '../theme_notifier.dart';
import 'web_theme_bridge.dart';

/// A service that handles keyboard shortcuts for the web platform.
class KeyboardShortcutsService {
  final BuildContext context;
  final WebThemeBridge? webThemeBridge;
  final GlobalKey<NavigatorState> navigatorKey;

  KeyboardShortcutsService({
    required this.context,
    required this.navigatorKey,
    this.webThemeBridge,
  }) {
    if (kIsWeb && webThemeBridge != null) {
      _registerKeyboardShortcutHandler();
    }
  }

  /// Registers the keyboard shortcut handler with JavaScript.
  void _registerKeyboardShortcutHandler() {
    webThemeBridge?.callJavaScriptFunction('registerKeyboardShortcutHandler', [
      _handleKeyboardShortcut,
    ]);
  }

  /// Handles keyboard shortcuts from JavaScript.
  void _handleKeyboardShortcut(String shortcut) {
    switch (shortcut) {
      case 'new_task':
        _navigateToNewTask();
        break;
      case 'pomodoro':
        _navigateToPomodoro();
        break;
      case 'toggle_theme':
        _toggleTheme();
        break;
      case 'search':
        _focusSearch();
        break;
      case 'settings':
        _navigateToSettings();
        break;
      case 'calendar':
        _navigateToCalendar();
        break;
      case 'home':
        _navigateToHome();
        break;
      case 'statistics':
        _navigateToStatistics();
        break;
    }
  }

  /// Navigates to the new task screen.
  void _navigateToNewTask() {
    navigatorKey.currentState?.pushNamed('/add_task');
  }

  /// Navigates to the pomodoro screen.
  void _navigateToPomodoro() {
    navigatorKey.currentState?.pushNamed('/pomodoro');
  }

  /// Toggles between light and dark theme.
  void _toggleTheme() {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    themeNotifier.toggleDarkMode();
  }

  /// Focuses the search field.
  void _focusSearch() {
    // This would need to be implemented by finding and focusing the search field
    // in the current screen, which would require a more complex implementation.
  }

  /// Navigates to the settings screen.
  void _navigateToSettings() {
    navigatorKey.currentState?.pushNamed('/settings');
  }

  /// Navigates to the calendar screen.
  void _navigateToCalendar() {
    navigatorKey.currentState?.pushNamed('/calendar');
  }

  /// Navigates to the home screen.
  void _navigateToHome() {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  /// Navigates to the statistics screen.
  void _navigateToStatistics() {
    navigatorKey.currentState?.pushNamed('/statistics');
  }
}
