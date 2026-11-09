class Psychologist {
  final String id; // UUID, matches User.id
  final String fullName;
  final String email;
  final String licenseNumber;
  final String specialty;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool active;

  Psychologist({
    required this.id,
    required this.fullName,
    required this.email,
    required this.licenseNumber,
    required this.specialty,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.active = true,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'license_number': licenseNumber,
      'specialty': specialty,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'active': active ? 1 : 0,
    };
  }

  factory Psychologist.fromMap(Map<String, dynamic> map) {
    return Psychologist(
      id: map['id'] as String,
      fullName: (map['full_name'] ?? map['fullName'] ?? '') as String,
      email: map['email'] as String? ?? '',
      licenseNumber: (map['license_number'] ?? map['licenseNumber'] ?? '') as String,
      specialty: map['specialty'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'].toString())
          : (map['createdAt'] != null
              ? (map['createdAt'] is DateTime ? map['createdAt'] : DateTime.parse(map['createdAt'].toString()))
              : DateTime.now()),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'].toString())
          : (map['updatedAt'] != null
              ? (map['updatedAt'] is DateTime ? map['updatedAt'] : DateTime.parse(map['updatedAt'].toString()))
              : DateTime.now()),
      active: (map['active'] is int) ? (map['active'] == 1) : (map['active'] == true),
    );
  }

  Map<String, dynamic> toMongo() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'licenseNumber': licenseNumber,
      'specialty': specialty,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'active': active,
    };
  }

  Map<String, dynamic> toJson() => toMap();
  factory Psychologist.fromJson(Map<String, dynamic> json) => Psychologist.fromMap(json);
  factory Psychologist.fromMongo(Map<String, dynamic> map) => Psychologist.fromMap(map);
}
