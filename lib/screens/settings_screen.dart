import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      _nameCtrl.text = user.displayName ?? '';
      _phoneCtrl.text = user.phone ?? '';
    }
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
    final data = {
      'displayName': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
    };
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update(data);
      await Provider.of<UserProvider>(context, listen: false).loadUser(uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль сохранён')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Личный кабинет', style: AppStyles.appBarTitle),
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// Аватар
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.lightGrey,
              backgroundImage: (user.photoURL != null && user.photoURL!.isNotEmpty)
                  ? NetworkImage(user.photoURL!)
                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
            ),
            const SizedBox(height: 16),

            /// Email
            Text(
              user.email ?? 'Нет адреса почты',
              style: AppStyles.cardPrice,
            ),
            const SizedBox(height: 32),

            /// Имя
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Имя',
                labelStyle: AppStyles.inputLabel,
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.greyText),
                filled: true,
                fillColor: AppColors.lightGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            /// Телефон
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Телефон',
                labelStyle: AppStyles.inputLabel,
                prefixIcon: const Icon(Icons.phone, color: AppColors.greyText),
                filled: true,
                fillColor: AppColors.lightGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 28),

            /// Кнопка сохранить
            _saving
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save),
              label: const Text('Сохранить', style: AppStyles.buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 40),
            Divider(color: AppColors.lightGrey, thickness: 1),
            const SizedBox(height: 20),

            /// Кнопка выйти
            ElevatedButton.icon(
              onPressed: () async {
                await AuthService.signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Выйти из аккаунта', style: AppStyles.buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greyText,
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
}
