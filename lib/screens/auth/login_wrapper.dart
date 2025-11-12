import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/project_provider.dart';
import '../../services/auth_service.dart';

// ✅ Импортируем экраны, которые мы будем показывать
import '../home/project_list_screen.dart';
import 'login_screen.dart';

// ✅ Внутреннее состояние для LoginWrapper
enum AuthStatus { loading, loggedIn, loggedOut }

class LoginWrapper extends StatefulWidget {
  const LoginWrapper({super.key});

  @override
  State<LoginWrapper> createState() => _LoginWrapperState();
}

class _LoginWrapperState extends State<LoginWrapper> {
  late final StreamSubscription<AuthState> _authStateSubscription;
  final _authService = AuthService();

  // ✅ Храним текущее состояние аутентификации
  AuthStatus _status = AuthStatus.loading;

  @override
  void initState() {
    super.initState();

    // Проверяем синхронно при запуске, чтобы избежать "мерцания"
    // (показа экрана входа, если сессия уже есть)
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      // Если пользователя точно нет, сразу ставим loggedOut
      setState(() => _status = AuthStatus.loggedOut);
    }
    // Если пользователь ЕСТЬ, мы оставляем 'loading',
    // пока _setupAuthListener не загрузит профиль и не вызовет setUser.

    _setupAuthListener();
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  /// Настраивает слушатель событий Supabase
  void _setupAuthListener() {
    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
          final session = data.session;
          // Используем context.read(), так как мы ВНУТРИ initState/listener
          final prov = context.read<ProjectProvider>();

          if (session != null) {
            // ✅ СЕССИЯ ЕСТЬ (Пользователь вошел ИЛИ приложение запустилось с сохраненной сессией)
            debugPrint("LoginWrapper: Сессия найдена. Загрузка профиля...");
            try {
              final profile = await _authService.getProfile();

              if (profile != null && mounted) {
                debugPrint("LoginWrapper: Профиль ${profile.fullName} загружен.");
                await prov.setUser(profile.id, profile.fullName);

                // ✅ ИСПРАВЛЕНИЕ: Вместо навигации, меняем состояние
                setState(() => _status = AuthStatus.loggedIn);
              } else {
                throw Exception("Профиль не найден для пользователя ${session.user.id}");
              }
            } catch (e) {
              debugPrint("LoginWrapper: Ошибка загрузки профиля: $e");
              if (mounted) _handleSignOut(prov);
            }
          } else {
            // ✅ СЕССИИ НЕТ (Пользователь вышел)
            debugPrint("LoginWrapper: Сессия не найдена (signed out).");
            if (mounted) _handleSignOut(prov);
          }
        });
  }

  // Обработчик выхода
  void _handleSignOut(ProjectProvider prov) {
    prov.clear(keepProjects: false);

    // ✅ ИСПРАВЛЕНИЕ: Вместо навигации, меняем состояние
    // Проверяем, что мы уже не в этом состоянии, чтобы избежать лишних setState
    if (_status != AuthStatus.loggedOut) {
      setState(() => _status = AuthStatus.loggedOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ИСПРАВЛЕНИЕ: Build теперь возвращает нужный экран, а не Spinner
    switch (_status) {
      case AuthStatus.loading:
      // Показываем загрузку, пока listener определяет состояние
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.loggedIn:
      // Показываем главный экран
        return const ProjectListScreen();
      case AuthStatus.loggedOut:
      // Показываем экран входа
        return const LoginScreen();
    }
  }
}