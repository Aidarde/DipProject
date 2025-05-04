import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_styles.dart';
import '../theme/app_colors.dart';
import 'cart_screen.dart';

class MenuScreen extends StatelessWidget {
  final String branchName;
  const MenuScreen({super.key, required this.branchName});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    // Пример меню ‒ обычно придёт из Firestore / API
    final items = [
      {'name': 'Чизбургер',    'price': 150, 'image': 'assets/images/burger.png'},
      {'name': 'Картофель фри','price': 100, 'image': 'assets/images/fries.png'},
      {'name': 'Кола',         'price':  80, 'image': 'assets/images/cola.png'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.menuTitle, style: AppStyles.appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) {
          // безопасно кастуем значения
          final name  = items[i]['name']  as String;
          final price = items[i]['price'] as int;
          final image = items[i]['image'] as String;

          return Card(
            elevation: 3,
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(image, width: 56, height: 56, fit: BoxFit.cover),
              ),
              title: Text(name, style: AppStyles.cardTitle),
              subtitle: Text(context.l10n.amount(price), style: AppStyles.cardPrice),
              trailing: IconButton(
                icon: const Icon(Icons.add_shopping_cart),
                onPressed: () {
                  cart.addItem(name: name, price: price, image: image);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.addedToCart(name))),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
