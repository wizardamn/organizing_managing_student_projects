import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/project_provider.dart';
import '../auth/login_screen.dart';
import '../project_list_screen.dart';

class LoginWrapper extends StatelessWidget {
  const LoginWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    final user = session?.user;

    // Используем post-frame callback безопасно
    if (user != null && user.emailConfirmedAt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Provider.of<ProjectProvider>(context, listen: false)
              .initialize(userId: user.id);
        }
      });

      return const ProjectListScreen();
    }

    return const LoginScreen();
  }
}
