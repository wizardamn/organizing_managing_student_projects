import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart'; // ✅ Используем сервис

class AuthProvider extends ChangeNotifier {
  // ✅ Используем экземпляр AuthService
  final AuthService _authService = AuthService();
  final supabase = Supabase.instance.client;

  // Геттер для получения текущего пользователя
  User? get user => supabase.auth.currentUser;

  // Геттер, указывающий, авторизован ли пользователь
  bool get isAuthenticated => user != null;

  // 💡 ПРИМЕЧАНИЕ: Методы бросают исключения, которые нужно обрабатывать в UI.

  Future<void> signIn(String email, String password) async {
    // Вход через сервис
    await _authService.signIn(email, password);
    notifyListeners();
  }

  // Обновленный метод signUp, использующий заглушки для fullName и role,
  // так как они не передаются в этом провайдере. В реальном приложении
  // этот метод должен принимать все необходимые параметры из UI.
  Future<void> signUp(String email, String password) async {
    // Регистрация через сервис
    // 💡 ВАЖНО: fullName и role должны быть предоставлены из UI!
    // Я использую заглушки, так как провайдер их не получает.
    await _authService.signUp(
      email,
      password,
      'New User',
      'student',
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    notifyListeners();
  }
}