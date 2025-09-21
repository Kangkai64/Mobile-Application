import 'dart:convert';

import 'vehicles.dart';
import 'customers.dart';

class WorkOrders {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String customerId;
  final String licensePlate;
  final String assignedStaffId;
  final String status;
  final String priority;
  final DateTime scheduledDate;
  final DateTime startedAt;
  final DateTime completedAt;
  final double totalAmount;
  final String paymentStatus;
  final String customerNotes;
  final String internalNotes;
  final Vehicles? vehicles;
  final Customers? customers;
  final int? totalTime;
  final String? customerSignature;

  WorkOrders({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.customerId,
    required this.licensePlate,
    required this.assignedStaffId,
    required this.status,
    required this.priority,
    required this.scheduledDate,
    required this.startedAt,
    required this.completedAt,
    required this.totalAmount,
    required this.paymentStatus,
    required this.customerNotes,
    required this.internalNotes,
  required this.vehicles,
  required this.customers,
  this.totalTime,
  this.customerSignature,
  });

  factory WorkOrders.fromMap(Map<String, dynamic> map) {
  return WorkOrders(
    id: map['id'] ?? '',
    createdAt: map['created_at'] != null
      ? DateTime.parse(map['created_at'])
      : DateTime.now(),
    updatedAt: map['updated_at'] != null
      ? DateTime.parse(map['updated_at'])
      : DateTime.now(),
    customerId: map['customer_id'] ?? '',
    licensePlate: map['license_plate'] ?? '',
    assignedStaffId: map['assigned_staff_id'] ?? '',
    status: map['status'] ?? 'Pending',
    priority: map['priority'] ?? 'Low',
    scheduledDate: map['scheduled_date'] != null
      ? DateTime.parse(map['scheduled_date'])
      : DateTime.now(),
    startedAt: map['started_at'] != null
      ? DateTime.parse(map['started_at'])
      : DateTime.now(),
    completedAt: map['completed_at'] != null
      ? DateTime.parse(map['completed_at'])
      : DateTime.now(),
    totalAmount: map['total_amount'] == null
      ? 0.0
      : (map['total_amount'] as num).toDouble(),
    paymentStatus: map['payment_status'] ?? 'Pending',
    customerNotes: map['customer_notes'] ?? '',
    internalNotes: map['internal_notes'] ?? '',
    vehicles: map['Vehicles'] != null
      ? Vehicles.fromMap(map['Vehicles'] as Map<String, dynamic>)
      : null,
    customers: map['Customers'] != null
      ? Customers.fromMap(map['Customers'] as Map<String, dynamic>)
      : null,
  totalTime: map['total_time'] is int ? map['total_time'] : (map['total_time'] != null ? int.tryParse(map['total_time'].toString()) : null),
  customerSignature: map['customer_signature'],
  );
  }


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'customer_id': customerId,
      'license_plate': licensePlate,
      'assigned_staff_id': assignedStaffId,
      'status': status,
      'priority': priority,
      'scheduled_date': scheduledDate.toIso8601String(),
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt.toIso8601String(),
      'total_amount': totalAmount,
      'payment_status': paymentStatus,
      'customer_notes': customerNotes,
      'internal_notes': internalNotes,
  'total_time': totalTime,
  'customer_signature': customerSignature,
    };
  }

  // JSON helpers
  factory WorkOrders.fromJson(Map<String, dynamic> json) => WorkOrders.fromMap(json);
  Map<String, dynamic> toJson() => toMap();

  // For saving as string in SharedPreferences
  String toJsonString() => jsonEncode(toJson());
  factory WorkOrders.fromJsonString(String source) =>
      WorkOrders.fromJson(jsonDecode(source));

  // Convenient getters
  String get vehicleName =>
      vehicles != null && vehicles!.vehicleName.trim().isNotEmpty
          ? vehicles!.vehicleName
          : licensePlate;

  String get customerName => customers?.name ?? customerId;
  String get customerEmail => customers?.email ?? '';
  String get customerPhone => customers?.contactNumber ?? '';
  String get customerAddress => customers?.address ?? '';
}