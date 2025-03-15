import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  // Use CupertinoThemeData for Cupertino styling
  late CupertinoThemeData _cupertinoTheme;
  // Keep Material ThemeData for backward compatibility
  late ThemeData _currentTheme;
  String _currentThemeName = 'Light';
  String _currentFont = 'SF Pro';
  Color _primaryColor = CupertinoColors.systemBlue;
  Color _textColor = CupertinoColors.label;
  Color _backgroundColor = CupertinoColors.systemBackground;

  ThemeNotifier() {
    // Initialize with default theme
    setTheme('Light');
  }

  CupertinoThemeData get cupertinoTheme => _cupertinoTheme;
  ThemeData get currentTheme => _currentTheme;
  String get currentThemeName => _currentThemeName;
  String get currentFont => _currentFont;
  Color get primaryColor => _primaryColor;
  Color get textColor => _textColor;
  Color get backgroundColor => _backgroundColor;

  // For backward compatibility
  Color get iconColor => _primaryColor;
  Color get menuBackgroundColor => _backgroundColor;

  void setTheme(String theme) {
    _currentThemeName = theme;
    switch (theme) {
      case 'Light':
        // Configure Cupertino theme for Light mode
        _cupertinoTheme = const CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: CupertinoColors.systemBlue,
          textTheme: CupertinoTextThemeData(
            textStyle: TextStyle(
              fontFamily: 'SF Pro',
              color: CupertinoColors.label,
              fontSize: 16,
            ),
          ),
          scaffoldBackgroundColor: CupertinoColors.systemBackground,
        );

        // For backward compatibility
        _currentTheme = ThemeData.light().copyWith(
          primaryColor: CupertinoColors.systemBlue,
          scaffoldBackgroundColor: CupertinoColors.systemBackground,
          textTheme: Typography.material2018().black.apply(
                fontFamily: _currentFont,
                decoration: TextDecoration.none,
              ),
        );
        _primaryColor = CupertinoColors.systemBlue;
        _textColor = CupertinoColors.label;
        _backgroundColor = CupertinoColors.systemBackground;
        break;

      case 'Night':
        // Configure Cupertino theme for Dark mode
        _cupertinoTheme = const CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: CupertinoColors.systemBlue,
          textTheme: CupertinoTextThemeData(
            textStyle: TextStyle(
              fontFamily: 'SF Pro',
              color: CupertinoColors.white,
              fontSize: 16,
            ),
          ),
          scaffoldBackgroundColor: CupertinoColors.black,
        );

        // For backward compatibility
        _currentTheme = ThemeData.dark().copyWith(
          primaryColor: CupertinoColors.systemBlue,
          scaffoldBackgroundColor: CupertinoColors.black,
          textTheme: Typography.material2018().white.apply(
                fontFamily: _currentFont,
                decoration: TextDecoration.none,
              ),
        );
        _primaryColor = CupertinoColors.systemBlue;
        _textColor = CupertinoColors.white;
        _backgroundColor = CupertinoColors.black;
        break;

      case 'ADHD':
        // Configure Cupertino theme for ADHD mode (high contrast, focused)
        _cupertinoTheme = const CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: CupertinoColors.systemOrange,
          textTheme: CupertinoTextThemeData(
            textStyle: TextStyle(
              fontFamily: 'SF Pro',
              color: CupertinoColors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          scaffoldBackgroundColor: CupertinoColors.systemBackground,
        );

        // For backward compatibility
        _currentTheme = ThemeData.light().copyWith(
          primaryColor: CupertinoColors.systemOrange,
          scaffoldBackgroundColor: CupertinoColors.systemBackground,
          textTheme: Typography.material2018().black.apply(
                fontFamily: _currentFont,
                decoration: TextDecoration.none,
              ),
        );
        _primaryColor = CupertinoColors.systemOrange;
        _textColor = CupertinoColors.black;
        _backgroundColor = CupertinoColors.systemBackground;
        break;

      default:
        // Default to Light theme
        _cupertinoTheme = const CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: CupertinoColors.systemBlue,
          textTheme: CupertinoTextThemeData(
            textStyle: TextStyle(
              fontFamily: 'SF Pro',
              color: CupertinoColors.label,
              fontSize: 16,
            ),
          ),
          scaffoldBackgroundColor: CupertinoColors.systemBackground,
        );

        // For backward compatibility
        _currentTheme = ThemeData.light().copyWith(
          primaryColor: CupertinoColors.systemBlue,
          scaffoldBackgroundColor: CupertinoColors.systemBackground,
          textTheme: Typography.material2018().black.apply(
                fontFamily: _currentFont,
                decoration: TextDecoration.none,
              ),
        );
        _primaryColor = CupertinoColors.systemBlue;
        _textColor = CupertinoColors.label;
        _backgroundColor = CupertinoColors.systemBackground;
    }
    notifyListeners();
  }

  void setFont(String font) {
    _currentFont = font;

    // Update Cupertino theme with new font
    _cupertinoTheme = _cupertinoTheme.copyWith(
      textTheme: _cupertinoTheme.textTheme.copyWith(
        textStyle: _cupertinoTheme.textTheme.textStyle.copyWith(
          fontFamily: _currentFont,
        ),
      ),
    );

    // Update Material theme for backward compatibility
    _currentTheme = _currentTheme.copyWith(
      textTheme: _currentTheme.textTheme.apply(
        fontFamily: _currentFont,
        decoration: TextDecoration.none,
      ),
    );

    notifyListeners();
  }
}
