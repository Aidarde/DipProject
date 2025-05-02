import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enjoy/screens/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/cart_provider.dart';

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final appUser = userProvider.user;
    if (appUser == null) {
      return const Scaffold(body: Center(child: Text('Пользователь не найден')));
    }
    final uid = appUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бонусы'),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!userSnap.hasData || !userSnap.data!.exists) {
            return const Center(child: Text('Не удалось загрузить данные пользователя'));
          }

          final bonusPoints = (userSnap.data!.data()!['bonusPoints'] as int?) ?? 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Ваши баллы: $bonusPoints',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('rewards').orderBy('cost').snapshots(),
                  builder: (context, rewardsSnap) {
                    if (rewardsSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (rewardsSnap.hasError) {
                      return Center(child: Text('Ошибка: ${rewardsSnap.error}'));
                    }

                    final rewards = rewardsSnap.data!.docs;
                    if (rewards.isEmpty) {
                      return const Center(child: Text('Наград пока нет'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: rewards.length,
                      itemBuilder: (context, index) {
                        final doc = rewards[index];
                        final data = doc.data();
                        final title = data['name'] as String? ?? 'Без названия';
                        final cost = data['cost'] as int? ?? 0;
                        final image = data['image'] as String? ?? '';
                        final canExchange = bonusPoints >= cost;

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: image.isNotEmpty
                                      ? Image.asset(image, width: 60, height: 60, fit: BoxFit.cover)
                                      : const Icon(Icons.card_giftcard, size: 60),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text('Стоимость: $cost баллов',
                                          style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
                                    canExchange ? Colors.redAccent : Colors.grey.shade400,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Обменять'),
                                ),
                              ],
                            ),
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