// lib/screens/orders_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/google_drive_link.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import '../l10n/l10n_ext.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text(context.l10n.userNotFound)),
      );
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
            return Center(
              child: Text(context.l10n.noOrdersYet, style: AppStyles.cardPrice),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (_, i) {
              final data   = orders[i].data();
              final items  = List<Map<String, dynamic>>.from(data['items'] ?? []);
              final branch = data['branchName'] as String?  ?? '';
              final total  = (data['total']     as num?)?.round()  ?? 0;
              final status = data['status']     as String? ?? '';
              final ts     = (data['timestamp'] as Timestamp?)?.toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
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
                        context.l10n.status(status),
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

                    Widget leading;
                    if (url.startsWith('http')) {
                      leading = CachedNetworkImage(
                        imageUrl: url,
                        placeholder: (_, __) => SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      );
                    } else {
                      leading = Image.asset(rawImage, width: 40, height: 40, fit: BoxFit.cover);
                    }

                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: leading,
                      ),
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

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year} '
          '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ожидается':    return Colors.orange;
      case 'в обработке':  return Colors.blue;
      case 'готов':        return AppColors.success;
      case 'выдан':        return AppColors.darkGreyText;
      default:             return Colors.black;
    }
  }
}
