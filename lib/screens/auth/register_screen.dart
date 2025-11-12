import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  String _role = 'student';
  bool _isLoading = false;
  // ✅ Состояние для просмотра пароля
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    super.dispose();
  }

  // ✅ Функция для показа стильных подсказок (Snackbar)
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        // Эстетичный фон: красный для ошибок, зеленый для успеха
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        // Закругленные углы для улучшения эстетики
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(15),
      ),
    );
  }

  void _register() async {
    if (_isLoading) return;
    // Проверка валидации формы
    if (!_formKey.currentState!.validate()) return;

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
        // Успешная регистрация: Стильная подсказка
        _showSnackBar('Регистрация успешна! Проверьте вашу почту для подтверждения.', isError: false);
        Navigator.pop(context);

      }

    } on Exception catch (e) {
      if (mounted) {
        // Отображение ошибок
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
    // Регулярное выражение для строгой проверки почты
    const emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$';

    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Center(
        child: SingleChildScrollView( // Чтобы избежать переполнения при появлении клавиатуры
          padding: const EdgeInsets.all(24),
          child: Form( // Обертка для активации валидации
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Поле Полное имя с валидацией
                TextFormField(
                  controller: _fullName,
                  decoration: const InputDecoration(labelText: 'Полное имя'),
                  validator: (v) => v == null || v.isEmpty ? 'Введите ваше имя' : null,
                ),
                // Поле Email с улучшенной валидацией
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', hintText: 'taskio@example.com'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Введите Email';
                    // ✅ Проверка формата Email
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
                        // Переключает состояние видимости
                        setState(() => _isPasswordVisible = !_isPasswordVisible);
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible, // Привязка к состоянию
                  validator: (v) => v == null || v.length < 6 ? 'Пароль должен быть не менее 6 символов' : null,
                ),
                // Выбор роли
                DropdownButtonFormField<String>(
                  value: _role,
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Учащийся')),
                    DropdownMenuItem(value: 'teacher', child: Text('Преподаватель')),
                    DropdownMenuItem(value: 'leader', child: Text('Руководитель проекта')),
                  ],
                  decoration: const InputDecoration(labelText: 'Ваша роль'),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _role = v);
                    }
                  },
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(onPressed: _register, child: const Text('Зарегистрироваться')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}