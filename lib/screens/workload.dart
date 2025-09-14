class Workload {
  final String id;
  final String make;
  final String model;
  final int year;
  final String color;
  final String vin;
  final String engineType;
  final int mileage;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String customerId;
  final String status;

  Workload({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.vin,
    required this.engineType,
    required this.mileage,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.customerId,
    required this.status,
  });

  factory Workload.fromMap(Map<String, dynamic> map) {
    return Workload(
      id: map['id'] ?? '',
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? 0,
      color: map['color'] ?? '',
      vin: map['vin'] ?? '',
      engineType: map['engine_type'] ?? '',
      mileage: map['mileage'] ?? 0,
      notes: map['notes'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      customerId: map['customer_id'] ?? '',
      status: map['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'color': color,
      'vin': vin,
      'engine_type': engineType,
      'mileage': mileage,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'customer_id': customerId,
      'status': status,
    };
  }

  // Convenient getters
  String get vehicle => '$year $make $model';
  String get shortVin => vin.length > 8 ? '...${vin.substring(vin.length - 8)}' : vin;
}