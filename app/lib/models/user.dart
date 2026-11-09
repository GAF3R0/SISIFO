enum UserRole { admin, psychologist }

class User {
  final String id; // UUID
  final String email;
  final bool emailVerified;
  final UserRole role;
  final String? passwordHash; // SHA-256

  User({
    required this.id,
    required this.email,
    this.emailVerified = false,
    required this.role,
    this.passwordHash,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'email_verified': emailVerified ? 1 : 0,
      'role': role.name,
      'password_hash': passwordHash ?? '',
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      emailVerified: (map['email_verified'] is int)
          ? (map['email_verified'] == 1)
          : (map['email_verified'] == true),
      role: (map['role'] == 'admin') ? UserRole.admin : UserRole.psychologist,
      passwordHash: map['password_hash'] as String?,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory User.fromJson(Map<String, dynamic> json) => User.fromMap(json);
}
