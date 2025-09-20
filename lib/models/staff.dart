class Staff {
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String name;
  final String email;
  final String contactNumber;
  final String? address;
  final String position;
  final DateTime? hireDate;
  final double? salary;
  final String staffStatus;
  final String? notes;
  final String authUserId;
  final List<String> specializations;
  final String? profileImageUrl;

  Staff({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.name,
    required this.email,
    required this.contactNumber,
    this.address,
    required this.position,
    this.hireDate,
    this.salary,
    required this.staffStatus,
    this.notes,
    required this.authUserId,
    this.specializations = const [],
    this.profileImageUrl,
  });

  factory Staff.fromMap(Map<String, dynamic> map) {
    return Staff(
      id: map['id'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      contactNumber: map['contact_number'] ?? '',
      address: map['address'],
      position: map['position'] ?? 'Technician',
      hireDate: map['hire_date'] != null ? DateTime.parse(map['hire_date']) : null,
      salary: map['salary']?.toDouble(),
      staffStatus: ((map['staff_status'] ?? 'Active').toString()),
      notes: map['notes'],
      authUserId: map['auth_user_id'],
      specializations: (map['specializations'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      profileImageUrl: map['profile_image_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'name': name,
      'email': email,
      'contact_number': contactNumber,
      'address': address,
      'position': position,
      'hire_date': hireDate?.toIso8601String().split('T')[0], // Date only
      'salary': salary,
      'staff_status': staffStatus,
      'notes': notes,
      'auth_user_id': authUserId,
      'specializations': specializations,
      'profile_image_url': profileImageUrl,
    };
  }

  Staff copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? email,
    String? contactNumber,
    String? address,
    String? position,
    DateTime? hireDate,
    double? salary,
    String? staffStatus,
    String? notes,
    String? authUserId,
    List<String>? specializations,
    String? profileImageUrl,
  }) {
    return Staff(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      email: email ?? this.email,
      contactNumber: contactNumber ?? this.contactNumber,
      address: address ?? this.address,
      position: position ?? this.position,
      hireDate: hireDate ?? this.hireDate,
      salary: salary ?? this.salary,
      staffStatus: staffStatus ?? this.staffStatus,
      notes: notes ?? this.notes,
      authUserId: authUserId ?? this.authUserId,
      specializations: specializations ?? this.specializations,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
