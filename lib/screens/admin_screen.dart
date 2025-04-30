// lib/screens/admin_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../services/auth_service.dart';  // для выхода

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);
    final appUser = userProv.user;

    // Если по какой-то причине профиль ещё не загрузился
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

    // Поток только тех заказов, что относятся к этому branchName
    final ordersStream = FirebaseFirestore.instance
        .collection('orders')
        .where('branchName', isEqualTo: branchName)
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Админ: $branchName'),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.signOut();
              // после signOut AuthWrapper автоматически покажет LoginScreen
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ordersStream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Ошибка при загрузке: ${snap.error}'));
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Нет заказов для вашего филиала'));
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
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: ExpansionTile(
                  title: Text('Заказ #${docs[i].id}'),
                  subtitle: Text(
                    'Сумма: $total сом\n'
                        'Статус: ${status.toString().toUpperCase()}\n'
                        'Дата: ${ts != null ? ts.toLocal().toString().split('.')[0] : '—'}',
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
    );
  }
}
