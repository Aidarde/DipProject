// lib/screens/login_screen.dart
import 'package:enjoy/screens/admin_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import 'registration_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String? _error;

  Future<void> _loginEmail() async {
    setState(() => _error=null);
    try {
      final user = await AuthService.signInWithEmail(_email.text.trim(), _pass.text);
      if (user!=null) {
        await Provider.of<UserProvider>(context, listen:false).loadUser(user.uid);
        final role = Provider.of<UserProvider>(context, listen: false).user?.role;
        if (role == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
        }

      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Ошибка входа');
    } catch (e) {
      setState(() => _error = 'Непредвиденная ошибка');
    }

  }

  Future<void> _loginGoogle() async {
    final user = await AuthService.signInWithGoogle();
    if (user!=null) {
      await Provider.of<UserProvider>(context, listen:false).loadUser(user.uid);
      final role = Provider.of<UserProvider>(context, listen: false).user?.role;
      if (role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          // Вместо mainAxisSize: MainAxisSize.center используем mainAxisAlignment
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Пароль'),
              // чтобы по нажатию «Enter» сразу пытаться логиниться
              onSubmitted: (_) => _loginEmail(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loginEmail,
              child: const Text('Войти по Email'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loginGoogle,
              icon: const Icon(Icons.login),
              label: const Text('Войти через Google'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                );
              },
              child: const Text('Нет аккаунта? Зарегистрироваться'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

}
