// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../services/fcm_service.dart';

class UserProvider with ChangeNotifier {
  AppUser? _user;
  bool     _isLoading = false;

  AppUser? get user       => _user;
  bool     get isLoading  => _isLoading;

  Future<void> loadUser(String uid) async {


    _isLoading = true;
    Future.microtask(notifyListeners);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      _user = snap.exists ? AppUser.fromMap(uid, snap.data()!) : null;

      // сохраняем FCM-токен
      await FCMService.saveTokenToFirestore(uid);
    } catch (e, st) {
      debugPrint('UserProvider.loadUser → $e\n$st');
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> updateUser(Map<String, dynamic> fields) async {
    if (_user == null) return;

    final uid = _user!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update(fields);


    _user = AppUser.fromMap(
      uid,
      {
        ..._user!.toMap(),
        ...fields,
      },
    );
    notifyListeners();
  }


  Future<void> updateDisplayName(String name) =>
      updateUser({'displayName': name});

  Future<void> updatePhone(String phone) =>
      updateUser({'phone': phone});
}
