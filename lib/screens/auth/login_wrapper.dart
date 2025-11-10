import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import '../home/project_list_screen.dart';

class LoginWrapper extends StatelessWidget {
  const LoginWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Используем StreamBuilder для подписки на изменения состояния аутентификации
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Показываем загрузку при первом подключении или смене состояния
          return const Center(child: CircularProgressIndicator());
        }

        final event = snapshot.data?.event;
        final session = snapshot.data?.session;

        // Если есть активная сессия, пользователь авторизован.
        if (session != null && session.user != null) {
          // 💡 ProjectProvider должен быть настроен на обработку этого события (AUTH_STATE_CHANGED)
          // и автоматическую загрузку данных.
          return const ProjectListScreen();
        }

        // Если нет сессии или произошел SIGN_OUT
        return const LoginScreen();
      },
    );
  }
}