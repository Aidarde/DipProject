class AppUser {
  final String uid;
  final String email;
  final String role;
  final int bonusPoints;

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.bonusPoints = 0,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      bonusPoints: map['bonusPoints'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'bonusPoints': bonusPoints,
    };
  }
}
