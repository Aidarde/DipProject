// lib/screens/order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n/l10n_ext.dart';
import '../theme/app_styles.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  // Вспомогательный метод для форматирования DateTime в строку
  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd.$mm.$yy $hh:$mi';
  }

  @override
  Widget build(BuildContext context) {
    final orderId = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.ordersTab, style: AppStyles.appBarTitle),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .get(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return Center(
              child: Text(
                context.l10n.errorLoading('order not found'),
                style: AppStyles.errorText,
              ),
            );
          }

          final data   = snap.data!.data()!;
          final items  = List<Map<String, dynamic>>.from(data['items'] ?? []);
          final branch = data['branchName'] as String? ?? '';
          final total  = (data['total'] as num?)?.toInt() ?? 0;
          final status = data['status'] as String? ?? '';
          final ts     = (data['timestamp'] as Timestamp?)?.toDate();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.branch(branch), style: AppStyles.sectionTitle),
                const SizedBox(height: 8),
                Text(context.l10n.amount(total), style: AppStyles.cardPrice),
                Text(context.l10n.status(status), style: AppStyles.cardPrice),
                if (ts != null) ...[
                  const SizedBox(height: 4),
                  // Передаём уже отформатированную строку!
                  Text(
                    context.l10n.date(_formatDate(ts)),
                    style: AppStyles.cardPrice,
                  ),
                ],
                const Divider(height: 32),
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, i) {
                      final it = items[i];
                      return ListTile(
                        leading: it['image'] != null
                            ? Image.asset(
                          it['image'] as String,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        )
                            : null,
                        title: Text(
                          it['name'] as String,
                          style: AppStyles.cardTitle,
                        ),
                        trailing: Text(
                          '${it['price']} ${context.l10n.som}',
                          style: AppStyles.cardPrice,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
