import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enjoy/screens/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  @override
  void initState() {
    super.initState();
    final uid = Provider.of<UserProvider>(context, listen: false).user?.uid;
    if (uid != null) {
      Provider.of<UserProvider>(context, listen: false).loadUser(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    if (userProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
      );
    }

    final appUser = userProvider.user;
    if (appUser == null) {
      return const Scaffold(
        body: Center(child: Text('Пользователь не найден', style: AppStyles.errorText)),
      );
    }

    final uid = appUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бонусы', style: AppStyles.appBarTitle),
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
          }
          if (!userSnap.hasData || !userSnap.data!.exists) {
            return const Center(
              child: Text('Не удалось загрузить данные пользователя', style: AppStyles.errorText),
            );
          }

          final bonusPoints = (userSnap.data!.data()!['bonusPoints'] as int?) ?? 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Ваши баллы: $bonusPoints',
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
                  builder: (context, rewardsSnap) {
                    if (rewardsSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (rewardsSnap.hasError) {
                      return Center(child: Text('Ошибка: ${rewardsSnap.error}', style: AppStyles.errorText));
                    }

                    final rewards = rewardsSnap.data!.docs;
                    if (rewards.isEmpty) {
                      return const Center(
                        child: Text('Наград пока нет', style: AppStyles.cardPrice),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: rewards.length,
                      itemBuilder: (context, index) {
                        final doc = rewards[index];
                        final data = doc.data();
                        final title = data['name'] as String? ?? 'Без названия';
                        final cost = data['cost'] as int? ?? 0;
                        final image = data['image'] as String? ?? '';
                        final canExchange = bonusPoints >= cost;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: image.isNotEmpty
                                    ? Image.asset(image, width: 60, height: 60, fit: BoxFit.cover)
                                    : const Icon(Icons.card_giftcard, size: 60, color: AppColors.primaryRed),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: AppStyles.cardTitle),
                                    const SizedBox(height: 4),
                                    Text('Стоимость: $cost баллов', style: AppStyles.cardPrice),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: canExchange
                                    ? () async {
                                  final cartProv = Provider.of<CartProvider>(context, listen: false);
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .update({'bonusPoints': FieldValue.increment(-cost)});
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
                                  cartProv.addRewardItemToCart(
                                    name: title,
                                    image: image,
                                    rewardId: doc.id,
                                  );
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Товар добавлен в корзину'),
                                      action: SnackBarAction(
                                        label: 'В корзину',
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const CartScreen()),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor:
                                  canExchange ? AppColors.primaryRed : Colors.grey.shade400,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Обменять'),
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
