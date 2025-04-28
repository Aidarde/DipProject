import 'package:enjoy/providers/user_provider.dart';
import 'package:enjoy/services/order_service.dart';
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
                final cart = Provider.of<CartProvider>(context, listen: false);
                final branchProvider = Provider.of<BranchProvider>(context, listen: false);
                final userProvider = Provider.of<UserProvider>(context, listen: false);

                final success = await OrderService.placeOrder(context, cart, branchProvider, userProvider);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Заказ оформлен и бонусы начислены!')),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ошибка при оформлении заказа')),
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
