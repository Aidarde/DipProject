import 'package:enjoy/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_styles.dart';
import 'main_screen.dart';
import 'admin_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  String? _err;
  bool _loading = false;

  Future<void> _loginEmail() async {
    setState(() { _err = null; _loading = true; });
    try {
      final user = await AuthService.signInWithEmail(_email.text.trim(), _pass.text.trim());
      if (user != null) await _openByRole(user.uid);
    } on FirebaseAuthException catch (e) {
      _err = e.message;
    } catch (_) {
      _err = context.l10n.unexpectedError;
    }
    setState(() => _loading = false);
  }

  Future<void> _loginGoogle() async {
    final user = await AuthService.signInWithGoogle();
    if (user != null) await _openByRole(user.uid);
  }

  Future<void> _openByRole(String uid) async {
    await context.read<UserProvider>().loadUser(uid);
    final role = context.read<UserProvider>().user?.role;
    final screen = role == 'admin' ? const AdminScreen() : const MainScreen();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.login, size: 72, color: AppColors.red),
              const SizedBox(height: 16),
              Text(context.l10n.welcome, textAlign: TextAlign.center, style: AppStyles.headline),
              const SizedBox(height: 32),
              _field(_email, context.l10n.email, surface, TextInputType.emailAddress),
              const SizedBox(height: 16),
              _field(_pass, context.l10n.password, surface, TextInputType.text, obscure: true, submit: _loginEmail),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton(onPressed: _loginEmail, child: Text(context.l10n.loginEmail)),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.account_circle),
                label: Text(context.l10n.loginGoogle),
                onPressed: _loginGoogle,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationScreen())),
                child: Text(context.l10n.noAccount),
              ),
              if (_err != null) ...[
                const SizedBox(height: 12),
                Text(_err!, textAlign: TextAlign.center, style: AppStyles.errorText),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, Color fill,
      TextInputType type, {bool obscure = false, void Function()? submit}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: type,
      onSubmitted: (_) => submit?.call(),
      decoration: InputDecoration(
        prefixIcon: Icon(obscure ? Icons.lock : Icons.email),
        labelText: label,
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
