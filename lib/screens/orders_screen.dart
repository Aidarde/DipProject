// lib/screens/orders_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n_ext.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../utils/google_drive_link.dart';
import '../utils/universal_image.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(body: Center(child: Text(context.l10n.userNotFound)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.ordersTab, style: AppStyles.appBarTitle),
        backgroundColor: AppColors.red,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                context.l10n.errorLoading('${snap.error}'),
                style: AppStyles.errorText,
              ),
            );
          }

          final orders = snap.data?.docs ?? [];
          if (orders.isEmpty) {
            return Center(child: Text(context.l10n.noOrdersYet, style: AppStyles.cardPrice));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (_, i) {
              final data   = orders[i].data();
              final items  = List<Map<String, dynamic>>.from(data['items'] ?? []);
              final branch = data['branchName'] as String? ?? '';
              final total  = (data['total'] as num?)?.round() ?? 0;
              final status = (data['status'] as String? ?? '').toLowerCase();
              final ts     = (data['timestamp'] as Timestamp?)?.toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(context.l10n.branch(branch), style: AppStyles.cardTitle),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(context.l10n.amount(total), style: AppStyles.cardPrice),
                      Text(
                        context.l10n.status(_localizedStatus(context, status)),
                        style: AppStyles.cardPrice.copyWith(color: _statusColor(status)),
                      ),
                      if (ts != null)
                        Text(
                          context.l10n.date(_fmt(ts)),
                          style: AppStyles.cardPrice.copyWith(fontSize: 12),
                        ),
                    ],
                  ),
                  children: items.map((item) {
                    final name     = item['name']  as String? ?? '';
                    final price    = (item['price'] as num?)?.round() ?? 0;
                    final rawImage = item['image'] as String? ?? '';
                    final url      = rawImage.toDriveDirect();

                    final leading = url.startsWith('http')
                        ? UniversalImage(url, width: 56, height: 56, borderRadius: 8)
                        : Image.asset(rawImage, width: 40, height: 40, fit: BoxFit.cover);

                    return ListTile(
                      leading: ClipRRect(borderRadius: BorderRadius.circular(8), child: leading),
                      title: Text(name, style: AppStyles.cardTitle.copyWith(fontSize: 15)),
                      subtitle: Text(context.l10n.amount(price), style: AppStyles.cardPrice),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- helpers --------------------------------------------------------------

  /// Перевод системного статуса в человекочитаемый (локализованный) текст.
  String _localizedStatus(BuildContext ctx, String status) {
    switch (status) {
      case 'ожидается':   return ctx.l10n.pending;
      case 'в обработке': return ctx.l10n.inProcess;
      case 'готов':       return ctx.l10n.ready;
      case 'выдан':       return ctx.l10n.delivered;
      default:            return status; // если появится новый статус
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Color _statusColor(String status) {
    switch (status) {
      case 'ожидается':   return Colors.orange;
      case 'в обработке': return Colors.blue;
      case 'готов':       return AppColors.success;
      case 'выдан':       return AppColors.darkGreyText;
      default:            return Colors.black;
    }
  }
}
