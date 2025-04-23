import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  late Future<List<AppOrder>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _ordersFuture = _orderService.fetchOrders(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заказы'),
        backgroundColor: Colors.redAccent,
      ),
      body: FutureBuilder<List<AppOrder>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint('Ошибка при загрузке заказов: ${snapshot.error}');
            return const Center(child: Text('Ошибка при загрузке заказов'));
          }

          final orders = snapshot.data;
          if (orders == null || orders.isEmpty) {
            return const Center(child: Text('У вас пока нет заказов'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: ExpansionTile(
                  title: Text('Филиал: ${order.branchName}'),
                  subtitle: Text(
                    'Сумма: ${order.total} сом\n'
                        'Дата: ${order.createdAt.toLocal().toString().split('.')[0]}\n'
                        'Статус: ${order.status}',
                    style: TextStyle(
                      color: order.status == 'готов' ? Colors.green :
                      order.status == 'отменён' ? Colors.red :
                      Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),


                  children: order.items.map((item) {
                    try {
                      return ListTile(
                        title: Text(item['name'] ?? 'Без названия'),
                        subtitle: Text('${item['price'] ?? 0} сом'),
                        leading: item['image'] != null
                            ? Image.asset(
                          item['image'],
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                        )
                            : const Icon(Icons.image_not_supported),
                      );
                    } catch (e) {
                      debugPrint('Ошибка при отображении элемента заказа: $e');
                      return const ListTile(
                        title: Text('Ошибка отображения элемента'),
                      );
                    }
                  }).toList(),
                ) ,
              );
            },
          );
        },
      ),
    );
  }
}
