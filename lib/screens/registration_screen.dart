import 'package:enjoy/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_styles.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  final _conf  = TextEditingController();
  String? _err;
  bool _loading = false;

  Future<void> _register() async {
    setState(() { _err = null; _loading = true; });
    if (_pass.text != _conf.text) {
      _err = context.l10n.passMismatch;
      setState(() => _loading = false);
      return;
    }
    try {
      final user = await AuthService.registerWithEmail(_email.text.trim(), _pass.text.trim());
      if (user != null && mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _err = e.message;
    } catch (_) {
      _err = context.l10n.unexpectedError;
    }
    setState(() => _loading = false);
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
              const Icon(Icons.person_add_alt_1, size: 72, color: AppColors.red),
              const SizedBox(height: 16),
              Text(context.l10n.createAccount, textAlign: TextAlign.center, style: AppStyles.headline),
              const SizedBox(height: 32),
              _field(_email, context.l10n.email, surface, TextInputType.emailAddress),
              const SizedBox(height: 16),
              _field(_pass, context.l10n.password, surface, TextInputType.text, obscure: true),
              const SizedBox(height: 16),
              _field(_conf, context.l10n.repeatPassword, surface, TextInputType.text, obscure: true),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton.icon(onPressed: _register, icon: const Icon(Icons.check), label: Text(context.l10n.register)),
              if (_err != null) ...[
                const SizedBox(height: 16),
                Text(_err!, textAlign: TextAlign.center, style: AppStyles.errorText),
              ],
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.haveAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, Color fill, TextInputType type,
      {bool obscure = false}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: type,
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
