import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;
  bool _loading = false;

  Future<void> _register() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() {
        _error = 'Пароли не совпадают';
        _loading = false;
      });
      return;
    }

    try {
      final user = await AuthService.registerWithEmail(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
      );
      if (user != null) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Ошибка регистрации');
    } catch (_) {
      setState(() => _error = 'Непредвиденная ошибка');
    }

    setState(() => _loading = false);
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
              const Icon(Icons.person_add_alt_1, size: 72, color: AppColors.primaryRed),
              const SizedBox(height: 16),
              const Text(
                'Создайте аккаунт',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email),
                  labelText: 'Email',
                  labelStyle: AppStyles.inputLabel,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock),
                  labelText: 'Пароль',
                  labelStyle: AppStyles.inputLabel,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  labelText: 'Повторите пароль',
                  labelStyle: AppStyles.inputLabel,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                onPressed: _register,
                icon: const Icon(Icons.check),
                label: const Text('Зарегистрироваться'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: AppStyles.errorText,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Уже есть аккаунт? Войти',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
