// lib/models/user_model.dart
class AppUser {
  final String uid;
  final String email;
  final String role;       // "user" или "admin"
  final String? branchName;
  final int bonusPoints;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.branchName,
    this.bonusPoints = 0,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
    uid: uid,
    email: map['email'] ?? '',
    role: map['role'] ?? 'user',
    branchName: map['branchName'],
    bonusPoints: map['bonusPoints'] as int? ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'email': email,
    'role': role,
    'branchName': branchName,
    'bonusPoints': bonusPoints,
  };
}
