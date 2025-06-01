// lib/screens/rewards_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import '../utils/google_drive_link.dart';
import '../utils/universal_image.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';
import 'cart_screen.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  @override
  void initState() {
    super.initState();
    // Предкэшируем изображения наград (уже с toDriveDirect)
    FirebaseFirestore.instance.collection('rewards').get().then((snap) {
      for (final doc in snap.docs) {
        final url = (doc['imageUrl'] as String? ?? '').toDriveDirect();
        if (url.startsWith('http')) {
          precacheImage(NetworkImage(url), context);   // ok для 1-2 КБ html не критично
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user  = context.watch<UserProvider>().user;
    final cart  = context.watch<CartProvider>();

    if (user == null) {
      return Scaffold(body: Center(child: Text(context.l10n.userNotFound)));
    }

    final uid           = user.uid;
    final bonus         = user.bonusPoints;
    final leftPoints    = (bonus - cart.rewardCostTotal).clamp(0, bonus);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.rewardsTab, style: AppStyles.appBarTitle),
        backgroundColor: AppColors.red,
      ),
      body: Column(
        children: [
          // ————— Баланс —————
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                Text(context.l10n.yourPoints(leftPoints),
                    style: AppStyles.sectionTitle),
              ],
            ),
          ),

          // ————— Список наград —————
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('rewards')
                  .orderBy('cost')
                  .snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rewards = snap.data!.docs;
                if (rewards.isEmpty) {
                  return Center(child: Text(context.l10n.noRewardsYet));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: rewards.length,
                  itemBuilder: (_, i) {
                    final data  = rewards[i].data();
                    final id    = rewards[i].id;
                    final name  = data['name']    as String? ?? '—';
                    final cost  = (data['cost']   as num?)?.round() ?? 0;
                    final raw   = data['imageUrl'] as String? ?? '';
                    final url   = raw.toDriveDirect();

                    final alreadyInCart = cart.containsReward(id);
                    final enoughPoints  = cost <= leftPoints;
                    final canExchange   = !alreadyInCart && enoughPoints;

                    final leading = url.startsWith('http')
                        ? UniversalImage(url, width: 56, height: 56, borderRadius: 8)
                        : const Icon(Icons.card_giftcard,
                        size: 56, color: Colors.red);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 6)],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(borderRadius: BorderRadius.circular(8), child: leading),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: AppStyles.cardTitle),
                                const SizedBox(height: 4),
                                Text(context.l10n.cost(cost), style: AppStyles.cardPrice),
                              ],
                            ),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: canExchange ? AppColors.red : Colors.grey,
                            ),
                            onPressed: canExchange
                                ? () async {
                              cart.addItem(
                                name:       name,
                                price:      0,
                                image:      url,
                                rewardCost: cost,
                                extra:      {'rewardId': id},
                              );

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .collection('rewardDrafts')
                                  .add({
                                'rewardId' : id,
                                'title'    : name,
                                'cost'     : cost,
                                'imageUrl' : raw,
                                'addedAt'  : FieldValue.serverTimestamp(),
                              });

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.l10n.addedToCart(name)),
                                  action: SnackBarAction(
                                    label: context.l10n.goToCart,
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const CartScreen()),
                                    ),
                                  ),
                                ),
                              );
                            }
                                : null,
                            child: Text(
                              alreadyInCart ? context.l10n.inCart : context.l10n.exchange,
                            ),
                          ),
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
