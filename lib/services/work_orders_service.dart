import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/work_orders.dart';

class WorkOrdersService {
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
}