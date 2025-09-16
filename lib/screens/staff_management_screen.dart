import 'package:flutter/material.dart';
import '../models/staff.dart';
import '../services/staff_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final StaffService _staffService = StaffService();
  List<Staff> _staffList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authorizeAndLoad();
  }

  Future<void> _authorizeAndLoad() async {
    final service = StaffService();
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null) {
      _denyAccess();
      return;
    }
    final me = await service.fetchByEmail(email);
    if (me == null || (me.position).toLowerCase() != 'admin') {
      _denyAccess();
      return;
    }
    _loadStaff();
  }

  void _denyAccess() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Access denied: Admins only')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    try {
      final staff = await _staffService.fetchAll();
      setState(() {
        _staffList = staff;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading staff: $e')),
        );
      }
    }
  }

  Future<void> _addStaff() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditStaffScreen()),
    );
    
    if (result == true) {
      _loadStaff();
    }
  }

  Future<void> _editStaff(Staff staff) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditStaffScreen(staff: staff),
      ),
    );
    
    if (result == true) {
      _loadStaff();
    }
  }

  Future<void> _deleteStaff(Staff staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Are you sure you want to delete ${staff.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _staffService.deleteStaff(staff.id);
        _loadStaff();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting staff: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _addStaff,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _staffList.isEmpty
              ? const Center(
                  child: Text(
                    'No staff members found.\nTap + to add staff.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _staffList.length,
                  itemBuilder: (context, index) {
                    final staff = _staffList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Text(
                            staff.name[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(staff.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(staff.email),
                            Text('${staff.position} • ${staff.contactNumber}'),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: const Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: const Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editStaff(staff);
                            } else if (value == 'delete') {
                              _deleteStaff(staff);
                            }
                          },
                        ),
                        onTap: () => _editStaff(staff),
                      ),
                    );
                  },
                ),
    );
  }
}

class AddEditStaffScreen extends StatefulWidget {
  final Staff? staff;

  const AddEditStaffScreen({super.key, this.staff});

  @override
  State<AddEditStaffScreen> createState() => _AddEditStaffScreenState();
}

class _AddEditStaffScreenState extends State<AddEditStaffScreen> {
  final StaffService _staffService = StaffService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _positionController = TextEditingController();
  final _salaryController = TextEditingController();
  final _notesController = TextEditingController();
  final _passwordController = TextEditingController();
  
  DateTime? _hireDate;
  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.staff != null;
    if (_isEdit) {
      final staff = widget.staff!;
      _nameController.text = staff.name;
      _emailController.text = staff.email;
      _contactController.text = staff.contactNumber;
      _addressController.text = staff.address ?? '';
      _positionController.text = staff.position;
      _salaryController.text = staff.salary?.toString() ?? '';
      _notesController.text = staff.notes ?? '';
      _hireDate = staff.hireDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _positionController.dispose();
    _salaryController.dispose();
    _notesController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _hireDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _hireDate = date);
    }
  }

  Future<void> _saveStaff() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'contact_number': _contactController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'position': _positionController.text.trim(),
        'salary': _salaryController.text.trim().isEmpty ? null : double.tryParse(_salaryController.text.trim()),
        'hire_date': _hireDate?.toIso8601String().split('T')[0],
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      };

      if (_isEdit) {
        await _staffService.updateStaff(widget.staff!.id, data);
      } else {
        data['password'] = _passwordController.text.trim();
        await _staffService.createStaff(data);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Staff updated successfully' : 'Staff created successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Staff' : 'Add Staff'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveStaff,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name *'),
                validator: (v) => v?.trim().isEmpty == true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email *'),
                validator: (v) {
                  if (v?.trim().isEmpty == true) return 'Email is required';
                  if (!v!.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Contact Number *'),
                validator: (v) => v?.trim().isEmpty == true ? 'Contact number is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(labelText: 'Position *'),
                validator: (v) => v?.trim().isEmpty == true ? 'Position is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _salaryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Salary'),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Hire Date'),
                  child: Text(_hireDate != null
                      ? '${_hireDate!.day}/${_hireDate!.month}/${_hireDate!.year}'
                      : 'Select date'),
                ),
              ),
              const SizedBox(height: 16),
              if (!_isEdit) ...[
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password *'),
                  validator: (v) {
                    if (v?.trim().isEmpty == true) return 'Password is required';
                    if (v!.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
