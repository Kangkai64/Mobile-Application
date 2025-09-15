class Vehicles {
  final String licensePlate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String customerId;
  final String make;
  final String model;
  final int year;
  final String color;
  final String vin;
  final String engineType;
  final int mileage;
  final String notes;

  Vehicles({
    required this.licensePlate,
    required this.createdAt,
    required this.updatedAt,
    required this.customerId,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.vin,
    required this.engineType,
    required this.mileage,
    required this.notes,
  });

  factory Vehicles.fromMap(Map<String, dynamic> map) {
    return Vehicles(
      licensePlate: map['license_plate'] ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
      customerId: map['customer_id'] ?? '',
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? 0,
      color: map['color'] ?? '',
      vin: map['vin'] ?? '',
      engineType: map['engine_type'] ?? '',
      mileage: map['mileage'] ?? 0,
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'license_plate': licensePlate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'customer_id': customerId,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'vin': vin,
      'engine_type': engineType,
      'mileage': mileage,
      'notes': notes,
    };
  }

  String get vehicleName => '$year $make $model';
}