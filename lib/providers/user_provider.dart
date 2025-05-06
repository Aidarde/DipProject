import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../services/fcm_service.dart';

class UserProvider with ChangeNotifier {
  AppUser? _user;
  bool    _isLoading = false;

  AppUser? get user      => _user;
  bool     get isLoading => _isLoading;

  Future<void> loadUser(String uid) async {
    _isLoading = true;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        _user = AppUser.fromMap(uid, doc.data()!);
      } else {
        _user = null;
      }

      // ← сохраняем токен
      await FCMService.saveTokenToFirestore(uid);
    } catch (e, st) {
      _user = null;
      debugPrint('UserProvider.loadUser error: $e\n$st');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
