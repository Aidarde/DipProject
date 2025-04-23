import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  AppUser? _user;

  AppUser? get user => _user;

  Future<void> loadUser(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      _user = AppUser.fromMap(doc.id, doc.data()!);
      notifyListeners();
    }
  }

  bool get isAdmin => _user?.role == 'admin';

  int get bonusPoints => _user?.bonusPoints ?? 0;
}
