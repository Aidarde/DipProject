// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static FirebaseAuth _auth = FirebaseAuth.instance;

  // Google Sign-In
  static Future<User?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final cred = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return (await _auth.signInWithCredential(cred)).user;
  }

  // Email/Password регистрация
  static Future<User?> registerWithEmail(String email, String pass) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: pass);
    return cred.user;
  }

  // Email/Password вход
  static Future<User?> signInWithEmail(String email, String pass) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: pass);
    return cred.user;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }
}
