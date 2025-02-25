import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeData _currentTheme = ThemeData.light();
  String _currentThemeName = 'Light';
  String _currentFont = 'Roboto';
  Color _iconColor = Colors.black;
  Color _textColor = Colors.black;
  Color _menuBackgroundColor = Colors.white;

  ThemeData get currentTheme => _currentTheme;
  String get currentThemeName => _currentThemeName;
  String get currentFont => _currentFont;
  Color get iconColor => _iconColor;
  Color get textColor => _textColor;
  Color get menuBackgroundColor => _menuBackgroundColor;

  get themeMode => null;

  void setTheme(String theme) {
    _currentThemeName = theme;
    switch (theme) {
      case 'Light':
        _currentTheme = ThemeData.light().copyWith(
          textTheme: _currentTheme.textTheme.apply(
            fontFamily: _currentFont,
            decoration: TextDecoration.none,
          ),
        );
        _iconColor = Colors.black;
        _textColor = Colors.black;
        _menuBackgroundColor = Colors.white;
        break;
      case 'Night':
        _currentTheme = ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.blueGrey,
        ).copyWith(
          textTheme: _currentTheme.textTheme.apply(
            fontFamily: _currentFont,
            decoration: TextDecoration.none,
          ),
        );
        _iconColor = Colors.white;
        _textColor = Colors.white;
        _menuBackgroundColor = Colors.black;
        break;
      case 'ADHD':
        _currentTheme = ThemeData(
          brightness: Brightness.light,
          primaryColor: Colors.yellow,
          hintColor: Colors.orange,
        ).copyWith(
          textTheme: _currentTheme.textTheme.apply(
            fontFamily: _currentFont,
            decoration: TextDecoration.none,
          ),
        );
        _iconColor = Colors.black;
        _textColor = Colors.black;
        _menuBackgroundColor = Colors.white;
        break;
      default:
        _currentTheme = ThemeData.light().copyWith(
          textTheme: _currentTheme.textTheme.apply(
            fontFamily: _currentFont,
            decoration: TextDecoration.none,
          ),
        );
        _iconColor = Colors.black;
        _textColor = Colors.black;
        _menuBackgroundColor = Colors.white;
    }
    notifyListeners();
  }

  void setFont(String font) {
    _currentFont = font;
    _currentTheme = _currentTheme.copyWith(
      textTheme: _currentTheme.textTheme.apply(
        fontFamily: _currentFont,
        decoration: TextDecoration.none,
      ),
    );
    notifyListeners();
  }
}
