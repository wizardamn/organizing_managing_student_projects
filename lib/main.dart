import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import 'providers/project_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_wrapper.dart';
import 'services/supabase_project_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await EasyLocalization.ensureInitialized();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ru')],
      path: 'assets/lang', // Убедитесь, что ваши en.json и ru.json находятся по этому пути
      fallbackLocale: const Locale('ru'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(
            create: (_) => ProjectProvider(
              SupabaseProjectRepository(),
              Supabase.instance.client.auth.currentUser?.id,
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
      title: 'Student Projects',
      debugShowCheckedModeBanner: false,
      themeMode: themeProv.currentTheme,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const LoginWrapper(),
    );
  }
}
