import 'package:enjoy/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/cart_provider.dart';



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
      appBar: AppBar(title: const Text('Корзина'), backgroundColor: Colors.redAccent),
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
              items: _branches
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
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
                  leading: Image.asset(item['image'], width: 50),
                  title: Text(item['name']),
                  subtitle: Text('${item['price']} сом'),
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
        color: Colors.white,
        padding: const EdgeInsets.all(16),
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

                // Сохраняем заказ
                await FirebaseFirestore.instance
                    .collection('orders')
                    .add(orderData);

                // Начисляем бонусы
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({'bonusPoints': FieldValue.increment(earned)});

                // Обновляем UserProvider
                await Provider.of<UserProvider>(context, listen: false)
                    .loadUser(user.uid);

                cart.clearCart();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Заказ оформлен. +$earned баллов!')),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Оформить'),
            ),
          ],
        ),
      ),
    );
  }
}

