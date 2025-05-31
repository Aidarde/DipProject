// lib/providers/cart_provider.dart
import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
  /// Список элементов корзины.
  /// Для награды price = 0, а rewardCost > 0.
  /// { name, price, image, rewardCost }
  final List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> get items => _items;

  /// Общая сумма к оплате (без учёта баллов)
  int get totalPrice =>
      _items.fold(0, (sum, e) => sum + (e['price'] as int));

  /// Сколько бонус-баллов нужно списать за все награды
  int get rewardCostTotal =>
      _items.fold(0, (sum, e) => sum + (e['rewardCost'] as int? ?? 0));

  void addItem({
    required String name,
    required int    price,
    required String image,
    int rewardCost = 0,
  }) {
    _items.add({
      'name'       : name,
      'price'      : price,
      'image'      : image,
      'rewardCost' : rewardCost,
    });
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
