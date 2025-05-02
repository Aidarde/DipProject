import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:enjoy/theme/app_colors.dart';
import 'package:enjoy/theme/app_styles.dart';

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
        title: const Text('Мои заказы', style: AppStyles.appBarTitle),
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка загрузки: ${snapshot.error}', style: AppStyles.errorText));
          }

          final orders = snapshot.data?.docs ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Text(
                'У вас пока нет заказов.',
                style: AppStyles.cardPrice,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data();
              final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
              final branchName = order['branchName'] ?? 'Неизвестно';
              final total = order['total'] ?? 0;
              final status = order['status'] ?? 'Неизвестно';
              final timestamp = (order['timestamp'] as Timestamp?)?.toDate();

              final color = _statusColor(status);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    'Филиал: $branchName',
                    style: AppStyles.cardTitle,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Сумма: $total сом', style: AppStyles.cardPrice),
                      Text(
                        'Статус: ${status.toUpperCase()}',
                        style: AppStyles.cardPrice.copyWith(color: color, fontWeight: FontWeight.w600),
                      ),
                      if (timestamp != null)
                        Text(
                          'Дата: ${_formatDate(timestamp)}',
                          style: AppStyles.cardPrice.copyWith(fontSize: 12),
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
                        title: Text(item['name'], style: AppStyles.cardTitle.copyWith(fontSize: 15)),
                        subtitle: Text('${item['price']} сом', style: AppStyles.cardPrice),
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
        return AppColors.success;
      case 'выдан':
        return AppColors.greyText;
      default:
        return Colors.black;
    }
  }
}
