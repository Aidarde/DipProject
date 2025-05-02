import 'package:enjoy/screens/admin_screen.dart';
import 'package:enjoy/screens/registration_screen.dart';
import 'package:enjoy/screens/main_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String? _error;
  bool _loading = false;

  Future<void> _loginEmail() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final user = await AuthService.signInWithEmail(
        _email.text.trim(),
        _pass.text.trim(),
      );
      if (user != null) {
        await Provider.of<UserProvider>(context, listen: false).loadUser(user.uid);
        final role = Provider.of<UserProvider>(context, listen: false).user?.role;
        final screen = (role == 'admin') ? const AdminScreen() : const MainScreen();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => screen));
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Ошибка входа');
    } catch (_) {
      setState(() => _error = 'Непредвиденная ошибка');
    }

    setState(() => _loading = false);
  }

  Future<void> _loginGoogle() async {
    final user = await AuthService.signInWithGoogle();
    if (user != null) {
      await Provider.of<UserProvider>(context, listen: false).loadUser(user.uid);
      final role = Provider.of<UserProvider>(context, listen: false).user?.role;
      final screen = (role == 'admin') ? const AdminScreen() : const MainScreen();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.login, size: 72, color: AppColors.primaryRed),
              const SizedBox(height: 16),
              const Text(
                'Добро пожаловать!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _email,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email),
                  labelText: 'Email',
                  labelStyle: AppStyles.inputLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pass,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock),
                  labelText: 'Пароль',
                  labelStyle: AppStyles.inputLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onSubmitted: (_) => _loginEmail(),
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _loginEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Войти по Email', style: AppStyles.buttonText),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loginGoogle,
                icon: const Icon(Icons.account_circle),
                label: const Text('Войти через Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                  );
                },
                child: const Text(
                  'Нет аккаунта? Зарегистрироваться',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: AppStyles.errorText,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}