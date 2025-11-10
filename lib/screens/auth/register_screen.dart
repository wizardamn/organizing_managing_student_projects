import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../providers/project_provider.dart'; // ✅ Используем ProjectProvider
import '../home/project_list_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  String _role = 'student';
  bool _isLoading = false;

  void _register() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final success = await _auth.signUp(
        _email.text.trim(),
        _password.text.trim(),
        _fullName.text.trim(),
        _role,
      );

      if (!mounted) return;

      if (success) {
        // 💡 После успешной регистрации, ProjectProvider загружает данные
        // и перенаправляет на ProjectListScreen
        final projectProvider = context.read<ProjectProvider>();
        await projectProvider.fetchProjects();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Регистрация успешна. Проверьте почту для подтверждения!')),
          );
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProjectListScreen()));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось завершить регистрацию.')),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _fullName, decoration: const InputDecoration(labelText: 'Имя')),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Пароль'), obscureText: true),
            DropdownButton<String>(
              value: _role,
              items: const [
                DropdownMenuItem(value: 'student', child: Text('Учащийся')),
                DropdownMenuItem(value: 'teacher', child: Text('Преподаватель')),
                DropdownMenuItem(value: 'leader', child: Text('Руководитель проекта')),
              ],
              onChanged: (v) => setState(() => _role = v!),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _register, child: const Text('Зарегистрироваться')),
          ],
        ),
      ),
    );
  }
}