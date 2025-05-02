import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
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
    final cart = Provider.of<CartProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина', style: AppStyles.appBarTitle),
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Выберите филиал',
                border: OutlineInputBorder(),
              ),
              value: _selectedBranch,
              items: _branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (val) => setState(() => _selectedBranch = val),
            ),
          ),
          Expanded(
            child: cart.items.isEmpty
                ? const Center(child: Text('Корзина пуста'))
                : ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (ctx, i) {
                final item = cart.items[i];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(item['image'], width: 50, height: 50, fit: BoxFit.cover),
                  ),
                  title: Text(item['name'], style: AppStyles.cardTitle),
                  subtitle: Text('${item['price']} сом', style: AppStyles.cardPrice),
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
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.lightGrey)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Итого: ${cart.totalPrice} сом',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: cart.items.isEmpty || _selectedBranch == null || user == null
                  ? null
                  : () async {
                final total = cart.totalPrice;
                final earned = (total * 0.1).round();

                final orderData = {
                  'userId': user.uid,
                  'branchName': _selectedBranch!,
                  'items': cart.items,
                  'total': total,
                  'timestamp': FieldValue.serverTimestamp(),
                  'status': 'в обработке',
                };

                await FirebaseFirestore.instance.collection('orders').add(orderData);
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({'bonusPoints': FieldValue.increment(earned)});
                await Provider.of<UserProvider>(context, listen: false).loadUser(user.uid);

                cart.clearCart();

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Заказ оформлен. +$earned баллов!')),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Оформить', style: AppStyles.buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
