import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  AppUser? _user;
  bool _isLoading = false;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAdmin => _user?.isAdmin ?? false;

  Future<void> loadUser(String uid, {bool forceReload = false}) async {
    if (!forceReload && _user != null && _user!.uid == uid) return; // предотвращаем повторную загрузку

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

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
  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String userId) {
    return FirebaseFirestore.instance.collection('users').doc(userId).snapshots();
  }
}