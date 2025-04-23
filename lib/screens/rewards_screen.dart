import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

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
                    final reward = rewards[index];
                    final rewardData = reward.data() as Map<String, dynamic>;

                    final title = rewardData['name'];
                    final image = rewardData['image'];
                    final cost = rewardData['cost'];

                    final canRedeem = (user.bonusPoints ?? 0) >= cost;

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Image.asset(image, width: 50),
                            title: Text(title),
                            subtitle: Text('Стоимость: $cost баллов'),
                          ),
                          ElevatedButton(
                            onPressed: canRedeem
                                ? () async {
                              final uid = user.uid;

                              try {
                                // 1. Списываем баллы
                                final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
                                await userDoc.update({
                                  'bonusPoints': FieldValue.increment(-cost),
                                });

                                // 2. Записываем обмен
                                await FirebaseFirestore.instance.collection('exchanges').add({
                                  'userId': uid,
                                  'rewardId': reward.id,
                                  'rewardTitle': title,
                                  'cost': cost,
                                  'timestamp': FieldValue.serverTimestamp(),
                                });

                                // 3. Обновляем пользователя
                                await userProvider.loadUser(uid);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Вы обменяли "$title"!')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Ошибка при обмене: $e')),
                                );
                              }
                            }
                                : null,
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
      ),
    );
  }
}
