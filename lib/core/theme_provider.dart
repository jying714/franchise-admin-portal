import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  void toggleTheme([bool? dark]) {
    if (dark == null) {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    } else {
      _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    }
    notifyListeners();
  }
}
