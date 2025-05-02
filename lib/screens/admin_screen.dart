import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';  // для выхода

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String statusFilter = 'все';

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ожидается':
        return Colors.grey;
      case 'в обработке':
        return Colors.orange;
      case 'готов':
        return Colors.green;
      case 'выдан':
        return Colors.blue;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);
    final appUser = userProv.user;

    if (userProv.isLoading || appUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final branchName = appUser.branchName;
    if (branchName == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Панель администратора')),
        body: const Center(child: Text('Не указан филиал для этого администратора')),
      );
    }

    final ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .where('branchName', isEqualTo: branchName)
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель администратора'),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.redAccent.shade100,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.store, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Филиал: $branchName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Text('Фильтр: ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: statusFilter,
                  items: const [
                    DropdownMenuItem(value: 'все', child: Text('Все')),
                    DropdownMenuItem(value: 'ожидается', child: Text('Ожидается')),
                    DropdownMenuItem(value: 'в обработке', child: Text('В обработке')),
                    DropdownMenuItem(value: 'готов', child: Text('Готов')),
                    DropdownMenuItem(value: 'выдан', child: Text('Выдан')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      statusFilter = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: ordersStream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Ошибка: ${snap.error}'));
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs.where((doc) {
                  final status = (doc['status'] ?? '').toString().toLowerCase();
                  return statusFilter == 'все' || status == statusFilter;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('Нет заказов по выбранному фильтру'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data();
                    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
                    final status = data['status'] ?? '—';
                    final total = data['total'] ?? 0;
                    final ts = (data['timestamp'] as Timestamp?)?.toDate();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        title: Text('Заказ #${docs[i].id}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Сумма: $total сом'),
                            Row(
                              children: [
                                const Text('Статус: '),
                                Text(
                                  status.toString().toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: getStatusColor(status),
                                  ),
                                ),
                              ],
                            ),
                            Text('Дата: ${ts != null ? ts.toLocal().toString().split('.')[0] : '—'}'),
                          ],
                        ),
                        children: [
                          ...items.map((it) => ListTile(
                            leading: it['image'] != null
                                ? Image.asset(it['image'], width: 32, height: 32)
                                : const Icon(Icons.fastfood),
                            title: Text(it['name']),
                            trailing: Text('${it['price']} сом'),
                          )),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                const Text('Изменить статус:'),
                                const SizedBox(width: 12),
                                DropdownButton<String>(
                                  value: status,
                                  items: const [
                                    DropdownMenuItem(value: 'ожидается', child: Text('Ожидается')),
                                    DropdownMenuItem(value: 'в обработке', child: Text('В обработке')),
                                    DropdownMenuItem(value: 'готов', child: Text('Готов')),
                                    DropdownMenuItem(value: 'выдан', child: Text('Выдан')),
                                  ],
                                  onChanged: (newStatus) {
                                    if (newStatus != null) {
                                      FirebaseFirestore.instance
                                          .collection('orders')
                                          .doc(docs[i].id)
                                          .update({'status': newStatus});
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
          ),
        ],
      ),
    );
  }
}