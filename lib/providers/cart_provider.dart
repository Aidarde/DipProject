import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  void addItem({
    required String name,
    required int price,
    required String image,
    String? rewardId,
  }) {
    _items.add({
      'name': name,
      'price': price,
      'image': image,
      if (rewardId != null) 'rewardId': rewardId, // Для отличия бонусов
    });
    notifyListeners();
  }


  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  double get totalPrice =>
      _items.fold(0.0, (sum, item) => sum + (item['price'] as num).toDouble());


  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  void addRewardItemToCart({
    required String name,
    required String image,
    required String rewardId,
  }) {
    _items.add({
      'name': name,
      'image': image,
      'price': 0, // бонусный товар бесплатно
      'rewardId': rewardId, // пометка, что это бонус
    });
    notifyListeners();
  }

}
