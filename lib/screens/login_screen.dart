// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_styles.dart';
import '../theme/app_colors.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  String? _err;
  bool _loading = false;

  Future<void> _loginEmail() async {
    setState(() {
      _err = null;
      _loading = true;
    });
    try {
      final user = await AuthService.signInWithEmail(
        _email.text.trim(),
        _pass.text.trim(),
      );
      if (user != null) {
        await _openByRole(user.uid);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _err = e.message);
    } catch (_) {
      setState(() => _err = context.l10n.unexpectedError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginGoogle() async {
    setState(() {
      _err = null;
      _loading = true;
    });
    try {
      final user = await AuthService.signInWithGoogle();
      if (user != null) {
        await _openByRole(user.uid);
      }
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openByRole(String uid) async {
    // загрузим профиль и FCM-токен
    await context.read<UserProvider>().loadUser(uid);
    // возвращаемся на корень — AuthWrapper сам выберет Admin или Main
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).colorScheme.surface;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.login, size: 72, color: AppColors.red),
              const SizedBox(height: 16),
              Text(
                context.l10n.welcome,
                textAlign: TextAlign.center,
                style: AppStyles.headline,
              ),
              const SizedBox(height: 32),
              _field(
                controller: _email,
                label: context.l10n.email,
                fillColor: fill,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email,
                onSubmitted: (_) => _loginEmail(),
              ),
              const SizedBox(height: 16),
              _field(
                controller: _pass,
                label: context.l10n.password,
                fillColor: fill,
                keyboardType: TextInputType.text,
                prefixIcon: Icons.lock,
                obscureText: true,
                onSubmitted: (_) => _loginEmail(),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                FilledButton(
                  onPressed: _loginEmail,
                  child: Text(context.l10n.loginEmail),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.account_circle),
                  label: Text(context.l10n.loginGoogle),
                  onPressed: _loginGoogle,
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegistrationScreen(),
                    ),
                  );
                },
                child: Text(context.l10n.noAccount),
              ),
              if (_err != null) ...[
                const SizedBox(height: 12),
                Text(
                  _err!,
                  textAlign: TextAlign.center,
                  style: AppStyles.errorText,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required Color fillColor,
    required TextInputType keyboardType,
    required IconData prefixIcon,
    bool obscureText = false,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        prefixIcon: Icon(prefixIcon),
        labelText: label,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
