import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  AppUser? _user;
  bool _isLoading = false;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;

  /// Добавляем геттер isAdmin
  bool get isAdmin => _user?.isAdmin ?? false;

  Future<void> loadUser(String uid) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (snapshot.exists) {
        final data = snapshot.data()!;
        _user = AppUser.fromMap(snapshot.id, data);
      } else {
        _user = null;
      }
    } catch (e) {
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }
}
