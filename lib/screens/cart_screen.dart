import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_styles.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _branches = ['Центральный филиал', 'Филиал на Юге', 'Филиал на Севере'];
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final user = FirebaseAuth.instance.currentUser;

    // общий итог для нижней панели
    final int total = cart.totalPrice.round();

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
                border: const OutlineInputBorder(),
              ),
              items: _branches
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              value: _selected,
              onChanged: (v) => setState(() => _selected = v),
            ),
          ),
          Expanded(
            child: cart.items.isEmpty
                ? Center(child: Text(context.l10n.cartEmpty))
                : ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (_, i) {
                final name  = cart.items[i]['name']  as String;
                final price = cart.items[i]['price'] as int;
                final image = cart.items[i]['image'] as String;

                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(image,
                        width: 50, height: 50, fit: BoxFit.cover),
                  ),
                  title: Text(name, style: AppStyles.cardTitle),
                  subtitle: Text(context.l10n.amount(price),
                      style: AppStyles.cardPrice),
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
          color: Theme.of(context).scaffoldBackgroundColor,
          border:
          Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.total(total),
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            FilledButton(
              onPressed: cart.items.isEmpty || _selected == null || user == null
                  ? null
                  : () async {
                final int earned = (total * 0.1).round();

                await FirebaseFirestore.instance
                    .collection('orders')
                    .add({
                  'userId': user.uid,
                  'branchName': _selected!,
                  'items': cart.items,
                  'total': total,
                  'timestamp': FieldValue.serverTimestamp(),
                  'status': 'в обработке',
                });

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({
                  'bonusPoints': FieldValue.increment(earned),
                });

                await context
                    .read<UserProvider>()
                    .loadUser(user.uid);

                cart.clearCart();

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          context.l10n.orderPlaced(earned))),
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
