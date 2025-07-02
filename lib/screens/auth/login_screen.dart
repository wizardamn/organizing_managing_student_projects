import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/project_provider.dart';
import '../project_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final pwd = _passwordController.text.trim();

    try {
      final auth = Supabase.instance.client.auth;
      final response = _isLogin
          ? await auth.signInWithPassword(email: email, password: pwd)
          : await auth.signUp(email: email, password: pwd);

      final userId = response.user?.id;
      if (!mounted) return;

      Provider.of<ProjectProvider>(context, listen: false).initialize(userId: userId);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProjectListScreen()),
      );
    } catch (e) {
      setState(() {
        _error = e is AuthException ? e.message : 'Ошибка авторизации';
      });
    }
  }

  Future<void> _guestLogin() async {
    if (!mounted) return;

    Provider.of<ProjectProvider>(context, listen: false).initialize(userId: null);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ProjectListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
            ],
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => (v?.isEmpty ?? true) ? 'Введите email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Пароль'),
                    obscureText: true,
                    validator: (v) => (v?.isEmpty ?? true) ? 'Введите пароль' : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(_isLogin ? 'Войти' : 'Зарегистрироваться'),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _isLogin = !_isLogin;
                _error = null;
              }),
              child: Text(_isLogin ? 'Создать аккаунт' : 'Уже есть аккаунт? Войти'),
            ),
            const Divider(height: 32),
            OutlinedButton(
              onPressed: _guestLogin,
              child: const Text('Войти как гость'),
            ),
          ],
        ),
      ),
    );
  }
}
