import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Пользователь не найден')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заказы'),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
          }

          final orders = snapshot.data?.docs ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Text(
                'У вас пока нет заказов.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data();
              final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
              final branchName = order['branchName'] ?? 'Неизвестно';
              final total = order['total'] ?? 0;
              final status = order['status'] ?? 'Неизвестно';
              final timestamp = (order['timestamp'] as Timestamp?)?.toDate();

              final color = _statusColor(status);

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    'Филиал: $branchName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Сумма: $total сом', style: const TextStyle(fontSize: 14)),
                      Text('Статус: ${status.toUpperCase()}', style: TextStyle(color: color, fontSize: 14)),
                      if (timestamp != null)
                        Text(
                          'Дата: ${_formatDate(timestamp)}',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                    ],
                  ),
                  children: [
                    ...items.map(
                          (item) => ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(item['image'], width: 40, height: 40, fit: BoxFit.cover),
                        ),
                        title: Text(item['name'], style: const TextStyle(fontSize: 15)),
                        subtitle: Text('${item['price']} сом', style: const TextStyle(color: Colors.grey)),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ожидается':
        return Colors.orange;
      case 'в обработке':
        return Colors.blue;
      case 'готов':
        return Colors.green;
      case 'выдан':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}
