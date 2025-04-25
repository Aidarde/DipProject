import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enjoy/providers/cart_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  @override
  void initState() {
    super.initState();

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final uid = userProvider.user?.uid;
    if (uid != null) {
      userProvider.loadUser(uid); // обновляем данные пользователя при входе
    }
  }

  @override
  Widget build(BuildContext context) {

    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бонусы'),
        backgroundColor: Colors.redAccent,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Ваши баллы: ${user.bonusPoints}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rewards')
                  .orderBy('cost')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Ошибка при загрузке наград: ${snapshot.error}');
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
                    final title = rewardData['name'] ?? 'Без названия';
                    final cost = rewardData['cost'] ?? 0;
                    final image = rewardData['image'] ?? '';
                    final rewardId = rewardDoc.id;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        leading: image.isNotEmpty
                            ? Image(image:AssetImage(image), width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.card_giftcard, size: 40),
                        title: Text(title),
                        subtitle: Text('Стоимость: $cost баллов'),
                        trailing: ElevatedButton(
                          onPressed: userProvider.user!.bonusPoints >= cost
                              ? () async {
                            await _exchangeReward(context, rewardId, title, cost, image);
                          }
                              : null,
                          child: const Text('Обменять'),
                        ),
                      ),
                    );
                  },
                )
                ;
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exchangeReward(BuildContext context, String rewardId, String title, int cost, String image) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null) return;

    try {
      // Обновляем баллы пользователя
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userDoc.update({'bonusPoints': user.bonusPoints - cost});

      // Сохраняем информацию об обмене
      await FirebaseFirestore.instance.collection('rewardHistory').add({
        'userId': user.uid,
        'rewardId': rewardId,
        'title': title,
        'cost': cost,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Добавляем товар в корзину
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.addItem(
        name: title,
        price: 0,
        image: image,
        rewardId: rewardId,
      );
      // добавляем как бонусный товар

      // Обновляем данные пользователя
      await userProvider.loadUser(user.uid);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Товар успешно обменян и добавлен в корзину')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при обмене: $e')),
      );
    }
  }


}
