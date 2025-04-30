import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static Future<User?> signInWithGoogle() async {
    try {
      GoogleSignIn googleSignIn;

      if (kIsWeb) {
        googleSignIn = GoogleSignIn(
          clientId: '929559084297-3m9pt1ahroujlv5alf0ust32ga4t2jtq.apps.googleusercontent.com',
        );
      } else {
        googleSignIn = GoogleSignIn();
      }

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Ошибка входа через Google: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        // Только на мобильных платформах
        await GoogleSignIn().signOut();
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Ошибка при выходе из аккаунта: $e');
    }
  }
}
