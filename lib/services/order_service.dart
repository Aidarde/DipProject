import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/user_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/branch_provider.dart';
import 'package:flutter/material.dart';

class OrderService {
  static Future<bool> placeOrder(BuildContext context, CartProvider cart, BranchProvider branchProvider, UserProvider userProvider) async {
    final user = FirebaseAuth.instance.currentUser;
    final branchName = branchProvider.selectedBranch;

    if (user == null || branchName == null) {
      return false;
    }

    final orderData = {
      'userId': user.uid,
      'branchName': branchName,
      'items': cart.items,
      'total': cart.totalPrice,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'в обработке',
    };

    try {
      await FirebaseFirestore.instance.collection('orders').add(orderData);

      final earnedPoints = (cart.totalPrice * 0.1).round();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'bonusPoints': FieldValue.increment(earnedPoints),
      });

      await userProvider.loadUser(user.uid);

      cart.clearCart();

      return true;
    } catch (e) {
      debugPrint('Ошибка оформления заказа: $e');
      return false;
    }
  }
}
