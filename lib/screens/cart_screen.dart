// lib/screens/cart_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_styles.dart';
import '../utils/google_drive_link.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final List<String> _branches = [
    'Центральный филиал',
    'Филиал на Юге',
    'Филиал на Севере',
  ];
  String? _selectedBranch;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final user = context.read<UserProvider>().user;
    final total = cart.totalPrice.round();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.cartTitle, style: AppStyles.appBarTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: context.l10n.chooseBranch,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              value: _selectedBranch,
              items: _branches
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedBranch = val),
            ),
          ),

          Expanded(
            child: cart.items.isEmpty
                ? Center(child: Text(context.l10n.cartEmpty))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cart.items.length,
              itemBuilder: (_, i) {
                final item     = cart.items[i];
                final name     = item['name']  as String;
                final price    = item['price'] as int;
                final rawImage = item['image'] as String;
                final url      = rawImage.toDriveDirect();

                Widget leading;
                if (url.startsWith('http')) {
                  leading = CachedNetworkImage(
                    imageUrl: url,
                    placeholder: (_, __) => SizedBox(
                      width: 50,
                      height: 50,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      size: 50,
                    ),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  );
                } else {
                  leading = Image.asset(
                    rawImage,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  );
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: leading,
                  ),
                  title: Text(name, style: AppStyles.cardTitle),
                  subtitle: Text(
                    context.l10n.amount(price),
                    style: AppStyles.cardPrice,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => cart.removeItem(i),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.total(total),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            FilledButton(
              onPressed: cart.items.isEmpty || _selectedBranch == null || user == null
                  ? null
                  : () async {
                final earned = (total * 0.1).round();
                // 1) создаём заказ
                await FirebaseFirestore.instance.collection('orders').add({
                  'userId':     user.uid,
                  'branchName': _selectedBranch!,
                  'items':      cart.items,
                  'total':      total,
                  'timestamp':  FieldValue.serverTimestamp(),
                  'status':     'в обработке',
                });
                // 2) начисляем бонусы
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({'bonusPoints': FieldValue.increment(earned)});
                // 3) обновляем провайдер
                await context.read<UserProvider>().loadUser(user.uid);
                cart.clearCart();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.orderPlaced(earned))),
                );
                Navigator.pop(context);
              },
              child: Text(context.l10n.checkout),
            ),
          ],
        ),
      ),
    );
  }
}
