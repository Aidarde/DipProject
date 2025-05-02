import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'package:enjoy/screens/cart_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class MenuScreen extends StatefulWidget {
  final String branchName;
  const MenuScreen({super.key, required this.branchName});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final List<Map<String, dynamic>> menuItems = [
    {'name': 'Чизбургер', 'price': 150, 'image': 'assets/images/burger.png'},
    {'name': 'Картофель фри', 'price': 100, 'image': 'assets/images/fries.png'},
    {'name': 'Кола', 'price': 80, 'image': 'assets/images/cola.png'},
  ];

  void addToCart(Map<String, dynamic> item) {
    Provider.of<CartProvider>(context, listen: false).addItem(
      name: item['name'],
      price: item['price'],
      image: item['image'],
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item['name']} добавлен в корзину')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        title: const Text('Меню', style: AppStyles.appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(item['image'], width: 56, height: 56, fit: BoxFit.cover),
              ),
              title: Text(item['name'], style: AppStyles.cardTitle),
              subtitle: Text('${item['price']} сом', style: AppStyles.cardPrice),
              trailing: IconButton(
                icon: const Icon(Icons.add_shopping_cart),
                onPressed: () => addToCart(item),
              ),
            ),
          );
        },
      ),
    );
  }
}
