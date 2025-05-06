import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
  /// один элемент корзины
  /// { name, price, image }
  final List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> get items => _items;

  int get totalPrice =>
      _items.fold(0, (sum, e) => sum + (e['price'] as int));

  void addItem({
    required String name,
    required int    price,
    required String image,
  }) {
    _items.add({
      'name' : name,
      'price': price,
      'image': image,
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
