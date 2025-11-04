import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import '../providers/project_provider.dart';
import '../providers/theme_provider.dart';

class UserProfileDrawer extends StatelessWidget {
  const UserProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final prov = Provider.of<ProjectProvider>(context, listen: false);
    final themeProv = Provider.of<ThemeProvider>(context);

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.userMetadata?['full_name'] ?? tr('guest')),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: const CircleAvatar(child: Icon(Icons.person, size: 36)),
            onDetailsPressed: () => _showProfileDialog(context),
          ),
          ListTile(leading: const Icon(Icons.assignment), title: Text(tr('my_projects')), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.language), title: Text(tr('choose_language')), onTap: () => _showLanguageDialog(context)),
          ListTile(leading: const Icon(Icons.brightness_6), title: Text(themeProv.isDarkMode ? 'Темная тема' : 'Светлая тема'), onTap: () => themeProv.toggleTheme()),
          ListTile(leading: const Icon(Icons.refresh), title: Text(tr('refresh_projects')), onTap: () async {
            await prov.fetchProjects();
            if (context.mounted) Navigator.pop(context);
          }),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(tr('logout')),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              prov.initialize(userId: null);
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
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
            ListTile(title: const Text('Русский'), onTap: () { context.setLocale(const Locale('ru')); Navigator.pop(context); }),
            ListTile(title: const Text('English'), onTap: () { context.setLocale(const Locale('en')); Navigator.pop(context); }),
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
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('ok')))],
      ),
    );
  }
}
