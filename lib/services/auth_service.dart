// lib/services/auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  /// Войти по email+пароль
  static Future<UserCredential?> signInWithEmail(
      String email, String password) {
    return FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
  }

  /// Зарегистрироваться по email+пароль.
  /// После создания аккаунта сразу пишем в Firestore документ:
  ///   role: 'user', branchName: '', bonusPoints: 0 и т. д.
  static Future<UserCredential?> registerWithEmail(
      String email, String password) async {
    final cred = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    final user = cred.user;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': email,
        'displayName': '',
        'phone': '',
        'role': 'user',
        'branchName': '',
        'bonusPoints': 0,
        'photoURL': '',
      });
    }
    return cred;
  }

  /// Войти через Google. Если впервые – создаём документ в Firestore с полями по умолчанию.
  static Future<UserCredential?> signInWithGoogle() async {
    late UserCredential cred;

    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      cred = await FirebaseAuth.instance.signInWithPopup(provider);
    } else {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      cred = await FirebaseAuth.instance.signInWithCredential(credential);
    }

    final user = cred.user;
    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        await docRef.set({
          'email': user.email ?? '',
          'displayName': user.displayName ?? '',
          'phone': user.phoneNumber ?? '',
          'role': 'user',
          'branchName': '',
          'bonusPoints': 0,
          'photoURL': user.photoURL ?? '',
        });
      }
    }
    return cred;
  }

  /// Выйти из FirebaseAuth и (на мобильных) GoogleSignIn
  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
  }
}
