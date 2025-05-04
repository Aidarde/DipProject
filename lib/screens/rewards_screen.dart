import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_styles.dart';
import '../theme/app_colors.dart';
import '../l10n/l10n_ext.dart';
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
    final uid = context.read<UserProvider>().user?.uid;
    if (uid != null) context.read<UserProvider>().loadUser(uid);
  }

  @override
  Widget build(BuildContext context) {
    final appUser = context.watch<UserProvider>().user;
    if (appUser == null) {
      return Scaffold(body: Center(child: Text(context.l10n.userNotFound)));
    }

    final uid = appUser.uid;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.rewardsTab, style: AppStyles.appBarTitle)),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (_, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final bonus = (userSnap.data?.data()?['bonusPoints'] as int?) ?? 0;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 28),
                    const SizedBox(width: 8),
                    Text(context.l10n.yourPoints(bonus), style: AppStyles.sectionTitle),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('rewards')
                      .orderBy('cost')
                      .snapshots(),
                  builder: (_, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text(context.l10n.errorLoading('${snap.error}')));
                    }

                    final rewards = snap.data!.docs;
                    if (rewards.isEmpty) {
                      return Center(
                        child: Text(context.l10n.noRewardsYet,
                            style: AppStyles.cardPrice),
                      );
                    }

                    return ListView.builder(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: rewards.length,
                      itemBuilder: (_, i) {
                        final doc   = rewards[i];
                        final data  = doc.data();

                        final title = (data['name']  as String?) ?? '–';
                        final cost  = (data['cost']  as num?)?.round() ?? 0;
                        final image = (data['image'] as String?) ?? '';
                        final can   = bonus >= cost;

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
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: image.isNotEmpty
                                    ? Image.asset(image,
                                    width: 60, height: 60, fit: BoxFit.cover)
                                    : const Icon(Icons.card_giftcard,
                                    size: 60, color: AppColors.red),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: AppStyles.cardTitle),
                                    const SizedBox(height: 4),
                                    Text(context.l10n.cost(cost),
                                        style: AppStyles.cardPrice),
                                  ],
                                ),
                              ),
                              FilledButton(
                                onPressed: can
                                    ? () async {
                                  final cart = context.read<CartProvider>();

                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .update({
                                    'bonusPoints':
                                    FieldValue.increment(-cost)
                                  });

                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .collection('rewardHistory')
                                      .add({
                                    'rewardId': doc.id,
                                    'title': title,
                                    'cost': cost,
                                    'image': image,
                                    'exchangedAt': Timestamp.now(),
                                  });

                                  cart.addRewardItemToCart(
                                      name: title,
                                      image: image,
                                      rewardId: doc.id);

                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          context.l10n.addedToCart(title)),
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
          );
        },
      ),
    );
  }
}
