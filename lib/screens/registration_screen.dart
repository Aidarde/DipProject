// lib/screens/registration_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegState();
}

class _RegState extends State<RegistrationScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  String? _error;

  // Простая проверка e-mail
  bool _isValidEmail(String email) {
    final pattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return pattern.hasMatch(email);
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final pass2 = _pass2Ctrl.text;

    // Валидация до обращения к Firebase
    if (email.isEmpty || pass.isEmpty || pass2.isEmpty) {
      setState(() => _error = 'Заполните все поля');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _error = 'Неверный формат e-mail');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Пароль должен быть не менее 6 символов');
      return;
    }
    if (pass != pass2) {
      setState(() => _error = 'Пароли не совпадают');
      return;
    }

    setState(() => _error = null);
    try {
      // создаём учётку
      final user = await AuthService.registerWithEmail(email, pass);
      if (user == null) throw 'Не удалось зарегистрироваться';

      // сохраняем профиль в Firestore только как user
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'email': email,
        'role': 'user',
        'branchName': null,
        'bonusPoints': 0,
      });

      // возвращаемся на экран логина
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      // выводим сообщение от Firebase (например, email-already-in-use)
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Ошибка: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: 'Пароль'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pass2Ctrl,
              decoration: const InputDecoration(labelText: 'Повторите пароль'),
              obscureText: true,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Зарегистрироваться'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
