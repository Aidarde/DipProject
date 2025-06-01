// lib/providers/cart_provider.dart
import 'package:flutter/material.dart';

/// Провайдер корзины. Хранит как обычные товары, так и бонус-товары.
///
/// *Для бонуса* `price == 0`, а `rewardCost > 0`.
/// Каждый элемент имеет произвольное поле `extra` для служебных данных
/// (например, rewardId, выбранные опции и т.п.).
class CartProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => List.unmodifiable(_items);

  /// Общая сумма к оплате, *не учитывая* бонус-баллы.
  int get totalPrice =>
      _items.fold<int>(0, (sum, e) => sum + (e['price'] as int? ?? 0));

  /// Сколько баллов будет списано за все бонус-товары.
  int get rewardCostTotal =>
      _items.fold<int>(0, (sum, e) => sum + (e['rewardCost'] as int? ?? 0));

  /// Добавление позиции.
  ///
  /// [price] — цена в сомах (0 для бонуса).
  /// [rewardCost] — требуемые баллы (0 для обычного товара).
  /// [extra] — произвольные данные (например `{'rewardId': doc.id}`).
  void addItem({
    required String name,
    required int price,
    required String image,
    int rewardCost = 0,
    Map<String, dynamic>? extra,
  }) {
    _items.add({
      'name': name,
      'price': price,
      'image': image,
      'rewardCost': rewardCost,
      if (extra != null) ...extra,
    });
    notifyListeners();
  }

  /// Проверка: есть ли уже бонус-товар с таким id в корзине.
  bool containsReward(String rewardId) =>
      _items.any((e) => e['rewardId'] == rewardId);

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
