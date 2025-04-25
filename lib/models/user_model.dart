class AppUser {
  final String uid;
  final String? name;
  final int bonusPoints;
  final bool isAdmin;

  AppUser({
    required this.uid,
    this.name,
    this.bonusPoints = 0,
    this.isAdmin = false,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      name: data['name'],
      bonusPoints: data['bonusPoints'] ?? 0,
      isAdmin: data['role'] == 'admin',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bonusPoints': bonusPoints,
      'isAdmin': isAdmin,
    };
  }
}
