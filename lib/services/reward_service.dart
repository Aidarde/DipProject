import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reward_item.dart';

class RewardService {
  static Future<List<RewardItem>> fetchRewards() async {
    final snapshot = await FirebaseFirestore.instance.collection('rewards').get();
    return snapshot.docs
        .map((doc) => RewardItem.fromMap(doc.id, doc.data()))
        .toList();
  }
}
