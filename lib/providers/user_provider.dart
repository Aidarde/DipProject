// lib/providers/user_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../services/fcm_service.dart'; // содержит FcmTokenHelper

class UserProvider with ChangeNotifier {
  AppUser? _user;
  bool _isLoading = false;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;

  /// Загружает профиль пользователя из Firestore и сохраняет его FCM-токен.
  Future<void> loadUser(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1) Скачиваем документ users/{uid}
      final docSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (docSnap.exists) {
        // 2) Строим модель из uid и данных
        final data = docSnap.data()!;
        _user = AppUser.fromMap(uid, data);
      } else {
        _user = null;
      }

      // 3) Сохраняем FCM-токен в Firestore
      await FcmTokenHelper.saveTokenToFirestore(uid);
    } catch (e, st) {
      // При ошибке сбрасываем пользователя и логируем
      _user = null;
      debugPrint('UserProvider.loadUser error: $e\n$st');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
