import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/work_orders.dart';

class WorkOrdersService {
  Future<WorkOrders?> fetchById(String id) async {
    final response = await _supabase
        .from('WorkOrders')
        .select('*, Vehicles(*), Customers(*)')
        .eq('id', id)
        .single();
    if (response == null || response.isEmpty) return null;
    return WorkOrders.fromMap(response);
  }
  Future<bool> updateWorkOrderPart(String id, Map<String, dynamic> updates) async {
    try {
      await _supabase.from('WorkOrderParts')
        .update(updates)
        .eq('id', id);
      return true;
    } catch (e) {
      print('Error updating WorkOrderPart: $e');
      return false;
    }
  }
  final _supabase = Supabase.instance.client;

  Future<List<WorkOrders>> fetchAll() async {
    final response = await _supabase
        .from('WorkOrders')
        .select('*, Vehicles(*), Customers(*)');
    return (response as List)
        .map((row) => WorkOrders.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<bool> updateWorkOrder (String id, Map<String, dynamic> updates) async {
    await _supabase.from('WorkOrders')
        .update(updates)
        .eq('id', id);
    // If no exception is thrown, consider update successful
    return true;
  }

  Future<WorkOrders?> createWorkOrder(Map<String, dynamic> data) async {
    final response = await _supabase.from('WorkOrders')
        .insert(data)
        .select()
        .single();

    if (response.isEmpty) return null;
    return WorkOrders.fromMap(response);
  }

  Future<bool> deleteWorkOrder (String id) async {
    final response = await _supabase.from('WorkOrders')
        .delete()
        .eq('id', id);

    if (response is List) {
      return response.isNotEmpty;
    }
    else if (response is int) {
      return response > 0;
    }
    return true;
  }

  Future<List<Map<String, dynamic>>?> fetchAssignedParts(String workOrderId) async {
    try {
      final response = await _supabase
          .from('WorkOrderParts')
          .select('*, Parts(*)')
          .eq('work_order_id', workOrderId);
      return (response as List).map((row) => row as Map<String, dynamic>).toList();
    } catch (error) {
      print('Error fetching assigned parts: $error');
      return null;
    }
  }
}