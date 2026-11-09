class Patient {
  final String id; // UUID
  final String fullName;
  final DateTime dateOfBirth;
  final String? gender;
  final String? phoneNumber;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool active;
  final int testCount;
  final DateTime? lastTestDate;

  Patient({
    required this.id,
    required this.fullName,
    required this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.active = true,
    this.testCount = 0,
    this.lastTestDate,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'phone_number': phoneNumber,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'active': active ? 1 : 0,
      'test_count': testCount,
      'last_test_date': lastTestDate?.toIso8601String(),
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] as String,
      fullName: (map['full_name'] ?? map['fullName'] ?? '') as String,
      dateOfBirth: map['date_of_birth'] != null
          ? DateTime.parse(map['date_of_birth'].toString())
          : (map['dateOfBirth'] != null
              ? (map['dateOfBirth'] is DateTime ? map['dateOfBirth'] : DateTime.parse(map['dateOfBirth'].toString()))
              : DateTime.now()),
      gender: map['gender'] as String?,
      phoneNumber: (map['phone_number'] ?? map['phoneNumber']) as String?,
      notes: map['notes'] as String?,
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
      testCount: (map['test_count'] ?? map['testCount'] ?? 0) as int,
      lastTestDate: map['last_test_date'] != null
          ? DateTime.parse(map['last_test_date'].toString())
          : (map['lastTestDate'] != null
              ? (map['lastTestDate'] is DateTime ? map['lastTestDate'] : DateTime.parse(map['lastTestDate'].toString()))
              : null),
    );
  }

  Map<String, dynamic> toMongo() {
    return {
      'id': id,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'phoneNumber': phoneNumber,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'active': active,
      'testCount': testCount,
      'lastTestDate': lastTestDate?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();
  factory Patient.fromJson(Map<String, dynamic> json) => Patient.fromMap(json);
  factory Patient.fromMongo(Map<String, dynamic> map) => Patient.fromMap(map);
}
