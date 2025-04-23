import 'package:cloud_firestore/cloud_firestore.dart';

class AppOrder {
  final String id;
  final String userId;
  final String branchName;
  final List<Map<String, dynamic>> items;
  final double total;
  final DateTime createdAt;
  final String status; // ✅ новое поле

  AppOrder({
    required this.id,
    required this.userId,
    required this.branchName,
    required this.items,
    required this.total,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'branchName': branchName,
      'items': items,
      'total': total,
      'createdAt': createdAt.toIso8601String(),
      'status': status, // ✅ сохраняем статус
    };
  }

  factory AppOrder.fromMap(String id, Map<String, dynamic> map) {
    return AppOrder(
      id: id,
      userId: map['userId'] ?? '',
      branchName: map['branchName'] ?? '',
      items: List<Map<String, dynamic>>.from(map['items']),
      total: (map['total'] as num).toDouble(),
      createdAt: (map['timestamp'] as Timestamp).toDate(),
      status: map['status'] ?? 'в обработке', // ✅ получаем статус или дефолт
    );
  }
}
