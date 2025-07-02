import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.auth.signUp(
          email: _emailC.text.trim(), password: _passC.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Проверьте почту для подтверждения')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() =>
      _error = e is AuthException ? e.message : 'Ошибка регистрации');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(
        appBar: AppBar(title: const Text('Регистрация')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
            ],
            Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  controller: _emailC,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                  (v?.isEmpty ?? true)
                      ? 'Введите email'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passC,
                  decoration: const InputDecoration(
                      labelText: 'Пароль (мин.6)'),
                  obscureText: true,
                  validator: (v) =>
                  (v?.length ?? 0) < 6
                      ? 'Минимум 6 символов'
                      : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _register,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Зарегистрироваться')),
              ]),
            )
          ]),
        ),
      );
}