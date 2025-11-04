import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import 'supabase_service.dart';

class AuthService {
  final SupabaseClient _client = SupabaseService.client;

  /// Регистрация нового пользователя с созданием записи в таблице profiles.
  /// Возвращает true, если регистрация прошла успешно.
  Future<bool> signUp(String email, String password, String fullName, String role) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
        },
        emailRedirectTo: 'https://yqcywpkkdwkmqposwyoz.supabase.co/auth/v1/callback',
      );

      final user = response.user;
      if (user == null) return false;

      // Создаём профиль в таблице profiles
      await _client.from('profiles').insert({
        'id': user.id,
        'full_name': fullName,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } on AuthException catch (e) {
      throw Exception('Ошибка регистрации: ${e.message}');
    } catch (e) {
      throw Exception('Не удалось зарегистрировать пользователя: $e');
    }
  }

  /// Вход пользователя по email и паролю.
  /// Возвращает true, если вход выполнен успешно.
  Future<bool> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) return false;
      return true;
    } on AuthException catch (e) {
      if (e.message.contains('Email not confirmed')) {
        throw Exception('Ваш email не подтверждён. Проверьте почту.');
      }
      throw Exception('Ошибка входа: ${e.message}');
    } catch (e) {
      throw Exception('Не удалось войти: $e');
    }
  }

  /// Выход из аккаунта
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Получить профиль текущего пользователя
  Future<ProfileModel?> getProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return null;
      return ProfileModel.fromJson(data);
    } catch (e) {
      throw Exception('Ошибка при загрузке профиля: $e');
    }
  }
}
