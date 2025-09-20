import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  // Regular client for user operations (respects RLS)
  SupabaseClient get client => Supabase.instance.client;

  // Service role client for admin operations (bypasses RLS)
  SupabaseClient? _serviceClient;

  // Initialize service role client
  void initializeServiceClient() {
    _serviceClient = SupabaseClient(
      SupabaseConfig.supabaseUrl,
      SupabaseConfig.serviceRoleKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
      ),
    );
  }

  // Get service role client (bypasses RLS)
  SupabaseClient get serviceClient {
    if (_serviceClient == null) {
      initializeServiceClient();
    }
    return _serviceClient!;
  }

  // Helper method to determine if we should use service role
  bool shouldUseServiceRole(String operation) {
    // List of operations that require service role (bypass RLS)
    const adminOperations = [
      'createStaff',
      'approveStaff',
      'rejectStaff',
      'deleteStaff',
      'resetStaffPassword',
      'adminQuery',
    ];
    return adminOperations.contains(operation);
  }

  // Generic method to execute queries with appropriate client
  Future<T> executeQuery<T>(
      String operation,
      Future<T> Function(SupabaseClient client) query,
      ) async {
    final clientToUse = shouldUseServiceRole(operation) ? serviceClient : client;
    return await query(clientToUse);
  }

  // Admin operations that bypass RLS
  Future<Map<String, dynamic>?> adminQuery(
      String table, {
        String? select,
        Map<String, dynamic>? filters,
        Map<String, dynamic>? data,
        String? operation, // 'select', 'insert', 'update', 'delete'
      }) async {
    try {
      switch (operation) {
        case 'select':
          dynamic query = serviceClient.from(table).select(select ?? '*');

          if (filters != null) {
            filters.forEach((key, value) {
              query = query.eq(key, value);
            });
          }

          final result = await query.maybeSingle();
          return result;

        case 'insert':
          if (data == null) throw Exception('Data required for insert');
          dynamic insertQuery = serviceClient.from(table).insert(data);
          if (select != null) {
            insertQuery = insertQuery.select(select);
          } else {
            insertQuery = insertQuery.select();
          }
          return await insertQuery.single();

        case 'update':
          if (data == null) throw Exception('Data required for update');
          dynamic updateQuery = serviceClient.from(table).update(data);

          if (filters != null) {
            filters.forEach((key, value) {
              updateQuery = updateQuery.eq(key, value);
            });
          }

          if (select != null) {
            updateQuery = updateQuery.select(select);
          } else {
            updateQuery = updateQuery.select();
          }
          return await updateQuery.single();

        case 'delete':
          dynamic deleteQuery = serviceClient.from(table).delete();

          if (filters != null) {
            filters.forEach((key, value) {
              deleteQuery = deleteQuery.eq(key, value);
            });
          }

          if (select != null) {
            deleteQuery = deleteQuery.select(select);
          } else {
            deleteQuery = deleteQuery.select();
          }
          return await deleteQuery.single();

        default:
          throw Exception('Invalid operation: $operation');
      }
    } catch (e) {
      print('Admin query error: $e');
      rethrow;
    }
  }

  // Clean up resources
  void dispose() {
    _serviceClient?.dispose();
  }
}