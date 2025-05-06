import 'package:cloud_firestore/cloud_firestore.dart';

/// Единичная позиция меню (бургер / напиток / десерт …)
class MenuItem {
  final String id;
  final String name;
  /// burger / side / drink / dessert …
  final String type;
  final int    basePrice;
  final String imageUrl;
  final bool   popular;

  MenuItem({
    required this.id,
    required this.name,
    required this.type,
    required this.basePrice,
    required this.imageUrl,
    required this.popular,
  });

  factory MenuItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return MenuItem(
      id        : d.id,
      name      : m['name'],
      type      : m['type'],
      basePrice : (m['basePrice'] as num).toInt(),
      imageUrl  : m['image'],
      popular   : m['popular'] ?? false,
    );
  }
}
