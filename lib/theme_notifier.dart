import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeData _currentTheme = ThemeData.light();

  ThemeData get currentTheme => _currentTheme;

  void setTheme(String theme) {
    switch (theme) {
      case 'Light':
        _currentTheme = ThemeData.light();
        break;
      case 'Dark':
        _currentTheme = ThemeData.dark();
        break;
      case 'Night':
        _currentTheme = ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.blueGrey,
        );
        break;
      case 'ADHD':
        _currentTheme = ThemeData(
          brightness: Brightness.light,
          primaryColor: Colors.yellow,
          hintColor: Colors.orange,
        );
        break;
      default:
        _currentTheme = ThemeData.light();
    }
    notifyListeners();
  }
}
