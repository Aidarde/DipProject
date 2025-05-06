// lib/screens/rewards_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../providers/cart_provider.dart';
import '../l10n/l10n_ext.dart';
import '../theme/app_styles.dart';
import '../theme/app_colors.dart';
import '../utils/google_drive_link.dart';
import 'cart_screen.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({Key? key}) : super(key: key);

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  @override
  void initState() {
    super.initState();

    // Префетчим все картинки из коллекции rewards
    FirebaseFirestore.instance
        .collection('rewards')
        .get()
        .then((snap) {
      if (!mounted) return;
      for (var doc in snap.docs) {
        final raw = doc.data()['imageUrl'] as String? ?? '';
        final url = raw.toDriveDirect();
        if (url.startsWith('http')) {
          precacheImage(CachedNetworkImageProvider(url), context);
        }
      }
    }).catchError((e) {
      debugPrint('Rewards prefetch error: $e');
    });


    final uid = context.read<UserProvider>().user?.uid;
    if (uid != null) {
      context.read<UserProvider>().loadUser(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUser = context.watch<UserProvider>().user;
    if (appUser == null) {
      return Scaffold(
        body: Center(child: Text(context.l10n.userNotFound)),
      );
    }
    final uid = appUser.uid;
    final bonus = appUser.bonusPoints;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.rewardsTab, style: AppStyles.appBarTitle),
        backgroundColor: AppColors.red,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                Text(
                  context.l10n.yourPoints(bonus),
                  style: AppStyles.sectionTitle,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('rewards')
                  .orderBy('cost')
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
                final rewards = snap.data!.docs;
                if (rewards.isEmpty) {
                  return Center(
                    child: Text(
                      context.l10n.noRewardsYet,
                      style: AppStyles.cardPrice,
                    ),
                  );
                }
                return ListView.builder(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: rewards.length,
                  itemBuilder: (_, i) {
                    final doc  = rewards[i];
                    final data = doc.data();
                    final title = data['name']    as String? ?? '–';
                    final cost  = (data['cost']   as num?)?.round() ?? 0;
                    final raw   = data['imageUrl'] as String? ?? '';
                    final url   = raw.toDriveDirect();
                    final can   = bonus >= cost;

                    final Widget icon = url.startsWith('http')
                        ? CachedNetworkImage(
                      imageUrl: url,
                      placeholder: (_, __) => Image.asset(
                        'assets/placeholder.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                      errorWidget: (_, __, ___) =>
                      const Icon(Icons.broken_image, size: 60),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                        : const Icon(Icons.card_giftcard,
                        size: 60, color: Colors.red);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(.05),
                              blurRadius: 6,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: icon,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: AppStyles.cardTitle),
                                const SizedBox(height: 4),
                                Text(
                                  context.l10n.cost(cost),
                                  style: AppStyles.cardPrice,
                                ),
                              ],
                            ),
                          ),
                          FilledButton(
                            onPressed: can
                                ? () async {
                              final cart = context.read<CartProvider>();
                              // списываем баллы
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .update({
                                'bonusPoints':
                                FieldValue.increment(-cost),
                              });
                              // логируем историю обмена
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .collection('rewardHistory')
                                  .add({
                                'rewardId':    doc.id,
                                'title':       title,
                                'cost':        cost,
                                'imageUrl':    raw,
                                'exchangedAt': FieldValue.serverTimestamp(),
                              });
                              // кладём товар в корзину (цена = 0)
                              cart.addItem(
                                name:  title,
                                price: 0,
                                image: url,
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                  Text(context.l10n.addedToCart(title)),
                                  action: SnackBarAction(
                                    label: context.l10n.goToCart,
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                          const CartScreen()),
                                    ),
                                  ),
                                ),
                              );
                            }
                                : null,
                            child: Text(context.l10n.exchange),
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
