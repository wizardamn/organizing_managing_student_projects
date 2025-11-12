import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;
  // ✅ Состояние для просмотра пароля
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // ✅ Функция для показа стильных подсказок
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(15),
      ),
    );
  }

  void _login() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _auth.signIn(_email.text.trim(), _password.text.trim());
      if (!mounted) return;

    } on Exception catch (e) {
      if (mounted) {
        // ✅ Используем новую функцию для стильных подсказок
        _showSnackBar(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Регулярное выражение для проверки почты:
    const emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$';

    return Scaffold(
      appBar: AppBar(title: const Text('Авторизация')),
      body: Center(
        child: SingleChildScrollView( // ✅ Добавлено для избежания переполнения
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', hintText: 'taskio@example.com'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Введите Email';
                    // ✅ Улучшенная проверка Email
                    if (!RegExp(emailRegex).hasMatch(v)) return 'Некорректный формат Email';
                    return null;
                  },
                ),
                // ✅ Поле Пароль с кнопкой просмотра
                TextFormField(
                  controller: _password,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    hintText: 'минимум 6 символов',
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() => _isPasswordVisible = !_isPasswordVisible);
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible, // ✅ Привязка к состоянию
                  validator: (v) => v == null || v.length < 6 ? 'Пароль должен быть не менее 6 символов' : null,
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Войти')
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('Зарегистрироваться'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}