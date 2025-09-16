import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/staff.dart';
import '../services/staff_service.dart';

class ApproveStaffScreen extends StatefulWidget {
  const ApproveStaffScreen({super.key});

  @override
  State<ApproveStaffScreen> createState() => _ApproveStaffScreenState();
}

class _ApproveStaffScreenState extends State<ApproveStaffScreen> {
  final StaffService _staffService = StaffService();
  bool _isLoading = true;
  List<Staff> _pending = [];

  @override
  void initState() {
    super.initState();
    _authorizeAndLoad();
  }

  Future<void> _authorizeAndLoad() async {
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null) {
      _denyAccess();
      return;
    }
    final me = await _staffService.fetchByEmail(email);
    if (me == null || (me.position).toLowerCase() != 'admin') {
      _denyAccess();
      return;
    }
    _loadPending();
  }

  void _denyAccess() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Access denied: Admins only')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _loadPending() async {
    setState(() => _isLoading = true);
    try {
      final rows = await _staffService.fetchPending();
      if (!mounted) return;
      setState(() {
        _pending = rows;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load pending: $e')),
      );
    }
  }

  Future<void> _approve(Staff staff) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Staff'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create login for: ${staff.email}')
          , const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Set Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Approve')),
        ],
      ),
    );
    if (ok != true) return;

    final password = controller.text.trim();
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    try {
      await _staffService.approveStaff(staffId: staff.id, password: password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approved ${staff.email}')),
      );
      _loadPending();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approval failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approve Staff Requests'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pending.isEmpty
              ? const Center(child: Text('No pending requests'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pending.length,
                  itemBuilder: (context, index) {
                    final s = _pending[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Text(s.name.isNotEmpty ? s.name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(s.name.isNotEmpty ? s.name : s.email),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.email),
                            Text(s.position),
                            if (s.specializations.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: s.specializations
                                      .map((sp) => Chip(label: Text(sp), backgroundColor: Colors.green[50]))
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _approve(s),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          child: const Text('Approve'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
