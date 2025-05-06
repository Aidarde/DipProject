// lib/screens/menu_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../utils/google_drive_link.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_styles.dart';
import '../theme/app_colors.dart';
import 'cart_screen.dart';

class MenuScreen extends StatefulWidget {
  final String branchName;
  const MenuScreen({Key? key, required this.branchName}) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  void initState() {
    super.initState();
    // Prefetch всех картинок меню (делается один раз)
    FirebaseFirestore.instance.collection('menu').get().then((snap) {
      for (var d in snap.docs) {
        final raw = d['image'] as String? ?? '';
        final url = raw.toDriveDirect();
        if (url.startsWith('http')) {
          precacheImage(CachedNetworkImageProvider(url), context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.menuTitle, style: AppStyles.appBarTitle),
        backgroundColor: AppColors.red,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('menu').orderBy('name').snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text(context.l10n.noRewardsYet));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data();
              final name  = data['name'] as String? ?? '';
              final price = (data['basePrice'] as num?)?.round() ?? 0;
              final raw   = data['image'] as String? ?? '';
              final url   = raw.toDriveDirect();

              final pic = raw.startsWith('http')
                  ? CachedNetworkImage(
                imageUrl: url,
                placeholder: (_, __) =>
                    Image.asset('assets/placeholder.png', width: 56, height: 56, fit: BoxFit.cover),
                errorWidget: (_, __, ___) =>
                const Icon(Icons.broken_image, size: 56),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              )
                  : Image.asset(raw, width: 56, height: 56, fit: BoxFit.cover);

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: pic),
                  title: Text(name, style: AppStyles.cardTitle),
                  subtitle: Text('$price ${context.l10n.som}', style: AppStyles.cardPrice),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_shopping_cart),
                    onPressed: () {
                      cart.addItem(name: name, price: price, image: url);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(context.l10n.addedToCart(name))));
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.red,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
        child: const Icon(Icons.shopping_cart),
      ),
    );
  }
}
