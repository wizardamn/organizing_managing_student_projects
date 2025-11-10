import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import 'providers/project_provider.dart';
import 'providers/theme_provider.dart';
import 'services/project_service.dart';
import 'screens/auth/login_wrapper.dart';
import 'screens/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await EasyLocalization.ensureInitialized();

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('SUPABASE_URL или SUPABASE_ANON_KEY отсутствуют в .env!');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  final currentUser = Supabase.instance.client.auth.currentUser;

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ru'), Locale('en')],
      path: 'assets/lang',
      fallbackLocale: const Locale('ru'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(
            create: (_) => ProjectProvider(
              ProjectService(),
              // ✅ ИСПРАВЛЕНИЕ: Передаем ID пользователя как именованный аргумент
              userId: currentUser?.id,
            ),
          ),
        ],
        child: const StudentProjectsApp(),
      ),
    ),
  );
}

class StudentProjectsApp extends StatelessWidget {
  const StudentProjectsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Организация проектов учащихся',
      debugShowCheckedModeBanner: false,
      themeMode: themeProv.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routes: {
        '/login': (_) => const LoginScreen(),
      },
      home: const LoginWrapper(),
    );
  }
}