import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import '../providers/project_provider.dart';
import '../providers/theme_provider.dart';
import '../models/project.dart';

class UserProfileDrawer extends StatelessWidget {
  const UserProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final prov = Provider.of<ProjectProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final isGuest = prov.isGuest;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.userMetadata?['full_name'] ?? tr('guest')),
            accountEmail: Text(user?.email ?? tr('no_email')),
            currentAccountPicture: const CircleAvatar(child: Icon(Icons.person, size: 36)),
            onDetailsPressed: () => _showProfileDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: Text(tr('my_projects')),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(tr('choose_language')),
            onTap: () => _showLanguageDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: Text(themeProv.isDarkMode ? 'Темная тема' : 'Светлая тема'),
            onTap: () => themeProv.toggleTheme(),
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: Text(tr('refresh_projects')),
            onTap: () async {
              await prov.fetchProjects();
              if (context.mounted) Navigator.pop(context);
            },
          ),

          if (isGuest)
            ListTile(
              leading: const Icon(Icons.login),
              title: Text('Войти как пользователь'),
              onTap: () {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
            ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(tr('logout')),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              prov.initialize(
                userId: null,
                onLogout: () {
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
              );
            },
          ),

          const Divider(),

          // Показываем список проектов
          Expanded(
            child: prov.view.isEmpty
                ? Center(child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(tr('no_projects')),
            ))
                : ListView.builder(
              itemCount: prov.view.length,
              itemBuilder: (context, index) {
                final project = prov.view[index];
                return ListTile(
                  leading: const Icon(Icons.work),
                  title: Text(project.title),
                  subtitle: Text(
                    '${tr('status')}: ${_statusToString(project.status)}\n${tr('deadline')}: ${DateFormat('yyyy-MM-dd').format(project.deadline)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.pop(context); // Закрыть Drawer
                    // Открыть подробности проекта, если нужно
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('choose_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Русский'),
              onTap: () {
                context.setLocale(const Locale('ru'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              onTap: () {
                context.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('profile')),
        content: Text(tr('not_implemented')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('ok')),
          ),
        ],
      ),
    );
  }

  String _statusToString(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.inProgress:
        return tr('in_progress');
      case ProjectStatus.completed:
        return tr('completed');
      case ProjectStatus.pending:
        return tr('pending');
    }
  }
}
