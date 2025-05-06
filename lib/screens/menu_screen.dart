// lib/screens/menu_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_styles.dart';
import '../theme/app_colors.dart';
import '../utils/network_image.dart';
import '../utils/google_drive_link.dart';
import 'cart_screen.dart';

class MenuScreen extends StatelessWidget {
  final String branchName;
  const MenuScreen({Key? key, required this.branchName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.red,
        title: Text(context.l10n.menuTitle, style: AppStyles.appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('menu')
            .orderBy('basePrice')
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                context.l10n.errorLoading('${snap.error}'),
                style: AppStyles.errorText,
              ),
            );
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(context.l10n.menuEmpty, style: AppStyles.cardPrice),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data     = docs[i].data();
              final name     = data['name']      as String? ?? '-';
              final rawPrice = data['basePrice'] as num?    ?? 0;
              final price    = rawPrice.round();
              final rawImage = data['image']     as String? ?? '';
              final imageUrl = rawImage.toDriveDirect();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 6)],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: networkImage(imageUrl, width: 56, height: 56),
                  ),
                  title: Text(name, style: AppStyles.cardTitle),
                  subtitle: Text('$price ${context.l10n.som}', style: AppStyles.cardPrice),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_shopping_cart, color: AppColors.red),
                    onPressed: () {
                      cart.addItem(name: name, price: price, image: imageUrl);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.l10n.addedToCart(name))),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
