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
    );
  }
}


