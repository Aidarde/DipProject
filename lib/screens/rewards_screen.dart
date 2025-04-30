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
    // Загружаем пользователя при инициализации
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
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Ваши баллы: $bonusPoints', style: const TextStyle(fontSize: 18)),
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
                      itemCount: rewards.length,
                      itemBuilder: (context, index) {
                        final doc = rewards[index];
                        final data = doc.data();
                        final title = data['name'] as String? ?? 'Без названия';
                        final cost = data['cost'] as int? ?? 0;
                        final image = data['image'] as String? ?? '';
                        final canExchange = bonusPoints >= cost;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: ListTile(
                            leading: image.isNotEmpty
                                ? Image.asset(image, width: 40, height: 40)
                                : const Icon(Icons.card_giftcard, size: 40),
                            title: Text(title),
                            subtitle: Text('Стоимость: $cost баллов'),
                            trailing: ElevatedButton(
                              onPressed: canExchange
                                  ? () async {
                                // 1) Захват провайдера ДО await
                                final cartProv = Provider.of<CartProvider>(context, listen: false);

                                // 2) Списываем баллы и пишем историю
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

                                // 3) Добавляем в корзину (без нового Provider.of)
                                cartProv.addRewardItemToCart(
                                  name: title,
                                  image: image,
                                  rewardId: doc.id,
                                );
                                print('⚙️ Cart after add: ${cartProv.items}');

                                // 4) Показать SnackBar с кнопкой перехода
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
                              child: const Text('Обменять'),
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
