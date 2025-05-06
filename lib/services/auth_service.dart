// lib/services/auth_service.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  /// Войти по email+пароль
  static Future<UserCredential?> signInWithEmail(
      String email, String password) {
    return FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
  }

  /// Зарегистрироваться по email+пароль
  static Future<UserCredential?> registerWithEmail(
      String email, String password) {
    return FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
  }

  /// Войти через Google (Web: popup, Mobile: GoogleSignIn)
  static Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      // для web используем popup
      final provider = GoogleAuthProvider();
      return await FirebaseAuth.instance.signInWithPopup(provider);
    } else {
      // для мобильных — через google_sign_in плагин
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // пользователь отменил вход
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await FirebaseAuth.instance.signInWithCredential(credential);
    }
  }

  /// Выйти (и из FirebaseAuth, и из GoogleSignIn на мобильных)
  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
  }
}
