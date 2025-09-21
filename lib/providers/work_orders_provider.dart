import 'package:flutter/material.dart';
import '../models/work_orders.dart';
import '../services/work_orders_service.dart';
import '../services/staff_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkOrdersProvider extends ChangeNotifier {
  Future<bool> updateWorkOrderPart(String id, Map<String, dynamic> updates) async {
    try {
      final success = await _service.updateWorkOrderPart(id, updates);
      return success;
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }
  WorkOrdersProvider._internal();
  static final _instance = WorkOrdersProvider._internal();
  factory WorkOrdersProvider() => _instance;

  final WorkOrdersService _service = WorkOrdersService();
  final StaffService _staffService = StaffService();

  List<WorkOrders>? _workOrders;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetch;
  String? _currentStaffId;
  DateTime? _lastStaffRefresh;
  String? _lastUserEmail;

  // public getters
  List<WorkOrders>? get workOrders => _workOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentStaffId => _currentStaffId;

  //getters
  List<WorkOrders> filterOrders({String? status, String? priority, bool filterByStaff = true, DateTime? selectedDate, String? dateFilterType}) {
    List<WorkOrders> filteredOrders = _workOrders ?? [];
    
    // Filter by current staff if requested
    if (filterByStaff) {
      // Always refresh staff info to ensure we have the current user
      _refreshStaffInfoIfNeeded();
      
      if (_currentStaffId != null) {
        filteredOrders = filteredOrders.where((o) => o.assignedStaffId == _currentStaffId).toList();
      }
    }
    
    // Apply date filters
    if (dateFilterType != null && dateFilterType != 'all') {
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      
      filteredOrders = filteredOrders.where((o) {
        DateTime orderDate = DateTime(o.scheduledDate.year, o.scheduledDate.month, o.scheduledDate.day);
        
        switch (dateFilterType) {
          case 'today':
            return orderDate.isAtSameMomentAs(today);
          case 'week':
            DateTime weekStart = today.subtract(Duration(days: today.weekday - 1));
            DateTime weekEnd = weekStart.add(Duration(days: 6));
            return orderDate.isAfter(weekStart.subtract(Duration(days: 1))) && 
                   orderDate.isBefore(weekEnd.add(Duration(days: 1)));
          case 'custom':
            if (selectedDate != null) {
              DateTime customDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
              return orderDate.isAtSameMomentAs(customDate);
            }
            return true;
          default:
            return true;
        }
      }).toList();
    }
    
    // Apply status and priority filters
    return filteredOrders
        .where((o) =>
            (status == null || o.status.toUpperCase() == status.toUpperCase()) &&
            (priority == null || o.priority.toUpperCase() == priority.toUpperCase()))
        .toList();
  }

  bool _isCacheValid() {
    if (_lastFetch == null) return false;
    return DateTime.now().difference(_lastFetch!) < const Duration(minutes: 5);
  }

  // Initialize current staff ID
  Future<void> _initializeCurrentStaff() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user?.email != null) {
        final staff = await _staffService.fetchByEmail(user!.email!);
        _currentStaffId = staff?.id;
        _lastUserEmail = user.email;
        _lastStaffRefresh = DateTime.now();
      }
    } catch (error) {
      print('Error initializing current staff: $error');
      _currentStaffId = null;
    }
  }

  // Refresh staff info if needed (user changed or never initialized)
  void _refreshStaffInfoIfNeeded() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final currentEmail = currentUser?.email;
    
    // Check if we need to refresh staff info
    bool needsRefresh = false;
    
    if (_currentStaffId == null || _lastUserEmail == null) {
      needsRefresh = true;
    } else if (currentEmail != _lastUserEmail) {
      needsRefresh = true;
    } else if (_lastStaffRefresh == null || 
               DateTime.now().difference(_lastStaffRefresh!) > const Duration(minutes: 5)) {
      needsRefresh = true;
    }
    
    if (needsRefresh) {
      _initializeCurrentStaff();
    }
  }

  // Load data and save in cache to share with all screens
  Future<void> loadWorkOrders({bool forceRefresh = false}) async {
    if (_isLoading) return;

    if (_workOrders != null && !forceRefresh && _isCacheValid()) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Initialize current staff ID if not already set
      if (_currentStaffId == null) {
        await _initializeCurrentStaff();
      }
      
      _workOrders = await _service.fetchAll();
      _lastFetch = DateTime.now();
      _error = null;
    }
    catch (error) {
      _error = error.toString();
    }
    finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateWorkOrder(String id, Map<String, dynamic> updates) async {
    try {
      final success = await _service.updateWorkOrder(id, updates);
      if (success && _workOrders != null) {
        // Update local cache
        final index = _workOrders!.indexWhere((order) => order.id == id);
        if (index != -1) {
          final updatedOrder = WorkOrders.fromJson({
            ..._workOrders![index].toJson(),
            ...updates,
          });
          _workOrders![index] = updatedOrder;
          notifyListeners();
        }
      }
      return success;
    }
    catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addWorkOrder(Map<String, dynamic> data) async {
    try {
      final newOrder = await _service.createWorkOrder(data);
      if (newOrder != null && _workOrders != null) {
        _workOrders!.insert(0, newOrder);
        notifyListeners();
        return true;
      }
      return false;
    }
    catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteWorkOrder(String id) async {
    try {
      final success = await _service.deleteWorkOrder(id);
      if (success && _workOrders != null) {
        _workOrders! .removeWhere((order) => order.id == id);
        notifyListeners();
      }
      return success;
    }
    catch (error) {
      _error = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> getAssignedPartsForWorkOrder(String workOrderId) async {
    try {
      return await _service.fetchAssignedParts(workOrderId);
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() => loadWorkOrders(forceRefresh: true);

  // Refresh staff info (useful when user changes or logs in)
  Future<void> refreshStaffInfo() async {
    await _initializeCurrentStaff();
    notifyListeners();
  }

  // Force refresh staff info and work orders
  Future<void> refreshAll() async {
    await _initializeCurrentStaff();
    await loadWorkOrders(forceRefresh: true);
  }

}