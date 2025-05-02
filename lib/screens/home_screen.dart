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

    // Промо-баннеры (в реальности можно подгружать из Firestore)
    final promotions = <String>[
      'assets/banners/promo1.png',
      'assets/banners/promo2.png',
      'assets/banners/promo3.png',
    ];

    // Популярные блюда
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
      ),
      body: ListView(
        children: <Widget>[
          // 1) Карусель промо
          SizedBox(
            height: 160,
            child: PageView(
              children: promotions.map((path) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(path, fit: BoxFit.cover),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 2) Заголовок "Популярное"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Популярное',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),

          // 3) Горизонтальный список популярных блюд
          SizedBox(
            height: 200, // увеличили высоту, чтобы избежать overflow
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: popular.length,
              itemBuilder: (ctx, i) {
                final item = popular[i];
                final name = item['name'] as String;
                final price = item['price'] as int;
                final image = item['image'] as String;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(right: 12, bottom: 4), // отступ снизу
                  child: SizedBox(
                    width: 140,
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // занимает только нужный размер
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Image.asset(image, width: 80, height: 80),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                        ),
                        Text('$price сом'),
                        const SizedBox(height: 4),
                        IconButton(
                          icon: const Icon(Icons.add_shopping_cart),
                          onPressed: () {
                            cartProvider.addItem(
                              name: name,
                              price: price,
                              image: image,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$name добавлен в корзину'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // 4) Кнопка "Смотреть всё меню"
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MenuScreen(branchName: branchName ?? ''),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Смотреть всё меню'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
