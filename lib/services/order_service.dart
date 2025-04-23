import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final CollectionReference ordersCollection =
  FirebaseFirestore.instance.collection('orders');

  Future<List<AppOrder>> fetchOrders(String userId) async {
    try {
      final querySnapshot = await ordersCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true) // ← исправлено
          .get();

      print('Найдено заказов: ${querySnapshot.docs.length}');

      return querySnapshot.docs.map((doc) {
        print('Документ: ${doc.data()}');
        return AppOrder.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Ошибка при получении заказов: $e');
      rethrow;
    }
  }
}
