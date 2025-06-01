// lib/screens/registration_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_styles.dart';
import '../theme/app_colors.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _conf = TextEditingController();
  String? _err;
  bool _loading = false;

  Future<void> _register() async {
    if (_pass.text.trim() != _conf.text.trim()) {
      setState(() => _err = context.l10n.passMismatch);
      return;
    }
    setState(() {
      _err = null;
      _loading = true;
    });
    try {
      final credential = await AuthService.registerWithEmail(
        _email.text.trim(),
        _pass.text.trim(),
      );
      final uid = credential?.user?.uid;
      if (uid != null) {
        // Загружаем в провайдер новый профиль
        await context.read<UserProvider>().loadUser(uid);
        // Возвращаемся назад — AuthWrapper сам выберет нужный экран
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        setState(() => _err = context.l10n.unexpectedError);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _err = e.message);
    } catch (_) {
      setState(() => _err = context.l10n.unexpectedError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).colorScheme.surface;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.registerTab, style: AppStyles.appBarTitle),
        backgroundColor: AppColors.red,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.app_registration, size: 72, color: AppColors.red),
              const SizedBox(height: 16),
              Text(
                context.l10n.createAccount,
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
                onSubmitted: (_) => _register(),
              ),
              const SizedBox(height: 16),
              _field(
                controller: _pass,
                label: context.l10n.password,
                fillColor: fill,
                keyboardType: TextInputType.text,
                prefixIcon: Icons.lock,
                obscureText: true,
                onSubmitted: (_) => _register(),
              ),
              const SizedBox(height: 16),
              _field(
                controller: _conf,
                label: context.l10n.confirmPassword,
                fillColor: fill,
                keyboardType: TextInputType.text,
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                onSubmitted: (_) => _register(),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                FilledButton(
                  onPressed: _register,
                  child: Text(context.l10n.register),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.alreadyHaveAccount),
                ),
              ],
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
