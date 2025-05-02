import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enjoy/providers/cart_provider.dart';
import 'package:enjoy/providers/branch_provider.dart';
import 'package:enjoy/screens/menu_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final branchProvider = Provider.of<BranchProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final branchName = branchProvider.selectedBranch;

    final promotions = <String>[
      'assets/banners/promo1.png',
      'assets/banners/promo2.png',
      'assets/banners/promo3.png',
    ];

    final popular = <Map<String, Object>>[
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
        title: const Text('Главная'),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: <Widget>[
          const SizedBox(height: 12),

          // Карусель
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

          // Популярное
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Популярное',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
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
                final name = item['name'] as String;
                final price = item['price'] as int;
                final image = item['image'] as String;

                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 12),
                      Image.asset(image, width: 72, height: 72),
                      const SizedBox(height: 8),
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('$price сом', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 6),
                      ElevatedButton(
                        onPressed: () {
                          cartProvider.addItem(
                            name: name,
                            price: price,
                            image: image,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$name добавлен в корзину')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
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
              },
            ),
          ),

          const SizedBox(height: 32),

          // Кнопка меню
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
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text(
                'Смотреть всё меню',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
