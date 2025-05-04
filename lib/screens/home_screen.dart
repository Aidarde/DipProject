import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/branch_provider.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_styles.dart';
import 'menu_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final branchName = context.watch<BranchProvider>().selectedBranch;
    final cart       = context.read<CartProvider>();

    final promos = [
      'assets/banners/promo1.png',
      'assets/banners/promo2.png',
      'assets/banners/promo3.png'
    ];

    final popular = [
      {'name': 'Чизбургер',     'price': 150, 'image': 'assets/images/burger.png'},
      {'name': 'Картофель фри', 'price': 100, 'image': 'assets/images/fries.png'},
      {'name': 'Кола',          'price':  80, 'image': 'assets/images/cola.png'},
    ];

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.homeTab, style: AppStyles.appBarTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SizedBox(height: 12),
          _PromoCarousel(promos: promos),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(context.l10n.popular, style: AppStyles.sectionTitle),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: popular.length,
              itemBuilder: (_, i) {
                final name  = popular[i]['name']  as String;
                final price = popular[i]['price'] as int;
                final image = popular[i]['image'] as String;

                return _PopularCard(
                  name: name,
                  price: price,
                  image: image,
                  onAdd: () {
                    cart.addItem(name: name, price: price, image: image);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.addedToCart(name))),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: FilledButton.icon(
              icon: const Icon(Icons.restaurant_menu),
              label: Text(context.l10n.viewMenu, style: AppStyles.buttonText),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MenuScreen(branchName: branchName ?? '')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------- helper widgets ---------- */

class _PromoCarousel extends StatelessWidget {
  final List<String> promos;
  const _PromoCarousel({required this.promos});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: PageController(viewportFraction: .9),
        itemCount: promos.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(promos[i], fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class _PopularCard extends StatelessWidget {
  final String name;
  final int    price;
  final String image;
  final VoidCallback onAdd;

  const _PopularCard({
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 6, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Image.asset(image, width: 72, height: 72),
          const SizedBox(height: 8),
          Text(name, style: AppStyles.cardTitle),
          Text('${price} ${context.l10n.som}', style: AppStyles.cardPrice),
          const SizedBox(height: 6),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(40, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onAdd,
            child: const Icon(Icons.add_shopping_cart, size: 18),
          ),
        ],
      ),
    );
  }
}
