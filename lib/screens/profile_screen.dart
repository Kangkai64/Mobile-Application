import 'package:flutter/material.dart';
import 'staff_management_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import '../services/staff_service.dart';
import '../models/staff.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utils/local_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StaffService _staffService = StaffService();
  Staff? _staff;
  User? get _currentUser => Supabase.instance.client.auth.currentUser;
  bool _isLoading = true;
  String? _error;
  final ImagePicker _picker = ImagePicker();
  String? _profileImagePath;
  int _jobsCompleted = 0;
  double _totalHours = 0;

  @override
  void initState() {
    super.initState();
    debugPrint('ProfileScreen initState');
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    try {
      final email = Supabase.instance.client.auth.currentUser?.email;
      if (email == null || email.isEmpty) {
        setState(() {
          _error = 'Not signed in.';
          _isLoading = false;
        });
        return;
      }
      debugPrint('ProfileScreen _loadStaff: before fetchByEmail(email=$email)');
      final staff = await _staffService.fetchByEmail(email);
      debugPrint('ProfileScreen _loadStaff: after fetchByEmail, mounted=$mounted, staffId=${staff?.id}');
      final stored = LocalStorage.getString('profile_image_${staff?.id ?? email}');
      setState(() {
        _staff = staff;
        _profileImagePath = stored;
        _isLoading = false;
        if (staff == null) {
          _error = 'Staff record not found for $email';
        }
      });
      if (staff != null) {
        await _loadStats(staff);
      }
    } catch (e) {
      debugPrint('ProfileScreen _loadStaff error: $e');
      setState(() {
        _error = 'Failed to load profile';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats(Staff staff) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('WorkOrderSummary')
          .select('*')
          .eq('assigned_staff', staff.name);
      if (response is List) {
        int jobsCompleted = 0;
        double totalHours = 0;
        for (final row in response) {
          final map = row as Map<String, dynamic>;
          final status = (map['status'] ?? '').toString();
          if (status == 'Completed') {
            jobsCompleted += 1;
          }
          final startedAt = map['started_at'];
          final completedAt = map['completed_at'];
          if (startedAt != null && completedAt != null) {
            try {
              final start = DateTime.parse(startedAt as String);
              final end = DateTime.parse(completedAt as String);
              final diff = end.difference(start).inMinutes / 60.0;
              if (diff.isFinite && diff > 0) {
                totalHours += diff;
              }
            } catch (_) {}
          }
        }
        if (mounted) {
          setState(() {
            _jobsCompleted = jobsCompleted;
            _totalHours = totalHours;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image == null) return;
      final key = 'profile_image_${_staff?.id ?? Supabase.instance.client.auth.currentUser?.email ?? 'user'}';
      await LocalStorage.setString(key, image.path);
      if (!mounted) return;
      setState(() {
        _profileImagePath = image.path;
      });
    } catch (_) {}
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade200,
            Colors.blue.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    debugPrint('ProfileScreen dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
            // User Information card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: _pickProfileImage,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _profileImagePath != null && _profileImagePath!.isNotEmpty
                          ? Image.file(
                              File(_profileImagePath!),
                              fit: BoxFit.cover,
                            )
                          : _buildDefaultAvatar(_currentUser?.email ?? "user")
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _staff?.name.isNotEmpty == true ? _staff!.name : 'Unknown',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _staff?.position ?? '—',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${_staff?.id ?? '—'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Statistics cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    Icons.emoji_events,
                    _jobsCompleted.toString(),
                    'Jobs Completed',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    Icons.access_time,
                    _totalHours.toStringAsFixed(1),
                    'Total Hours',
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    Icons.build,
                    '4.8',
                    'Avg Rating',
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Specializations card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Specializations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if ((_staff?.specializations ?? []).isEmpty)
                        _buildSpecializationChip('No specializations set')
                      else
                        ..._staff!.specializations.map(_buildSpecializationChip),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Settings card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsItem(
                    Icons.settings,
                    'App Settings',
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('App Settings coming soon!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    Icons.notifications,
                    'Notifications',
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notification settings coming soon!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                  if ((_staff?.position ?? '').toLowerCase() == 'admin')
                    _buildSettingsItem(
                      Icons.people,
                      'Staff Management',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StaffManagementScreen(),
                          ),
                        );
                      },
                    ),
                  _buildSettingsItem(
                    Icons.help_outline,
                    'Help & Support',
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Help & Support coming soon!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    Icons.logout,
                    'Sign Out',
                    () async {
                      await Supabase.instance.client.auth.signOut();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecializationChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.green[700],
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
