// lib/screens/order_detail_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/google_drive_link.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_styles.dart';
import '../theme/app_colors.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({Key? key}) : super(key: key);

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
        backgroundColor: AppColors.red,
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
          final total  = (data['total'] as num?)?.round() ?? 0;
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
                      final it       = items[i];
                      final name     = it['name']  as String? ?? '';
                      final price    = (it['price'] as num?)?.round() ?? 0;
                      final rawImage = it['image'] as String? ?? '';
                      final url      = rawImage.toDriveDirect();

                      Widget leading;
                      if (url.startsWith('http')) {
                        leading = CachedNetworkImage(
                          imageUrl: url,
                          placeholder: (_, __) => Image.asset(
                            'assets/placeholder.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                          errorWidget: (_, __, ___) =>
                          const Icon(Icons.broken_image, size: 40),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        );
                      } else {
                        leading = Image.asset(
                          rawImage,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        );
                      }

                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: leading,
                        ),
                        title: Text(name, style: AppStyles.cardTitle.copyWith(fontSize: 15)),
                        trailing: Text(
                          '${price} ${context.l10n.som}',
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
