// lib/screens/home_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/branch_provider.dart';
import '../providers/cart_provider.dart';
import '../utils/google_drive_link.dart';
import '../screens/menu_screen.dart';
import '../screens/cart_screen.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_styles.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // префетчим все «popular»
    FirebaseFirestore.instance
        .collection('menu')
        .where('popular', isEqualTo: true)
        .get()
        .then((snap) {
      for (var d in snap.docs) {
        final url = (d['image'] as String? ?? '').toDriveDirect();
        if (url.startsWith('http')) {
          precacheImage(CachedNetworkImageProvider(url), context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final branch = context.watch<BranchProvider>().selectedBranch ?? '';
    final cart   = context.read<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.red,
        title: Text(context.l10n.homeTab, style: AppStyles.appBarTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          const SizedBox(height: 12),
          // баннеры
          SizedBox(
            height: 160,
            child: PageView(
              controller: PageController(viewportFraction: .9),
              children: ['promo1', 'promo2', 'promo3']
                  .map((p) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/banners/$p.png', fit: BoxFit.cover),
                ),
              ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(context.l10n.popular, style: AppStyles.sectionTitle),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('menu')
                  .where('popular', isEqualTo: true)
                  .snapshots(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snap.data!.docs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (_, i) {
                    final data = snap.data!.docs[i].data();
                    final name  = data['name']  as String? ?? '';
                    final price = (data['basePrice'] as num?)?.round() ?? 0;
                    final raw   = data['image'] as String? ?? '';
                    final url   = raw.toDriveDirect();

                    return _PopularCard(
                      name: name,
                      price: price,
                      imageUrl: url,
                      onAdd: () {
                        cart.addItem(name: name, price: price, image: url);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(context.l10n.addedToCart(name))));
                      },
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
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => MenuScreen(branchName: branch))),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.red,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
        child: const Icon(Icons.shopping_cart),
      ),
    );
  }
}

class _PopularCard extends StatelessWidget {
  final String name;
  final int price;
  final String imageUrl;
  final VoidCallback onAdd;
  const _PopularCard({required this.name, required this.price, required this.imageUrl, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 6, offset: const Offset(0,4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              placeholder: (_, __) => Image.asset('assets/placeholder.png', width: 72, height: 72, fit: BoxFit.cover),
              errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 72),
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 8),
            Text(name, style: AppStyles.cardTitle),
            Text('$price ${context.l10n.som}', style: AppStyles.cardPrice),
            const SizedBox(height: 6),
            ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                minimumSize: const Size(40, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.add_shopping_cart, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
