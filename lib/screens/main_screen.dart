import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/user_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../l10n/l10n_ext.dart';

import 'home_screen.dart';
import 'orders_screen.dart';
import 'rewards_screen.dart';
import 'settings_screen.dart';
import 'cart_screen.dart';
import 'admin_screen.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      const OrdersScreen(),
      const RewardsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: pages[_index],

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.red,
        shape: const CircleBorder(),
        child: const Icon(Icons.shopping_cart),
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home),        label: context.l10n.homeTab),
          BottomNavigationBarItem(icon: const Icon(Icons.receipt_long), label: context.l10n.ordersTab),
          BottomNavigationBarItem(icon: const Icon(Icons.card_giftcard),label: context.l10n.rewardsTab),
          BottomNavigationBarItem(icon: const Icon(Icons.settings),    label: context.l10n.settingsTab),
        ],
      ),
    );
  }
}

/* -------- AUTH WRAPPER (остался здесь) ---------- */

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.data == null) return const LoginScreen();

        final uid = snap.data!.uid;
        return FutureBuilder(
          future: context.read<UserProvider>().loadUser(uid),
          builder: (_, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final role = context.read<UserProvider>().user?.role;
            return role == 'admin' ? const AdminScreen() : const MainScreen();
          },
        );
      },
    );
  }
}
