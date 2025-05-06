import 'package:enjoy/services/fcm_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_styles.dart';
import '../l10n/l10n_ext.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool  _saving     = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<UserProvider>().user;
    _nameCtrl.text  = u?.displayName ?? '';
    _phoneCtrl.text = u?.phone       ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'displayName': _nameCtrl.text.trim(),
        'phone':       _phoneCtrl.text.trim(),
      });
      await context.read<UserProvider>().loadUser(uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.saveError(e.toString()))),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProv  = context.watch<ThemeProvider>();
    final localeProv = context.watch<LocaleProvider>();
    final user       = context.watch<UserProvider>().user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final surface = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsTab, style: AppStyles.appBarTitle),
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: surface,
              backgroundImage: (user.photoURL?.isNotEmpty ?? false)
                  ? NetworkImage(user.photoURL!)
                  : const AssetImage('assets/default_avatar.png')
              as ImageProvider,
            ),
            const SizedBox(height: 16),
            Text(
              user.email ?? context.l10n.noEmail,
              style: AppStyles.cardPrice,
            ),
            const SizedBox(height: 32),

            // Имя
            _buildInput(_nameCtrl, context.l10n.name),
            const SizedBox(height: 16),

            // Телефон
            _buildInput(
              _phoneCtrl,
              context.l10n.phone,
              TextInputType.phone,
            ),
            const SizedBox(height: 28),

            // Сохранить
            _saving
                ? const CircularProgressIndicator()
                : FilledButton.icon(
              icon: const Icon(Icons.save),
              label: Text(context.l10n.save, style: AppStyles.buttonText),
              onPressed: _saveProfile,
            ),

            const SizedBox(height: 40),
            Divider(color: Theme.of(context).dividerColor),
            const SizedBox(height: 20),

            // Тёмная тема
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.dark_mode),
                  const SizedBox(width: 12),
                  Text(context.l10n.darkMode, style: AppStyles.cardTitle),
                ]),
                Switch(
                  value: themeProv.isDarkMode,
                  onChanged: (_) => themeProv.toggleTheme(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Выбор языка
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.language),
                  const SizedBox(width: 12),
                  Text(context.l10n.language, style: AppStyles.cardTitle),
                ]),
                DropdownButton<Locale>(
                  value: localeProv.locale,
                  items: const [
                    DropdownMenuItem(
                      value: Locale('ru'),
                      child: Text('Русский'),
                    ),
                    DropdownMenuItem(
                      value: Locale('ky'),
                      child: Text('Кыргызча'),
                    ),
                  ],
                  onChanged: (loc) {
                    if (loc != null) {
                      localeProv.setLocale(loc);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Выйти из аккаунта
            ElevatedButton.icon(
              onPressed: () async {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  await FCMService.deleteToken(uid);
                }
                await AuthService.signOut();
              },
              icon: const Icon(Icons.logout),
              label: Text(context.l10n.logout),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
      TextEditingController controller,
      String label, [
        TextInputType type = TextInputType.text,
      ]) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
