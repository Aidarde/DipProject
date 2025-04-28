import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enjoy/providers/cart_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});


  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      return const Scaffold(
        body: Center(child: Text('Пользователь не найден')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бонусы'),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userProvider.userStream(firebaseUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Ошибка загрузки пользователя'));
          }

          final userData = snapshot.data!.data();
          if (userData == null) {
            return const Center(child: Text('Пользователь не найден'));
          }

          final bonusPoints = userData['bonusPoints'] ?? 0;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Ваши баллы: $bonusPoints',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              // Сюда оставляем StreamBuilder наград как у тебя был
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('rewards')
                      .orderBy('cost')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Ошибка: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final rewards = snapshot.data!.docs;

                    if (rewards.isEmpty) {
                      return const Center(child: Text('Наград пока нет'));
                    }

                    return ListView.builder(
                      itemCount: rewards.length,
                      itemBuilder: (context, index) {
                        final rewardDoc = rewards[index];
                        final rewardData = rewardDoc.data() as Map<String, dynamic>;
                        final rewardId = rewardDoc.id;
                        final title = rewardData['name'] ?? 'Без названия';
                        final cost = rewardData['cost'] ?? 0;
                        final image = rewardData['image'] ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: ListTile(
                            leading: image.isNotEmpty
                                ? Image(image: AssetImage(image), width: 50, height: 50, fit: BoxFit.cover)
                                : const Icon(Icons.card_giftcard, size: 40),
                            title: Text(title),
                            subtitle: Text('Стоимость: $cost баллов'),
                            trailing: ElevatedButton(
                              onPressed: bonusPoints >= cost
                                  ? () => _exchangeReward(
                                context: context,
                                rewardId: rewardId,
                                title: title,
                                cost: cost,
                                image: image,
                                userId: firebaseUser.uid,
                                cartProvider: cartProvider,
                              )
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


  Future<void> _exchangeReward({
    required BuildContext context,
    required String rewardId,
    required String title,
    required int cost,
    required String image,
    required String userId,
    required CartProvider cartProvider,
  }) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

      final userSnapshot = await userRef.get();
      final userData = userSnapshot.data();
      if (userData == null) return;

      final currentPoints = userData['bonusPoints'] ?? 0;
      final newPoints = currentPoints - cost;

      if (newPoints < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Недостаточно баллов для обмена')),
        );
        return;
      }

      await userRef.update({'bonusPoints': newPoints});

      await userRef.collection('rewardHistory').add({
        'rewardId': rewardId,
        'title': title,
        'cost': cost,
        'image': image,
        'exchangedAt': Timestamp.now(),
      });

      cartProvider.addRewardItemToCart(
        name: title,
        image: image,
        rewardId: rewardId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Товар добавлен в корзину')),
      );
    } catch (e) {
      debugPrint('Ошибка обмена награды: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Произошла ошибка при обмене')),
      );
    }
  }

}