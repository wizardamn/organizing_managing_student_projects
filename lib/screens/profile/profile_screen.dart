import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../providers/project_provider.dart';
// ✅ ИМПОРТ: Используем модель из файла models/profile_model.dart
import '../../models/profile_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  // ✅ УДАЛЕНО: _roleController, так как роль не редактируется

  ProfileModel? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      // ✅ Используем AuthService для получения профиля
      final profile = await _authService.getProfile();

      if (profile != null && mounted) {
        _profile = profile;
        _nameController.text = profile.fullName;
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки профиля: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    // Проверка, что форма валидна и профиль загружен
    if (!_formKey.currentState!.validate() || _profile == null) return;

    final newName = _nameController.text.trim();

    // Запрещаем сохранение, если имя не изменилось
    if (newName == _profile!.fullName) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет изменений для сохранения')),
        );
      }
      return;
    }

    try {
      // 1. Обновляем полное имя в таблице profiles
      await Supabase.instance.client.from('profiles').update({
        'full_name': newName,
      }).eq('id', _profile!.id);

      // 2. Обновляем метаданные Auth-пользователя (для drawer)
      await Supabase.instance.client.auth.updateUser(UserAttributes(
        data: {'full_name': newName},
      ));


      if (!mounted) return;

      // ✅ Уведомляем ProjectProvider об изменении имени
      final prov = context.read<ProjectProvider>();
      prov.updateUserName(newName);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль успешно обновлён')),
      );

      // Обновляем локальное состояние, используя copyWith или новый конструктор
      setState(() {
        _profile = ProfileModel(
          id: _profile!.id,
          fullName: newName,
          role: _profile!.role,
          email: _profile!.email,
          createdAt: _profile!.createdAt,
        );
      });

    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка БД: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось обновить профиль: $e')),
        );
      }
    }
  }

  // ✅ Утилита для получения отображаемого названия роли
  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'student':
        return 'Учащийся';
      case 'teacher':
        return 'Преподаватель';
      case 'leader':
        return 'Руководитель проекта';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Если _loading == false, _profile должен быть не-null. Используем !.
    final profile = _profile!;
    final displayRole = _getRoleDisplayName(profile.role);

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 12),
              Center(
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(Icons.person, size: 50, color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ),
              const SizedBox(height: 20),
              // Поле для редактирования полного имени
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Полное имя'),
                validator: (v) =>
                v == null || v.isEmpty ? 'Введите имя' : null,
              ),
              const SizedBox(height: 12),
              // Поле для email (только чтение)
              TextFormField(
                enabled: false,
                initialValue: profile.email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              // Поле для роли (только чтение)
              TextFormField(
                readOnly: true,
                initialValue: displayRole,
                decoration: const InputDecoration(
                    labelText: 'Роль',
                    prefixIcon: Icon(Icons.badge_outlined)
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save),
                label: const Text('Сохранить изменения'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}