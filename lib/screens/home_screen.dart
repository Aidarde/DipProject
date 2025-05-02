import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enjoy/providers/cart_provider.dart';
import 'package:enjoy/providers/branch_provider.dart';
import 'package:enjoy/screens/menu_screen.dart';
import 'package:enjoy/theme/app_colors.dart';
import 'package:enjoy/theme/app_styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final branchProvider = Provider.of<BranchProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final branchName = branchProvider.selectedBranch;

    final promotions = [
      'assets/banners/promo1.png',
      'assets/banners/promo2.png',
      'assets/banners/promo3.png',
    ];

    final popular = [
      {
        'name': 'Чизбургер',
        'price': 150,
        'image': 'assets/images/burger.png',
      },
      {
        'name': 'Картофель фри',
        'price': 100,
        'image': 'assets/images/fries.png',
      },
      {
        'name': 'Кола',
        'price': 80,
        'image': 'assets/images/cola.png',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        title: const Text('Главная', style: AppStyles.appBarTitle),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: <Widget>[
          const SizedBox(height: 12),

          // Промо-баннеры
          SizedBox(
            height: 160,
            child: PageView.builder(
              itemCount: promotions.length,
              controller: PageController(viewportFraction: 0.9),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(promotions[index], fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Популярные товары
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Популярное',
              style: AppStyles.sectionTitle,
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: popular.length,
              itemBuilder: (ctx, i) {
                final item = popular[i];
                return _PopularItemCard(
                  name: item['name'] as String,
                  price: item['price'] as int,
                  image: item['image'] as String,
                  onAdd: () {
                    cartProvider.addItem(
                      name: item['name'] as String,
                      price: item['price'] as int,
                      image: item['image'] as String,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item['name']} добавлен в корзину')),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // Кнопка "Смотреть меню"
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MenuScreen(branchName: branchName ?? ''),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Смотреть всё меню', style: AppStyles.buttonText),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularItemCard extends StatelessWidget {
  final String name;
  final int price;
  final String image;
  final VoidCallback onAdd;

  const _PopularItemCard({
    required this.name,
    required this.price,
    required this.image,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 12),
          Image.asset(image, width: 72, height: 72),
          const SizedBox(height: 8),
          Text(name, style: AppStyles.cardTitle),
          Text('$price сом', style: AppStyles.cardPrice),
          const SizedBox(height: 6),
          ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(40, 36),
              padding: EdgeInsets.zero,
            ),
            child: const Icon(Icons.add_shopping_cart, size: 18),
          ),
        ],
      ),
    );
  }
}
