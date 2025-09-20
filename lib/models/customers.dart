class Customers {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final String email;
  final String contactNumber;
  final String address;
  final DateTime? dateOfBirth;
  final String gender;
  final String notes;
  final String? authUserId;

  Customers({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.email,
    required this.contactNumber,
    required this.address,
    required this.dateOfBirth,
    required this.gender,
    required this.notes,
    this.authUserId,
  });

  factory Customers.fromMap(Map<String, dynamic> map) {
    return Customers(
      id: map['id'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      contactNumber: map['contact_number'] ?? '',
      address: map['address'] ?? '',
      dateOfBirth:
          map['date_of_birth'] != null ? DateTime.parse(map['date_of_birth']) : null,
      gender: map['gender'] ?? '',
      notes: map['notes'] ?? '',
      authUserId: map['auth_user_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'name': name,
      'email': email,
      'contact_number': contactNumber,
      'address': address,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0], // Date only
      'gender': gender,
      'notes': notes,
      'auth_user_id': authUserId,
    };
  }

  Customers copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? email,
    String? contactNumber,
    String? address,
    DateTime? dateOfBirth,
    String? gender,
    String? notes,
    String? authUserId,
  }) {
    return Customers(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      email: email ?? this.email,
      contactNumber: contactNumber ?? this.contactNumber,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      notes: notes ?? this.notes,
      authUserId: authUserId ?? this.authUserId,
    );
  }
}


