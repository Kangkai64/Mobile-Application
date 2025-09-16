import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/staff.dart';

class StaffService {
  final _supabase = Supabase.instance.client;

  Future<List<Staff>> fetchAll() async {
    final response = await _supabase
        .from('Staff')
        .select('*')
        .eq('staff_status', 'Active')
        .order('name');
    return (response as List)
        .map((row) => Staff.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<Staff>> fetchPending() async {
    final response = await _supabase
        .from('Staff')
        .select('*')
        .eq('staff_status', 'Pending')
        .order('created_at');
    return (response as List)
        .map((row) => Staff.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<Staff?> fetchById(String id) async {
    final response = await _supabase
        .from('Staff')
        .select('*')
        .eq('id', id)
        .maybeSingle();

    if (response == null || (response is Map && response.isEmpty)) return null;
    return Staff.fromMap(response as Map<String, dynamic>);
  }

  Future<Staff?> fetchByEmail(String email) async {
    final response = await _supabase
        .from('Staff')
        .select('*')
        .eq('email', email)
        .eq('staff_status', 'Active')
        .maybeSingle();

    if (response == null || (response is Map && response.isEmpty)) return null;
    return Staff.fromMap(response as Map<String, dynamic>);
  }

  /// Request an account: creates a pending Staff record without creating an Auth user
  Future<Staff?> requestAccount({
    required String email,
    String? name,
    String? contactNumber,
    String? position,
    List<String>? specializations,
  }) async {
    final data = <String, dynamic>{
      'email': email,
      'name': name?.trim().isNotEmpty == true ? name!.trim() : email.split('@').first,
      'contact_number': contactNumber,
      'position': (position?.isNotEmpty == true) ? position : 'Mechanic',
      'staff_status': 'Pending',
      'specializations': specializations ?? <String>[],
    };

    final response = await _supabase
        .from('Staff')
        .insert(data)
        .select()
        .single();

    if (response.isEmpty) return null;
    return Staff.fromMap(response);
  }

  /// For admin: approve a pending staff by creating an Auth user and updating the record
  Future<Staff?> approveStaff({
    required String staffId,
    required String password,
    bool emailConfirm = true,
  }) async {
    // Fetch pending staff first
    final staff = await fetchById(staffId);
    if (staff == null) {
      throw Exception('Staff not found');
    }

    if (staff.authUserId != null) {
      // Already has auth
      return staff;
    }

    // Create Supabase Auth user
    final authResponse = await _supabase.auth.admin.createUser(
      AdminUserAttributes(
        email: staff.email,
        password: password,
        emailConfirm: emailConfirm,
      ),
    );

    if (authResponse.user == null) {
      throw Exception('Failed to create auth user');
    }

    final updates = {
      'auth_user_id': authResponse.user!.id,
      'staff_status': 'Active',
      'updated_at': DateTime.now().toIso8601String(),
    };

    final updated = await _supabase
        .from('Staff')
        .update(updates)
        .eq('id', staffId)
        .select()
        .single();

    return Staff.fromMap(updated as Map<String, dynamic>);
  }

  Future<bool> rejectStaff(String id) async {
    final staff = await fetchById(id);
    if (staff == null) return false;

    // If there is an auth user, delete it to revoke access
    if (staff.authUserId != null) {
      try {
        await _supabase.auth.admin.deleteUser(staff.authUserId!);
      } catch (_) {}
    }

    await _supabase
        .from('Staff')
        .update({
          'staff_status': 'Rejected',
          'auth_user_id': null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
    return true;
  }

  Future<Staff?> createStaff(Map<String, dynamic> data) async {
    try {
      // First, create Supabase Auth user
      final authResponse = await _supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: data['email'],
          password: data['password'] ?? 'admin123',
          emailConfirm: true,
        ),
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create auth user');
      }

      // Add auth_user_id to staff data
      data['auth_user_id'] = authResponse.user!.id;

      // Create staff record
      final response = await _supabase.from('Staff')
          .insert(data)
          .select()
          .single();

      if (response.isEmpty) return null;
      return Staff.fromMap(response);
    } catch (e) {
      // If staff creation fails, try to clean up auth user
      try {
        await _supabase.auth.admin.deleteUser(data['auth_user_id']);
      } catch (_) {}
      rethrow;
    }
  }

  Future<bool> updateStaff(String id, Map<String, dynamic> updates) async {
    updates['updated_at'] = DateTime.now().toIso8601String();
    await _supabase.from('Staff')
        .update(updates)
        .eq('id', id);
    return true;
  }

  Future<bool> deactivateStaff(String id) async {
    return await updateStaff(id, {'staff_status': 'Inactive'});
  }

  Future<bool> deleteStaff(String id) async {
    // Get staff record first to get auth_user_id
    final staff = await fetchById(id);
    if (staff == null) return false;

    // Delete from Staff table
    await _supabase.from('Staff')
        .delete()
        .eq('id', id);

    // Delete auth user if exists
    if (staff.authUserId != null) {
      try {
        await _supabase.auth.admin.deleteUser(staff.authUserId!);
      } catch (e) {
        // Log error but don't fail the operation
        print('Failed to delete auth user: $e');
      }
    }

    return true;
  }

  Future<bool> resetStaffPassword(String email, String newPassword) async {
    try {
      final staff = await fetchByEmail(email);
      if (staff?.authUserId == null) return false;

      await _supabase.auth.admin.updateUserById(
        staff!.authUserId!,
        attributes: AdminUserAttributes(password: newPassword),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> validateStaffLogin(String email) async {
    final staff = await fetchByEmail(email);
    return staff != null && staff.staffStatus.toString() == 'Active';
  }
}
