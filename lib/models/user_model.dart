// lib/models/user_model.dart

class AppUser {
  final String uid;
  final String email;
  final String role;
  final int bonusPoints;
  final String branchName;    // теперь non-null, по умолчанию пустая строка
  final String displayName;
  final String phone;
  final String photoURL;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.bonusPoints,
    required this.branchName,
    required this.displayName,
    required this.phone,
    required this.photoURL,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'bonusPoints': bonusPoints,
      'branchName': branchName,
      'displayName': displayName,
      'phone': phone,
      'photoURL': photoURL,
    };
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'user',
      bonusPoints: (map['bonusPoints'] as num?)?.toInt() ?? 0,
      branchName: map['branchName'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      photoURL: map['photoURL'] as String? ?? '',
    );
  }
}
