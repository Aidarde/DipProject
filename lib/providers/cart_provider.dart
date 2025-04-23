import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  void addItem(Map<String, dynamic> item) {
    _items.add(item);
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
}
