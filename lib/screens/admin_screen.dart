// lib/screens/admin_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final CollectionReference ordersRef =
  FirebaseFirestore.instance.collection('orders');

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await ordersRef.doc(orderId).update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель администратора'),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersRef.orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Ошибка при загрузке заказов'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(child: Text('Нет заказов'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;

              final items = List<Map<String, dynamic>>.from(data['items']);
              final status = data['status'] ?? 'ожидается';
              final branch = data['branchName'] ?? '—';
              final total = data['total'] ?? 0;
              final timestamp = data['timestamp'] as Timestamp?;
              final createdAt = timestamp?.toDate();

              return Card(
                margin: const EdgeInsets.all(10),
                child: ExpansionTile(
                  title: Text('Филиал: $branch'),
                  subtitle: Text(
                    'Сумма: $total сом\nСтатус: ${status.toString().toUpperCase()}\nДата: ${createdAt?.toLocal().toString().split('.')[0] ?? ''}',
                  ),
                  children: [
                    ...items.map((item) => ListTile(
                      title: Text(item['name']),
                      subtitle: Text('${item['price']} сом'),
                      leading: Image.asset(item['image'], width: 40),
                    )),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const Text('Изменить статус:'),
                          const SizedBox(width: 10),
                          DropdownButton<String>(
                            value: status,
                            items: const [
                              DropdownMenuItem(value: 'ожидается', child: Text('Ожидается')),
                              DropdownMenuItem(value: 'в обработке', child: Text('В обработке')),
                              DropdownMenuItem(value: 'готов', child: Text('Готов')),
                              DropdownMenuItem(value: 'выдан', child: Text('Выдан')),
                            ],
                            onChanged: (newValue) {
                              if (newValue != null) {
                                updateOrderStatus(doc.id, newValue);
                              }
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
