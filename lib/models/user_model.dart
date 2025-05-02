import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String role;
  final int bonusPoints;
  final String? branchName;

  // Новые поля для SettingsScreen:
  final String? displayName;
  final String? phone;
  final String? photoURL;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.bonusPoints,
    this.branchName,
    this.displayName,
    this.phone,
    this.photoURL,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'bonusPoints': bonusPoints,
      if (branchName != null)   'branchName': branchName,
      if (displayName != null)  'displayName': displayName,
      if (phone != null)        'phone': phone,
      if (photoURL != null)     'photoURL': photoURL,
    };
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'user',
      bonusPoints: (map['bonusPoints'] as num?)?.toInt() ?? 0,
      branchName: map['branchName'] as String?,
      displayName: map['displayName'] as String?,
      phone: map['phone'] as String?,
      photoURL: map['photoURL'] as String?,
    );
  }
}
