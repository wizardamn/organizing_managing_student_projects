import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // 💡 Используем более точное имя переменной, но оставляем старый геттер для совместимости
  bool _isDark = false;
  bool get isDark => _isDark;
  bool get isDarkMode => _isDark;

  ThemeMode get currentTheme => _isDark ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}