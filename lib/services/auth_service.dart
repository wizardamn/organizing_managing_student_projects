import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // ✅ ВАЖНО: Укажите здесь свой фактический URL, необходимый для подтверждения
  // Это может быть URL вашего приложения, если вы используете динамические ссылки.
  final String _emailRedirectTo = 'https://yqcywpkkdwkmqposwyoz.supabase.co/auth/v1/callback';

  /// Регистрация нового пользователя с созданием записи в таблице profiles.
  Future<bool> signUp(String email, String password, String fullName, String role) async {
    try {
      if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
        throw Exception('Все поля должны быть заполнены.');
      }
      if (role.isEmpty) {
        throw Exception('Роль не выбрана.');
      }
      // Проверка минимальной длины пароля
      if (password.length < 6) {
        throw Exception('Пароль должен быть не менее 6 символов.');
      }

      final AuthResponse response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
        },
        // ✅ ВЕРНУЛИ emailRedirectTo: Supabase использует этот URL для отправки письма.
        emailRedirectTo: _emailRedirectTo,
      );

      final user = response.user;

      // Если user == null, Supabase успешно отправил письмо.
      if (user == null) {
        return true;
      }

      // ❌ УДАЛИЛИ РУЧНОЕ СОЗДАНИЕ ПРОФИЛЯ.
      // Теперь это обязан делать триггер в БД!

      return true;
    } on AuthException catch (e) {
      throw Exception('Ошибка регистрации: ${e.message}');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Непредвиденная ошибка регистрации: $e');
    }
  }

  /// Вход пользователя по email и паролю.
  Future<bool> signIn(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email и пароль должны быть заполнены.');
      }
      if (password.length < 6) {
        throw Exception('Пароль должен быть не менее 6 символов.');
      }

      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return true;
    } on AuthException catch (e) {
      // ✅ Улучшенная обработка для подсказок
      String message = e.message;
      if (message.contains('Invalid login credentials')) {
        message = 'Неверный email или пароль.';
      } else if (message.contains('Email not confirmed')) {
        message = 'Email не подтвержден. Проверьте почту.';
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('Не удалось войти: $e');
    }
  }

  // ... (getProfile и signOut остаются без изменений)
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<ProfileModel?> getProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select('id, full_name, role, created_at')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        final metadataRole = user.userMetadata?['role'] as String?;
        final metadataName = user.userMetadata?['full_name'] as String?;

        if (metadataRole != null && metadataName != null) {
          // Пытаемся создать недостающую запись, если есть полные метаданные
          await _client.from('profiles').insert({
            'id': user.id,
            'full_name': metadataName,
            'role': metadataRole,
            'created_at': DateTime.now().toIso8601String(),
          });
          return getProfile();
        }
        return null;
      }
      return ProfileModel.fromJson(data, user);
    } on PostgrestException catch (e) {
      throw Exception('Ошибка БД при загрузке профиля: ${e.message}');
    } catch (e) {
      throw Exception('Ошибка при загрузке профиля: $e');
    }
  }
}