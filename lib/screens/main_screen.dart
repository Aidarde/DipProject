import 'package:flutter/material.dart';
import 'package:enjoy/screens/home_screen.dart';
import 'package:enjoy/screens/orders_screen.dart';
import 'package:enjoy/screens/rewards_screen.dart';
import 'package:enjoy/screens/settings_screen.dart';
import 'package:enjoy/screens/cart_screen.dart';
import 'package:enjoy/theme/app_colors.dart';
import 'package:enjoy/theme/app_styles.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const OrdersScreen(),
    const RewardsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _pages[_selectedIndex],

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          );
        },
        backgroundColor: AppColors.primaryRed,
        child: const Icon(Icons.shopping_cart),
        shape: const CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primaryRed,
        unselectedItemColor: AppColors.greyText,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.cardBackground,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Заказы',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Бонусы',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}