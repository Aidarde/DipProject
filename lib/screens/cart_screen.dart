import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/branch_provider.dart';


class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина'),
        backgroundColor: Colors.redAccent,
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text('Корзина пуста'))
          : ListView.builder(
        itemCount: cart.items.length,
        itemBuilder: (context, index) {
          final item = cart.items[index];
          return ListTile(
            leading: Image.asset(item['image'], width: 50),
            title: Text(item['name']),
            subtitle: Text('${item['price']} сом'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                cart.removeItem(index);
              },
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey[200],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Итого: ${cart.totalPrice} сом',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () async {
                if (cart.items.isEmpty) return;

                final user = FirebaseAuth.instance.currentUser;
                final branchName = Provider.of<BranchProvider>(context, listen: false).selectedBranch;

                if (user == null || branchName == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ошибка: пользователь или филиал не найден')),
                  );
                  return;
                }

                final orderData = {
                  'userId': user.uid,
                  'branchName': branchName,
                  'items': cart.items,
                  'total': cart.totalPrice,
                  'timestamp': FieldValue.serverTimestamp(),
                  'status': 'в обработке', // ✅ добавили статус
                };


                  try {
                    await FirebaseFirestore.instance.collection('orders').add(orderData);
                    cart.clearCart();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Заказ оформлен успешно')),
                    );
                    Navigator.pop(context); // возвращаемся назад
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка при оформлении заказа: $e')),
                    );
                  }
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
